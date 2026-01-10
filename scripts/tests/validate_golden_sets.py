#!/usr/bin/env python3
"""
Golden Set & Stress Test Validation Script
==========================================
Purpose: Comprehensive validation of parser outputs
Date: January 10, 2026
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Any

# Colors
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
NC = '\033[0m'

class ValidationStats:
    def __init__(self):
        self.total = 0
        self.passed = 0
        self.failed = 0
        self.warnings = 0
    
    def add_pass(self):
        self.total += 1
        self.passed += 1
    
    def add_fail(self):
        self.total += 1
        self.failed += 1
    
    def add_warning(self):
        self.warnings += 1
    
    @property
    def pass_rate(self):
        return (self.passed / self.total * 100) if self.total > 0 else 0

def validate_json_structure(data: Dict, filename: str, stats: ValidationStats) -> List[str]:
    """Validate JSON structure against CANONICAL_JSON_SCHEMA"""
    issues = []
    
    # Test 1: Required top-level fields
    if 'workout_date' not in data:
        issues.append("Missing 'workout_date' field")
        stats.add_fail()
    elif not isinstance(data['workout_date'], str):
        issues.append("'workout_date' must be string")
        stats.add_fail()
    else:
        stats.add_pass()
    
    # Test 2: Sessions array
    if 'sessions' not in data:
        issues.append("Missing 'sessions' array")
        stats.add_fail()
    elif not isinstance(data['sessions'], list):
        issues.append("'sessions' must be array")
        stats.add_fail()
    elif len(data['sessions']) == 0:
        issues.append("'sessions' array is empty")
        stats.add_fail()
    else:
        stats.add_pass()
    
    return issues

def check_type_safety(obj: Any, path: str = "") -> List[str]:
    """Recursively check for string values in numeric fields"""
    issues = []
    
    if isinstance(obj, dict):
        numeric_fields = [
            'target_reps', 'target_sets', 'actual_reps', 'actual_sets',
            'target_duration_sec', 'actual_duration_sec', 'target_weight',
            'actual_weight', 'rpe', 'rir', 'item_sequence'
        ]
        
        for key, value in obj.items():
            current_path = f"{path}.{key}" if path else key
            
            if key in numeric_fields and value is not None:
                # Check for weight objects (v3.0 structure)
                if key in ['target_weight', 'actual_weight'] and isinstance(value, dict):
                    if 'value' in value and not isinstance(value['value'], (int, float)):
                        issues.append(f"{current_path}.value is string: {value['value']}")
                elif not isinstance(value, (int, float)):
                    issues.append(f"{current_path} is string: {value}")
            
            # Recurse
            if isinstance(value, (dict, list)):
                issues.extend(check_type_safety(value, current_path))
    
    elif isinstance(obj, list):
        for i, item in enumerate(obj):
            issues.extend(check_type_safety(item, f"{path}[{i}]"))
    
    return issues

def check_block_codes(data: Dict) -> List[str]:
    """Validate block codes against 17 standard types"""
    valid_codes = {
        'WU', 'ACT', 'MOB',  # PREPARATION
        'STR', 'ACC', 'HYP',  # STRENGTH
        'PWR', 'WL',  # POWER
        'SKILL', 'GYM',  # SKILL
        'METCON', 'INTV', 'SS', 'HYROX',  # CONDITIONING
        'CD', 'STRETCH', 'BREATH'  # RECOVERY
    }
    
    issues = []
    
    def check_recursive(obj, path=""):
        if isinstance(obj, dict):
            if 'block_code' in obj:
                code = obj['block_code']
                if code and code not in valid_codes:
                    issues.append(f"{path}: Invalid block_code '{code}'")
            
            for key, value in obj.items():
                check_recursive(value, f"{path}.{key}" if path else key)
        
        elif isinstance(obj, list):
            for i, item in enumerate(obj):
                check_recursive(item, f"{path}[{i}]")
    
    check_recursive(data)
    return issues

def count_equipment_keys(data: Dict) -> tuple:
    """Count items with/without equipment_key"""
    total_items = 0
    items_with_equipment = 0
    
    def count_recursive(obj):
        nonlocal total_items, items_with_equipment
        
        if isinstance(obj, dict):
            if 'items' in obj and isinstance(obj['items'], list):
                for item in obj['items']:
                    if isinstance(item, dict) and 'exercise_name' in item:
                        total_items += 1
                        if 'equipment_key' in item and item['equipment_key']:
                            items_with_equipment += 1
            
            for value in obj.values():
                if isinstance(value, (dict, list)):
                    count_recursive(value)
        
        elif isinstance(obj, list):
            for item in obj:
                count_recursive(item)
    
    count_recursive(data)
    return items_with_equipment, total_items

def check_prescription_performance_separation(data: Dict) -> List[str]:
    """Check for mixed prescription/performance data"""
    issues = []
    
    def check_recursive(obj, path=""):
        if isinstance(obj, dict):
            # Check if object has both prescription/performed AND raw fields
            has_prescription = 'prescription' in obj or 'performed' in obj
            raw_fields = {'reps', 'sets', 'weight', 'duration'} & set(obj.keys())
            
            if raw_fields and not has_prescription:
                issues.append(f"{path}: Has raw fields {raw_fields} without prescription/performed wrapper")
            
            for key, value in obj.items():
                if isinstance(value, (dict, list)):
                    check_recursive(value, f"{path}.{key}" if path else key)
        
        elif isinstance(obj, list):
            for i, item in enumerate(obj):
                check_recursive(item, f"{path}[{i}]")
    
    check_recursive(data)
    return issues

def validate_file(filepath: Path, stats: ValidationStats) -> Dict:
    """Validate a single JSON file"""
    results = {
        'filename': filepath.name,
        'valid': True,
        'issues': []
    }
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        print(f"  {GREEN}✓{NC} Valid JSON structure")
        stats.add_pass()
        
        # Structural validation
        structure_issues = validate_json_structure(data, filepath.name, stats)
        if structure_issues:
            results['issues'].extend(structure_issues)
            results['valid'] = False
        else:
            print(f"  {GREEN}✓{NC} Required fields present")
        
        # Type safety
        type_issues = check_type_safety(data)
        if type_issues:
            print(f"  {RED}✗{NC} Type safety: Found {len(type_issues)} string numbers")
            results['issues'].extend(type_issues)
            results['valid'] = False
            stats.add_fail()
        else:
            print(f"  {GREEN}✓{NC} Type safety: All numbers are numeric")
            stats.add_pass()
        
        # Block codes
        block_issues = check_block_codes(data)
        if block_issues:
            print(f"  {RED}✗{NC} Block codes: {len(block_issues)} invalid")
            results['issues'].extend(block_issues)
            results['valid'] = False
            stats.add_fail()
        else:
            print(f"  {GREEN}✓{NC} Block codes: All valid")
            stats.add_pass()
        
        # Equipment keys (v3.0)
        with_equipment, total_items = count_equipment_keys(data)
        if total_items == 0:
            print(f"  {YELLOW}⚠{NC} No exercise items found")
            stats.add_warning()
        elif with_equipment == total_items:
            print(f"  {GREEN}✓{NC} Equipment keys: {with_equipment}/{total_items}")
            stats.add_pass()
        else:
            print(f"  {YELLOW}⚠{NC} Equipment keys: {with_equipment}/{total_items} (partial)")
            stats.add_warning()
            stats.add_pass()
        
        # Prescription/Performance separation
        separation_issues = check_prescription_performance_separation(data)
        if separation_issues:
            print(f"  {YELLOW}⚠{NC} Separation: {len(separation_issues)} potential issues")
            results['issues'].extend(separation_issues)
            stats.add_warning()
        
    except json.JSONDecodeError as e:
        print(f"  {RED}✗{NC} Invalid JSON: {e}")
        results['valid'] = False
        results['issues'].append(f"JSON parse error: {e}")
        stats.add_fail()
    except Exception as e:
        print(f"  {RED}✗{NC} Error: {e}")
        results['valid'] = False
        results['issues'].append(f"Validation error: {e}")
        stats.add_fail()
    
    return results

def main():
    print("🧪 FULL SYSTEM STRESS TEST - ZAMM PARSER")
    print("=" * 50)
    print()
    
    # Stats
    stats = ValidationStats()
    
    # Golden set directory
    golden_dir = Path("data/golden_set")
    if not golden_dir.exists():
        print(f"{RED}✗ Golden set directory not found{NC}")
        return 1
    
    # Find JSON files (exclude audit/review files)
    json_files = [
        f for f in golden_dir.glob("*.json")
        if not any(x in f.name for x in ['AUDIT', 'REVIEW', 'MANUAL'])
    ]
    
    print(f"📂 PHASE 2: Golden Set Regression Test")
    print("-" * 50)
    print(f"Found {len(json_files)} golden JSON files\n")
    
    all_results = []
    
    for json_file in sorted(json_files):
        print(f"Testing: {json_file.name}")
        result = validate_file(json_file, stats)
        all_results.append(result)
        print()
    
    # Phase 3: Stress Test
    print()
    print(f"🔥 PHASE 3: Stress Test - The Nasty 10")
    print("-" * 50)
    print("Stress test file created: data/stress_test_10.txt")
    print()
    print("⚠️  Note: Stress test requires manual parsing via AI agent")
    print("   Each scenario tests a specific edge case:")
    print()
    print("   1. Hebrew-English Salad - Language mixing")
    print("   2. Complex Range - Multiple range types")
    print("   3. Implicit Date - No YYYY-MM-DD format")
    print("   4. Superset Nightmare - A1/A2/A3 notation")
    print("   5. Ghost Athlete - No athlete name")
    print("   6. RPE Decimal - Fractional RPE values")
    print("   7. Typos & Aliases - Exercise name variations")
    print("   8. Performance Only - No prescription data")
    print("   9. Metric Confusion - Imperial units (lbs)")
    print("   10. Empty Shell - Rest day/minimal data")
    print()
    
    # Final Report
    print("=" * 50)
    print("📊 FINAL REPORT")
    print("=" * 50)
    print()
    print(f"Regression Tests:")
    print(f"  Total Checks: {stats.total}")
    print(f"  Passed: {stats.passed}")
    print(f"  Failed: {stats.failed}")
    print(f"  Warnings: {stats.warnings}")
    print()
    
    pass_rate = stats.pass_rate
    
    if stats.failed == 0:
        print(f"  Status: {GREEN}✓ ALL TESTS PASSED{NC} (100%)")
        verdict = "PRODUCTION READY"
    elif pass_rate >= 95:
        print(f"  Status: {GREEN}✓ PRODUCTION READY{NC} ({pass_rate:.1f}%)")
        verdict = "PRODUCTION READY"
    elif pass_rate >= 90:
        print(f"  Status: {YELLOW}⚠ GOOD, MINOR ISSUES{NC} ({pass_rate:.1f}%)")
        verdict = "GOOD, MINOR ISSUES"
    else:
        print(f"  Status: {RED}✗ NEEDS WORK{NC} ({pass_rate:.1f}%)")
        verdict = "NEEDS WORK"
    
    print()
    print("Files with Issues:")
    failed_files = [r for r in all_results if not r['valid'] or r['issues']]
    if failed_files:
        for result in failed_files:
            print(f"  • {result['filename']}: {len(result['issues'])} issues")
    else:
        print("  None! 🎉")
    
    print()
    print("Next Steps:")
    print("  1. Parse stress_test_10.txt via AI agent")
    print("  2. Validate each output against CANONICAL_JSON_SCHEMA.md")
    print("  3. Test DB commit with validate_parsed_workout()")
    print("  4. Document any failures in learning examples")
    print()
    print("✅ Test suite execution complete!")
    
    # Return exit code based on results
    return 0 if stats.failed == 0 else 1

if __name__ == '__main__':
    sys.exit(main())
