#!/usr/bin/env python3
"""
Add equipment_key to all exercises in golden set JSON files
Based on zamm.equipment_catalog
"""

import json
import os
from pathlib import Path
from collections import defaultdict

# Equipment mapping rules based on exercise names
EQUIPMENT_MAPPING = {
    # Free weights
    'barbell': ['Back Squat', 'Front Squat', 'Barbell', 'Squat', 'Deadlift', 'Clean', 
                'Snatch', 'Press', 'Bench Press', 'Overhead Press', 'Thruster', 
                'Power Clean', 'Hang Clean', 'RDL'],
    'dumbbell': ['DB', 'Dumbbell', 'Dumbell'],
    'kettlebell': ['KB', 'Kettlebell'],
    
    # Cardio machines
    'rowing_machine': ['Row', 'C2', 'Rowing', 'Erg', 'Concept2'],
    'assault_bike': ['Assault Bike', 'AB', 'Air Bike'],
    'bike': ['Bike', 'Stationary Bike'],
    'treadmill': ['Treadmill', 'Jog', 'Run'],
    'ski_erg': ['Ski Erg', 'Ski'],
    
    # Machines
    'cable_machine': ['Cable'],
    'lat_pulldown': ['Lat Pulldown'],
    'leg_press': ['Leg Press'],
    
    # Bodyweight equipment
    'pull_up_bar': ['Pull-up', 'Pullup', 'Pull Up', 'Chin-up', 'Chinup', 'Bar Hang', 'Muscle-up'],
    'dip_station': ['Dip', 'Dips'],
    'rings': ['Ring'],
    
    # Bands
    'resistance_band': ['Band', 'Resistance Band'],
    'mini_band': ['Mini-Band', 'Mini Band', 'Miniband'],
    
    # Mobility & Recovery
    'foam_roller': ['Foam Roll', 'FR', 'Foam Roller'],
    'lacrosse_ball': ['Lacrosse Ball', 'Lacrosse'],
    'pvc_pipe': ['PVC'],
    
    # Functional
    'wall_ball': ['Wall Ball', 'WB'],
    'medicine_ball': ['Medicine Ball', 'Med Ball'],
    'slam_ball': ['Slam Ball'],
    'jump_rope': ['Jump Rope', 'DU', 'Double Under', 'Single Under'],
    'box': ['Box Jump', 'Step Up', 'Box Step'],
    'sandbag': ['Sandbag', 'Sand Bag'],
    'sled': ['Sled Push', 'Sled Pull', 'Sled'],
    
    # Bodyweight/None
    'bodyweight': ['BW', 'Bodyweight', 'Body Weight', 'Air Squat', 'Push-up', 'Pushup', 
                   'Push Up', 'Burpee', 'Plank', 'Sit-up', 'Situp', 'Mountain Climber', 
                   'Lunge', 'Walk', 'Light Jog', 'Stretch', 'Breathing', 'Mobility', 
                   'Activation', 'Scap', 'Shoulder']
}

def get_equipment_key(exercise_name):
    """Determine equipment_key from exercise name"""
    if not exercise_name:
        return 'none'
    
    lower_name = exercise_name.lower()
    
    # Check each equipment type
    for equip_key, patterns in EQUIPMENT_MAPPING.items():
        for pattern in patterns:
            if pattern.lower() in lower_name:
                return equip_key
    
    # Default to bodyweight if uncertain
    return 'bodyweight'

def add_equipment_to_exercise(exercise):
    """Add equipment_key to a single exercise object"""
    if 'equipment_key' not in exercise and 'exercise_name' in exercise:
        exercise['equipment_key'] = get_equipment_key(exercise['exercise_name'])
    return exercise

def process_workout(data):
    """Recursively process workout structure"""
    if 'sessions' not in data:
        return data
    
    for session in data['sessions']:
        if 'blocks' not in session:
            continue
        
        for block in session['blocks']:
            if 'items' not in block:
                continue
            
            for item in block['items']:
                # Handle exercise_options (alternative exercises)
                if 'exercise_options' in item and isinstance(item['exercise_options'], list):
                    for exercise in item['exercise_options']:
                        add_equipment_to_exercise(exercise)
                
                # Handle direct exercise (standard format)
                if 'exercise_name' in item:
                    add_equipment_to_exercise(item)
    
    return data

def main():
    # Set up paths
    script_dir = Path(__file__).parent
    golden_set_dir = script_dir.parent / 'data' / 'golden_set'
    
    # Find all JSON files
    json_files = list(golden_set_dir.glob('*.json'))
    print(f"Found {len(json_files)} JSON files in golden set\n")
    
    # Statistics
    stats = {
        'files_updated': 0,
        'exercises_updated': 0,
        'equipment_used': defaultdict(int)
    }
    
    for file_path in sorted(json_files):
        try:
            # Read file
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Track before state
            before = json.dumps(data, sort_keys=True)
            
            # Process workout
            process_workout(data)
            
            # Check if changed
            after = json.dumps(data, sort_keys=True)
            if before != after:
                # Write back with pretty formatting
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                    f.write('\n')
                
                stats['files_updated'] += 1
                print(f"✓ Updated: {file_path.name}")
                
                # Count exercises and equipment
                if 'sessions' in data:
                    for session in data['sessions']:
                        if 'blocks' in session:
                            for block in session['blocks']:
                                if 'items' in block:
                                    for item in block['items']:
                                        if 'exercise_options' in item:
                                            for ex in item['exercise_options']:
                                                if 'equipment_key' in ex:
                                                    stats['exercises_updated'] += 1
                                                    stats['equipment_used'][ex['equipment_key']] += 1
                                        if 'exercise_name' in item and 'equipment_key' in item:
                                            stats['exercises_updated'] += 1
                                            stats['equipment_used'][item['equipment_key']] += 1
            else:
                print(f"  No changes: {file_path.name}")
        
        except Exception as err:
            print(f"✗ Error processing {file_path.name}: {err}")
    
    # Print summary
    print('\n' + '=' * 60)
    print('SUMMARY')
    print('=' * 60)
    print(f"Files updated: {stats['files_updated']} / {len(json_files)}")
    print(f"Exercises updated: {stats['exercises_updated']}")
    print('\nEquipment usage:')
    
    sorted_equipment = sorted(stats['equipment_used'].items(), 
                              key=lambda x: x[1], reverse=True)
    
    for key, count in sorted_equipment:
        print(f"  {key:<20} {count}")
    
    print('=' * 60)

if __name__ == '__main__':
    main()
