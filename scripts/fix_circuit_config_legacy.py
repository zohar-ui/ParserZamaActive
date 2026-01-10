#!/usr/bin/env python3
"""
Fix legacy duration fields in circuit_config objects.
Converts rest_between_rounds_sec to v3.2 {value, unit} structure.
"""

import json
from pathlib import Path
from typing import Any, Dict


def fix_circuit_config(obj: Any) -> Any:
    """Recursively fix circuit_config objects."""
    if isinstance(obj, dict):
        # Check if this is a circuit_config with rest_between_rounds_sec
        if 'rest_between_rounds_sec' in obj:
            value = obj.pop('rest_between_rounds_sec')
            if isinstance(value, (int, float)):
                obj['rest_between_rounds'] = {
                    "value": value,
                    "unit": "sec"
                }
                print(f"  → Converted rest_between_rounds_sec: {value} → {{value: {value}, unit: 'sec'}}")

        # Recursively process nested objects
        for key, value in obj.items():
            obj[key] = fix_circuit_config(value)

        return obj
    elif isinstance(obj, list):
        return [fix_circuit_config(item) for item in obj]
    else:
        return obj


def fix_file(file_path: Path) -> bool:
    """Fix a single JSON file."""
    print(f"Processing {file_path.name}...")

    try:
        # Read the file
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # Check if file needs fixing
        file_content = json.dumps(data)
        if 'rest_between_rounds_sec' not in file_content:
            print("  ✓ No legacy fields found")
            return False

        # Fix the data
        fixed_data = fix_circuit_config(data)

        # Write back with proper formatting
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(fixed_data, f, indent=4, ensure_ascii=False)

        print(f"  ✅ Fixed successfully")
        return True

    except Exception as e:
        print(f"  ❌ Error: {e}")
        return False


def main():
    """Main function."""
    golden_set_dir = Path(__file__).parent.parent / "data" / "golden_set"

    if not golden_set_dir.exists():
        print(f"❌ Directory not found: {golden_set_dir}")
        return

    # Get all JSON files
    json_files = list(golden_set_dir.glob("*.json"))

    print(f"Found {len(json_files)} JSON files")
    print("=" * 60)

    fixed_count = 0
    for json_file in sorted(json_files):
        if fix_file(json_file):
            fixed_count += 1
        print()

    print("=" * 60)
    print(f"✅ Complete! Fixed {fixed_count} files")
    print()
    print("Next step: Run validation to verify:")
    print("  bash scripts/validate_golden_sets.sh")


if __name__ == "__main__":
    main()
