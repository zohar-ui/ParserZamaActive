#!/usr/bin/env python3
"""
Add equipment_key to exercises in golden set JSON files
Based on equipment catalog from migration 20260110170000
"""

import json
import os
import re
from pathlib import Path

# Equipment mapping based on exercise name patterns
EQUIPMENT_MAPPING = {
    # Barbell exercises
    r'(?i)^(back squat|front squat|deadlift|bb |barbell|sumo deadlift|clean|snatch|overhead press|bench press|row.*barbell|hip thrust.*bb|elevated deadlift)': 'barbell',

    # Dumbbell exercises (pair for bilateral, single for unilateral)
    r'(?i)^(db |dumbbell|one arm.*row|single arm)': 'dumbbell',
    r'(?i)^(dbs |dumbbells)': 'dumbbell_pair',

    # Kettlebell
    r'(?i)^(kb |kettlebell|swing|turkish get)': 'kettlebell',

    # Rowing machine
    r'(?i)^(row|c2 row|rowing|concept2|erg)': 'rowing_machine',

    # Cardio machines
    r'(?i)^(assault bike|air bike|ab )': 'assault_bike',
    r'(?i)^(bike|cycle)': 'bike',
    r'(?i)^(treadmill|run.*treadmill)': 'treadmill',
    r'(?i)^(ski erg)': 'ski_erg',

    # Cable/machines
    r'(?i)^(cable|lat pulldown|leg press|machine|pallof press)': 'cable_machine',

    # Bodyweight equipment
    r'(?i)^(pull.?up|chin.?up)': 'pull_up_bar',
    r'(?i)^(dip|bar dip)': 'dip_station',
    r'(?i)^(ring|muscle up)': 'rings',

    # Bands
    r'(?i)^(band|resistance band|mini band)': 'resistance_band',

    # Recovery/Mobility
    r'(?i)^(foam roll|fr )': 'foam_roller',
    r'(?i)^(lacrosse|lacrosse ball)': 'lacrosse_ball',
    r'(?i)^(massage ball)': 'massage_ball',
    r'(?i)^(pvc|dowel)': 'pvc_pipe',

    # Functional equipment
    r'(?i)^(slam ball)': 'slam_ball',
    r'(?i)^(wall ball|wb )': 'wall_ball',
    r'(?i)^(medicine ball|med ball)': 'medicine_ball',
    r'(?i)^(jump rope|rope|double under|du)': 'jump_rope',
    r'(?i)^(box jump|box step|step up)': 'box',
    r'(?i)^(sandbag)': 'sandbag',
    r'(?i)^(sled)': 'sled',

    # Specialty
    r'(?i)^(landmine)': 'landmine',
    r'(?i)^(trx)': 'trx',
    r'(?i)^(ab wheel)': 'ab_wheel',

    # Bodyweight (must be last as it's the fallback for many exercises)
    r'(?i)^(bw |bodyweight|air squat|push.?up|plank|burpee|sit.?up|bridge|lunge|step|walk|jog|run(?!.*treadmill)|sprint|breathing|stretch|mobility|hip switch|ankle|knee|dead bug|groiner|squat to stand|mcgill|glute bridge|hip airplane|calf raise|toe walk|heel walk|quad smash|hamstring)': 'bodyweight',
}

def determine_equipment(exercise_name: str) -> str:
    """Determine equipment_key based on exercise name"""
    if not exercise_name:
        return 'bodyweight'

    # Check each pattern
    for pattern, equipment_key in EQUIPMENT_MAPPING.items():
        if re.search(pattern, exercise_name):
            return equipment_key

    # Default to bodyweight if no match
    return 'bodyweight'

def add_equipment_to_exercise(exercise: dict, path_context: str = "") -> tuple[dict, str]:
    """Add equipment_key to an exercise if missing. Returns (exercise, action_taken)"""
    if 'equipment_key' in exercise:
        return exercise, "already_present"

    exercise_name = exercise.get('exercise_name', '')
    equipment_key = determine_equipment(exercise_name)
    exercise['equipment_key'] = equipment_key

    action = f"Added '{equipment_key}' to '{exercise_name}' {path_context}"
    return exercise, action

def process_items(items: list, block_label: str = "") -> list[str]:
    """Process items in a block, return list of actions"""
    actions = []
    if not items:
        return actions

    for idx, item in enumerate(items):
        context = f"(block {block_label}, item {idx+1})"

        # Check if item has exercise_name directly
        if 'exercise_name' in item:
            _, action = add_equipment_to_exercise(item, context)
            if action != "already_present":
                actions.append(action)

        # Check for exercise_options (array of exercises)
        if 'exercise_options' in item and isinstance(item['exercise_options'], list):
            for opt_idx, option in enumerate(item['exercise_options']):
                opt_context = f"(block {block_label}, item {idx+1}, option {opt_idx+1})"
                _, action = add_equipment_to_exercise(option, opt_context)
                if action != "already_present":
                    actions.append(action)

    return actions

def process_workout_file(filepath: Path) -> tuple[bool, list[str]]:
    """
    Process a single workout JSON file.
    Returns (modified, actions_list)
    """
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)

        actions = []
        modified = False

        # Navigate through sessions -> blocks -> items
        if 'sessions' not in data:
            return False, ["No sessions found"]

        for session_idx, session in enumerate(data['sessions']):
            if 'blocks' not in session:
                continue

            for block_idx, block in enumerate(session['blocks']):
                block_label = block.get('block_label', f"#{block_idx+1}")

                if 'items' in block:
                    block_actions = process_items(block['items'], block_label)
                    actions.extend(block_actions)
                    if block_actions:
                        modified = True

        # Write back if modified
        if modified:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=4, ensure_ascii=False)

        return modified, actions

    except Exception as e:
        return False, [f"ERROR: {str(e)}"]

def main():
    """Main function to process all golden set files"""
    golden_set_dir = Path(__file__).parent.parent / 'data' / 'golden_set'

    if not golden_set_dir.exists():
        print(f"ERROR: Directory not found: {golden_set_dir}")
        return

    json_files = sorted(golden_set_dir.glob('*.json'))

    if not json_files:
        print(f"ERROR: No JSON files found in {golden_set_dir}")
        return

    print(f"Processing {len(json_files)} files in {golden_set_dir}")
    print("=" * 80)

    total_modified = 0
    total_actions = 0

    for filepath in json_files:
        modified, actions = process_workout_file(filepath)

        if modified:
            total_modified += 1
            total_actions += len(actions)
            print(f"\n✓ {filepath.name}")
            for action in actions:
                print(f"  - {action}")
        else:
            if actions and actions[0].startswith("ERROR"):
                print(f"\n✗ {filepath.name}")
                print(f"  - {actions[0]}")
            else:
                print(f"\n○ {filepath.name} (no changes needed)")

    print("\n" + "=" * 80)
    print(f"Summary:")
    print(f"  Files processed: {len(json_files)}")
    print(f"  Files modified: {total_modified}")
    print(f"  Total equipment_keys added: {total_actions}")

    # Print equipment key reference
    print("\n" + "=" * 80)
    print("Equipment Key Reference:")
    print("  barbell, dumbbell, dumbbell_pair, kettlebell")
    print("  rowing_machine, assault_bike, bike, treadmill, ski_erg")
    print("  cable_machine, pull_up_bar, dip_station, rings")
    print("  resistance_band, foam_roller, lacrosse_ball, pvc_pipe")
    print("  wall_ball, medicine_ball, jump_rope, box, sandbag, sled")
    print("  bodyweight (default)")

if __name__ == '__main__':
    main()
