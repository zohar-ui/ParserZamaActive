#!/usr/bin/env python3
"""
Bulk add equipment_key to all golden set JSON files
Writes results to output file to avoid terminal issues
"""

import json
import os
from pathlib import Path
from collections import defaultdict

# Equipment mapping
EQUIPMENT_MAP = {
    'barbell': ['Back Squat', 'Front Squat', 'Barbell', ' Squat', 'Deadlift', 'Clean', 'Snatch', 'Press', 'Bench Press', 'Overhead Press', 'Thruster', 'Power Clean', 'Hang Clean', 'RDL', ' BB ', 'Hip Thrust'],
    'dumbbell': [' DB ', 'Dumbbell', 'Dumbell'],
    'kettlebell': [' KB ', ' KTB ', 'Kettlebell'],
    'rowing_machine': ['Row', ' C2 ', 'Rowing', ' Erg', 'Concept2'],
    'assault_bike': ['Assault Bike', ' AB ', 'Air Bike'],
    'bike': ['Bike', 'Stationary Bike'],
    'treadmill': ['Treadmill', ' Jog', ' Run'],
    'ski_erg': ['Ski Erg', ' Ski'],
    'cable_machine': ['Cable'],
    'lat_pulldown': ['Lat Pulldown'],
    'leg_press': ['Leg Press'],
    'pull_up_bar': ['Pull-up', 'Pullup', 'Pull Up', 'Chin-up', 'Chinup', 'Bar Hang', 'Muscle-up', 'Dead Hang'],
    'dip_station': [' Dip', 'Dips'],
    'rings': ['Ring'],
    'resistance_band': ['Band', 'Banded'],
    'mini_band': ['Mini-Band', 'Mini Band', 'Miniband'],
    'foam_roller': ['Foam Roll', ' FR ', 'Foam Roller'],
    'lacrosse_ball': ['Lacrosse Ball', 'Lacrosse'],
    'pvc_pipe': [' PVC', 'Dowel'],
    'wall_ball': ['Wall Ball', ' WB '],
    'medicine_ball': ['Medicine Ball', 'Med Ball'],
    'slam_ball': ['Slam Ball'],
    'jump_rope': ['Jump Rope', ' DU', 'Double Under', 'Single Under'],
    'box': ['Box Jump', 'Step Up', 'Box Step'],
    'sandbag': ['Sandbag', 'Sand Bag'],
    'sled': ['Sled Push', 'Sled Pull', ' Sled'],
    'landmine': ['Landmine'],
    'bodyweight': [' BW ', 'Bodyweight', 'Body Weight', 'Air Squat', 'Push-up', 'Pushup', 'Push Up', 'Burpee', 'Plank', 'Sit-up', 'Situp', 'Mountain Climber', ' Lunge', ' Walk', 'Light Jog', 'Stretch', 'Breathing', 'Mobility', 'Activation', 'Scap', 'Shoulder', 'Dead Bug', 'Glute Bridge', 'Hip', 'Ankle', 'Calf', 'Cat', 'Frog', 'Inchworm', 'Couch', ' Cars', 'Curl-Up', 'Hard-Style', 'Back Extension', 'Isometric', 'Airplane', 'Groiner', 'Floss', 'Hyper', 'Open Books', 'Smash']
}

def get_equipment_key(exercise_name):
    if not exercise_name:
        return 'bodyweight'
    
    # Normalize the name
    name = ' ' + exercise_name + ' '
    
    # Check patterns (order matters - check specific before general)
    for equip_key, patterns in EQUIPMENT_MAP.items():
        for pattern in patterns:
            if pattern.lower() in name.lower():
                return equip_key
    
    return 'bodyweight'

def add_equipment_recursive(obj):
    """Recursively add equipment_key to all exercise objects"""
    if isinstance(obj, dict):
        # If this is an exercise object
        if 'exercise_name' in obj and 'equipment_key' not in obj:
            obj['equipment_key'] = get_equipment_key(obj['exercise_name'])
        
        # Recurse into all values
        for value in obj.values():
            add_equipment_recursive(value)
    
    elif isinstance(obj, list):
        # Recurse into list items
        for item in obj:
            add_equipment_recursive(item)

def main():
    script_dir = Path(__file__).parent
    golden_dir = script_dir.parent / 'data' / 'golden_set'
    output_file = script_dir.parent / 'equipment_update_results.txt'
    
    json_files = sorted(golden_dir.glob('*.json'))
    
    results = []
    results.append(f"Processing {len(json_files)} JSON files\n")
    results.append("=" * 80 + "\n\n")
    
    stats = {
        'files_updated': 0,
        'exercises_updated': 0,
        'equipment_used': defaultdict(int)
    }
    
    # Track exercises per equipment for mapping table
    exercise_to_equipment = defaultdict(set)
    
    for file_path in json_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            before = json.dumps(data, sort_keys=True)
            add_equipment_recursive(data)
            after = json.dumps(data, sort_keys=True)
            
            if before != after:
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                    f.write('\n')
                
                stats['files_updated'] += 1
                results.append(f"✓ Updated: {file_path.name}\n")
                
                # Count equipment usage
                def count_equipment(obj):
                    if isinstance(obj, dict):
                        if 'exercise_name' in obj and 'equipment_key' in obj:
                            stats['exercises_updated'] += 1
                            stats['equipment_used'][obj['equipment_key']] += 1
                            exercise_to_equipment[obj['exercise_name']].add(obj['equipment_key'])
                        for value in obj.values():
                            count_equipment(value)
                    elif isinstance(obj, list):
                        for item in obj:
                            count_equipment(item)
                
                count_equipment(data)
            else:
                results.append(f"  No changes: {file_path.name}\n")
        
        except Exception as e:
            results.append(f"✗ Error: {file_path.name}: {e}\n")
    
    # Generate summary
    results.append("\n" + "=" * 80 + "\n")
    results.append("SUMMARY\n")
    results.append("=" * 80 + "\n")
    results.append(f"Files updated: {stats['files_updated']} / {len(json_files)}\n")
    results.append(f"Exercises updated: {stats['exercises_updated']}\n\n")
    
    results.append("Equipment usage (sorted by frequency):\n")
    results.append("-" * 80 + "\n")
    sorted_equip = sorted(stats['equipment_used'].items(), key=lambda x: x[1], reverse=True)
    for key, count in sorted_equip:
        results.append(f"  {key:<25} {count:>3}\n")
    
    # Exercise to equipment mapping
    results.append("\n" + "=" * 80 + "\n")
    results.append("EXERCISE -> EQUIPMENT MAPPING\n")
    results.append("=" * 80 + "\n")
    for ex_name in sorted(exercise_to_equipment.keys()):
        equip_list = ', '.join(sorted(exercise_to_equipment[ex_name]))
        results.append(f"{ex_name:<40} -> {equip_list}\n")
    
    # Write results
    with open(output_file, 'w', encoding='utf-8') as f:
        f.writelines(results)
    
    print(f"Results written to: {output_file}")
    print(f"Files updated: {stats['files_updated']}/{len(json_files)}")
    print(f"Exercises updated: {stats['exercises_updated']}")

if __name__ == '__main__':
    main()
