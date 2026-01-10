#!/usr/bin/env node

/**
 * Add equipment_key to all exercises in golden set JSON files
 * Based on zamm.equipment_catalog
 */

const fs = require('fs');
const path = require('path');

// Equipment mapping rules based on exercise names
const equipmentMapping = {
  // Free weights
  'barbell': ['Back Squat', 'Front Squat', 'Barbell', 'Squat', 'Deadlift', 'Clean', 'Snatch', 'Press', 'Bench Press', 'Overhead Press', 'Thruster', 'Power Clean', 'Hang Clean'],
  'dumbbell': ['DB', 'Dumbbell', 'Dumbell'],
  'kettlebell': ['KB', 'Kettlebell'],
  
  // Cardio machines
  'rowing_machine': ['Row', 'C2', 'Rowing', 'Erg', 'Concept2'],
  'assault_bike': ['Assault Bike', 'AB', 'Air Bike'],
  'bike': ['Bike', 'Stationary Bike'],
  'treadmill': ['Treadmill', 'Jog', 'Run'],
  'ski_erg': ['Ski Erg', 'Ski'],
  
  // Machines
  'cable_machine': ['Cable'],
  'lat_pulldown': ['Lat Pulldown'],
  'leg_press': ['Leg Press'],
  
  // Bodyweight equipment
  'pull_up_bar': ['Pull-up', 'Pullup', 'Pull Up', 'Chin-up', 'Chinup', 'Bar Hang', 'Muscle-up'],
  'dip_station': ['Dip', 'Dips'],
  'rings': ['Ring'],
  
  // Bands
  'resistance_band': ['Band', 'Resistance Band'],
  'mini_band': ['Mini-Band', 'Mini Band', 'Miniband'],
  
  // Mobility & Recovery
  'foam_roller': ['Foam Roll', 'FR', 'Foam Roller'],
  'lacrosse_ball': ['Lacrosse Ball', 'Lacrosse'],
  'pvc_pipe': ['PVC'],
  
  // Functional
  'wall_ball': ['Wall Ball', 'WB'],
  'medicine_ball': ['Medicine Ball', 'Med Ball'],
  'slam_ball': ['Slam Ball'],
  'jump_rope': ['Jump Rope', 'DU', 'Double Under', 'Single Under'],
  'box': ['Box Jump', 'Step Up', 'Box Step'],
  'sandbag': ['Sandbag', 'Sand Bag'],
  'sled': ['Sled Push', 'Sled Pull', 'Sled'],
  
  // Bodyweight/None
  'bodyweight': ['BW', 'Bodyweight', 'Body Weight', 'Air Squat', 'Push-up', 'Pushup', 'Push Up', 'Burpee', 
                 'Plank', 'Sit-up', 'Situp', 'Mountain Climber', 'Lunge', 'Walk', 'Light Jog', 
                 'Stretch', 'Breathing', 'Mobility', 'Activation']
};

// Determine equipment_key from exercise name
function getEquipmentKey(exerciseName) {
  if (!exerciseName) return 'none';
  
  const lowerName = exerciseName.toLowerCase();
  
  // Check each equipment type
  for (const [equipKey, patterns] of Object.entries(equipmentMapping)) {
    for (const pattern of patterns) {
      if (lowerName.includes(pattern.toLowerCase())) {
        return equipKey;
      }
    }
  }
  
  // Default to bodyweight if uncertain
  return 'bodyweight';
}

// Process a single exercise object
function addEquipmentToExercise(exercise) {
  if (!exercise.equipment_key && exercise.exercise_name) {
    exercise.equipment_key = getEquipmentKey(exercise.exercise_name);
  }
  return exercise;
}

// Recursively process workout structure
function processWorkout(data) {
  if (!data.sessions) return data;
  
  for (const session of data.sessions) {
    if (!session.blocks) continue;
    
    for (const block of session.blocks) {
      if (!block.items) continue;
      
      for (const item of block.items) {
        // Handle exercise_options (alternative exercises)
        if (item.exercise_options && Array.isArray(item.exercise_options)) {
          for (const exercise of item.exercise_options) {
            addEquipmentToExercise(exercise);
          }
        }
        
        // Handle direct exercise (standard format)
        if (item.exercise_name) {
          addEquipmentToExercise(item);
        }
      }
    }
  }
  
  return data;
}

// Main execution
const goldenSetDir = path.join(__dirname, '..', 'data', 'golden_set');
const files = fs.readdirSync(goldenSetDir).filter(f => f.endsWith('.json'));

console.log(`Found ${files.length} JSON files in golden set`);

const stats = {
  filesUpdated: 0,
  exercisesUpdated: 0,
  equipmentUsed: new Map()
};

for (const file of files) {
  const filePath = path.join(goldenSetDir, file);
  
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const data = JSON.parse(content);
    
    // Track before state
    const before = JSON.stringify(data);
    
    // Process workout
    processWorkout(data);
    
    // Check if changed
    const after = JSON.stringify(data);
    if (before !== after) {
      // Write back with pretty formatting
      fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
      stats.filesUpdated++;
      console.log(`✓ Updated: ${file}`);
      
      // Count exercises and equipment
      if (data.sessions) {
        for (const session of data.sessions) {
          if (session.blocks) {
            for (const block of session.blocks) {
              if (block.items) {
                for (const item of block.items) {
                  if (item.exercise_options) {
                    for (const ex of item.exercise_options) {
                      if (ex.equipment_key) {
                        stats.exercisesUpdated++;
                        stats.equipmentUsed.set(ex.equipment_key, 
                          (stats.equipmentUsed.get(ex.equipment_key) || 0) + 1);
                      }
                    }
                  }
                  if (item.exercise_name && item.equipment_key) {
                    stats.exercisesUpdated++;
                    stats.equipmentUsed.set(item.equipment_key, 
                      (stats.equipmentUsed.get(item.equipment_key) || 0) + 1);
                  }
                }
              }
            }
          }
        }
      }
    } else {
      console.log(`  No changes: ${file}`);
    }
  } catch (err) {
    console.error(`✗ Error processing ${file}: ${err.message}`);
  }
}

// Print summary
console.log('\n' + '='.repeat(60));
console.log('SUMMARY');
console.log('='.repeat(60));
console.log(`Files updated: ${stats.filesUpdated} / ${files.length}`);
console.log(`Exercises updated: ${stats.exercisesUpdated}`);
console.log('\nEquipment usage:');

const sortedEquipment = Array.from(stats.equipmentUsed.entries())
  .sort((a, b) => b[1] - a[1]);

for (const [key, count] of sortedEquipment) {
  console.log(`  ${key.padEnd(20)} ${count}`);
}

console.log('='.repeat(60));
