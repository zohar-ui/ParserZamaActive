#!/usr/bin/env python3
"""
Schema Upgrade Script: v3.1 → v3.2
Converts duration and distance fields from plain numbers to {value, unit} structure.
"""

import json
import os
from pathlib import Path
from typing import Any, Dict


def convert_duration_field(data: Dict[str, Any], old_field: str, new_field: str, unit: str) -> None:
    """Convert a duration field from plain number to {value, unit} structure."""
    if old_field in data:
        value = data.pop(old_field)
        if isinstance(value, (int, float)):
            data[new_field] = {"value": value, "unit": unit}
        elif isinstance(value, str):
            # Check if it's a range like "20-30"
            if "-" in value and value.replace(".", "").replace("-", "").isdigit():
                # This is a range - should be split into min/max fields
                # For now, skip conversion and leave as-is in notes
                print(f"  ⚠️  Skipping range value '{value}' in {old_field} - needs manual review")
                # Put it back temporarily
                data[old_field] = value
            elif value.replace(".", "").isdigit():
                # Simple numeric string
                data[new_field] = {"value": float(value), "unit": unit}


def convert_distance_field(data: Dict[str, Any], old_field: str, new_field: str, unit: str = "m") -> None:
    """Convert a distance field from plain number to {value, unit} structure."""
    if old_field in data:
        value = data.pop(old_field)
        if isinstance(value, (int, float)):
            data[new_field] = {"value": value, "unit": unit}


def convert_object(obj: Any) -> Any:
    """Recursively convert all duration and distance fields in an object."""
    if isinstance(obj, dict):
        # Convert duration fields - check _min FIRST to preserve original unit
        if "target_duration_min" in obj:
            convert_duration_field(obj, "target_duration_min", "target_duration", "min")
        elif "target_duration_sec" in obj:
            convert_duration_field(obj, "target_duration_sec", "target_duration", "sec")

        # Rest fields
        if "target_rest_min" in obj:
            convert_duration_field(obj, "target_rest_min", "target_rest", "min")
        elif "target_rest_sec" in obj:
            convert_duration_field(obj, "target_rest_sec", "target_rest", "sec")

        # AMRAP and ForTime
        convert_duration_field(obj, "target_amrap_duration_sec", "target_amrap_duration", "sec")
        convert_duration_field(obj, "target_fortime_cap_sec", "target_fortime_cap", "sec")

        # Convert duration fields (performed level)
        convert_duration_field(obj, "actual_duration_sec", "actual_duration", "sec")
        convert_duration_field(obj, "actual_time_sec", "actual_time", "sec")

        # Convert distance fields (plain number format)
        convert_distance_field(obj, "target_meters", "target_distance", "m")
        convert_distance_field(obj, "actual_meters", "actual_distance", "m")
        convert_distance_field(obj, "target_distance_m", "target_distance", "m")
        convert_distance_field(obj, "actual_distance_m", "actual_distance", "m")

        # Handle legacy format: target_distance + distance_unit (separate fields)
        if "target_distance" in obj and "distance_unit" in obj:
            value = obj.pop("target_distance")
            unit = obj.pop("distance_unit")
            if isinstance(value, (int, float)):
                obj["target_distance"] = {"value": value, "unit": unit}

        if "actual_distance" in obj and "distance_unit" in obj:
            value = obj.pop("actual_distance")
            unit = obj.pop("distance_unit")
            if isinstance(value, (int, float)):
                obj["actual_distance"] = {"value": value, "unit": unit}

        # Recursively process nested objects
        for key, value in obj.items():
            obj[key] = convert_object(value)

        return obj
    elif isinstance(obj, list):
        return [convert_object(item) for item in obj]
    else:
        return obj


def upgrade_file(file_path: Path) -> None:
    """Upgrade a single JSON file from v3.1 to v3.2."""
    print(f"Processing {file_path.name}...")

    try:
        # Read the file
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # Convert the data
        converted_data = convert_object(data)

        # Write back with proper formatting
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(converted_data, f, indent=4, ensure_ascii=False)

        print(f"✅ {file_path.name} upgraded successfully")

    except Exception as e:
        print(f"❌ Error processing {file_path.name}: {e}")


def main():
    """Main function to upgrade all golden set files."""
    golden_set_dir = Path(__file__).parent.parent / "data" / "golden_set"

    if not golden_set_dir.exists():
        print(f"❌ Directory not found: {golden_set_dir}")
        return

    # Get all JSON files
    json_files = list(golden_set_dir.glob("*.json"))

    if not json_files:
        print(f"❌ No JSON files found in {golden_set_dir}")
        return

    print(f"Found {len(json_files)} JSON files to upgrade")
    print("=" * 60)

    # Process each file
    for json_file in sorted(json_files):
        upgrade_file(json_file)

    print("=" * 60)
    print(f"✅ Upgrade complete! Processed {len(json_files)} files")
    print("\nNext steps:")
    print("1. Run: python3 scripts/validate_golden_sets.py")
    print("2. Review the validation report for 100% v3.2 compliance")


if __name__ == "__main__":
    main()
