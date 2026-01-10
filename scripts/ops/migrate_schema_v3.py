#!/usr/bin/env python3

"""
Schema v3.0 Migration Script

Changes:
1. Reorder item fields: item_sequence → exercise_name → equipment_key → prescription → performed
2. Convert weight fields from simple values to {value, unit} structure

Usage: python3 scripts/migrate_schema_v3.py
"""

import json
import os
from pathlib import Path
from typing import Any, Dict, List

GOLDEN_SET_DIR = Path(__file__).parent.parent / 'data' / 'golden_set'

# Weight field patterns to transform
WEIGHT_FIELDS = [
    'actual_weight_kg',
    'target_weight_kg',
    'target_weight_kg_min',
    'target_weight_kg_max',
    'target_load',
    'actual_load'
]

# Statistics
stats = {
    'files_processed': 0,
    'items_reordered': 0,
    'weight_fields_converted': 0,
    'errors': []
}


def convert_weight(value: Any) -> Any:
    """Convert weight value to new structure"""
    if value is None:
        return None
    
    # Handle arrays (multiple sets)
    if isinstance(value, list):
        return [{'value': v, 'unit': 'kg'} for v in value]
    
    # Handle single values
    return {'value': value, 'unit': 'kg'}


def transform_weights(obj: Any) -> None:
    """Transform weight fields in an object"""
    if not isinstance(obj, dict):
        return
    
    # Handle min/max range pattern
    if 'target_weight_kg_min' in obj and 'target_weight_kg_max' in obj:
        obj['target_weight'] = {
            'value_min': obj['target_weight_kg_min'],
            'value_max': obj['target_weight_kg_max'],
            'unit': 'kg'
        }
        del obj['target_weight_kg_min']
        del obj['target_weight_kg_max']
        stats['weight_fields_converted'] += 2
    
    # Handle individual weight fields
    for field in WEIGHT_FIELDS:
        if field in obj and field not in ['target_weight_kg_min', 'target_weight_kg_max']:
            new_field = field.replace('_kg', '')
            obj[new_field] = convert_weight(obj[field])
            del obj[field]
            stats['weight_fields_converted'] += 1
    
    # Recursively process nested objects and arrays
    for key, value in list(obj.items()):
        if isinstance(value, list):
            for item in value:
                transform_weights(item)
        elif isinstance(value, dict):
            transform_weights(value)


def reorder_item_fields(item: Dict[str, Any]) -> Dict[str, Any]:
    """Reorder fields in an item object"""
    if not isinstance(item, dict):
        return item
    
    # Check if this is an item with exercise fields
    if not ('exercise_name' in item or 'exercises' in item or 'exercise_options' in item):
        return item
    
    # Create new dict with desired field order
    ordered_item = {}
    
    # 1. Sequence
    if 'item_sequence' in item:
        ordered_item['item_sequence'] = item['item_sequence']
    
    # 2. Identity fields (exercise_name, equipment_key)
    if 'exercise_name' in item:
        ordered_item['exercise_name'] = item['exercise_name']
    if 'equipment_key' in item:
        ordered_item['equipment_key'] = item['equipment_key']
    
    # 3. Prescription
    if 'prescription' in item:
        ordered_item['prescription'] = item['prescription']
    
    # 4. Performed
    if 'performed' in item:
        ordered_item['performed'] = item['performed']
    
    # 5. All other fields
    for key, value in item.items():
        if key not in ordered_item:
            ordered_item[key] = value
    
    stats['items_reordered'] += 1
    return ordered_item


def process_items(obj: Any) -> None:
    """Process all items in blocks recursively"""
    if not isinstance(obj, dict):
        return
    
    # If this is an items array, reorder each item
    if 'items' in obj and isinstance(obj['items'], list):
        obj['items'] = [reorder_item_fields(item) for item in obj['items']]
        
        # Process nested exercises/exercise_options
        for item in obj['items']:
            if 'exercises' in item and isinstance(item['exercises'], list):
                item['exercises'] = [reorder_item_fields(ex) for ex in item['exercises']]
            if 'exercise_options' in item and isinstance(item['exercise_options'], list):
                item['exercise_options'] = [reorder_item_fields(ex) for ex in item['exercise_options']]
    
    # Recursively process nested structures
    for key, value in obj.items():
        if isinstance(value, list):
            for item in value:
                process_items(item)
        elif isinstance(value, dict):
            process_items(value)


def process_file(filename: str) -> None:
    """Process a single JSON file"""
    filepath = GOLDEN_SET_DIR / filename
    
    try:
        print(f"Processing: {filename}")
        
        # Read and parse JSON
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Step 1: Reorder fields
        process_items(data)
        
        # Step 2: Transform weights
        transform_weights(data)
        
        # Write back with pretty formatting
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write('\n')
        
        stats['files_processed'] += 1
        print(f"✓ {filename} updated")
        
    except Exception as error:
        stats['errors'].append({'file': filename, 'error': str(error)})
        print(f"✗ Error processing {filename}: {error}")


def main():
    """Main execution"""
    print('🚀 Starting Schema v3.0 Migration\n')
    print('Changes:')
    print('  1. Reorder item fields (exercise_name, equipment_key before prescription/performed)')
    print('  2. Convert weight fields to {value, unit} structure\n')
    
    # Get all JSON files
    files = sorted([f.name for f in GOLDEN_SET_DIR.glob('*.json')])
    
    print(f'Found {len(files)} JSON files\n')
    
    # Process each file
    for filename in files:
        process_file(filename)
    
    # Print summary
    print('\n' + '=' * 60)
    print('📊 Migration Summary')
    print('=' * 60)
    print(f"Files processed: {stats['files_processed']}/{len(files)}")
    print(f"Items reordered: {stats['items_reordered']}")
    print(f"Weight fields converted: {stats['weight_fields_converted']}")
    
    if stats['errors']:
        print(f"\n❌ Errors: {len(stats['errors'])}")
        for err in stats['errors']:
            print(f"  - {err['file']}: {err['error']}")
    else:
        print('\n✅ Schema v3.0 migration complete!')


if __name__ == '__main__':
    main()
