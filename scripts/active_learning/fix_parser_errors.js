#!/usr/bin/env node

/**
 * Auto-fix common parser errors in golden set
 * Usage: node scripts/fix_parser_errors.js [--dry-run] [workout_file]
 */

const fs = require('fs');
const path = require('path');

const GOLDEN_SET_DIR = path.join(__dirname, '../data/golden_set/');

// ============================================
// Fix Functions
// ============================================

/**
 * Fix type errors (strings that should be numbers)
 */
function fixTypeErrors(obj) {
  const numericFields = [
    'target_sets', 'target_reps', 'target_duration_sec',
    'actual_sets', 'actual_reps', 'set_index',
    'target_rpe', 'actual_rpe', 'target_rir', 'actual_rir',
    'target_percentage_1rm', 'rounds', 'target_rounds', 'actual_rounds'
  ];
  
  for (const field of numericFields) {
    if (typeof obj[field] === 'string' && !isNaN(obj[field]) && obj[field].trim() !== '') {
      obj[field] = parseFloat(obj[field]);
    }
  }
  
  // Recursive for nested objects
  for (const key in obj) {
    if (typeof obj[key] === 'object' && obj[key] !== null && !Array.isArray(obj[key])) {
      obj[key] = fixTypeErrors(obj[key]);
    } else if (Array.isArray(obj[key])) {
      obj[key] = obj[key].map(item => 
        typeof item === 'object' ? fixTypeErrors(item) : item
      );
    }
  }
  
  return obj;
}

/**
 * Fix range formats (string ranges to min/max)
 */
function fixRangeFormats(obj) {
  const rangeFields = ['target_reps', 'target_weight', 'target_duration', 'target_rpe'];
  
  for (const field of rangeFields) {
    if (typeof obj[field] === 'string' && obj[field].includes('-')) {
      const match = obj[field].match(/(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)/);
      if (match) {
        const [_, min, max] = match;
        delete obj[field];
        obj[`${field}_min`] = parseFloat(min);
        obj[`${field}_max`] = parseFloat(max);
      }
    }
  }
  
  // Recursive
  for (const key in obj) {
    if (typeof obj[key] === 'object' && obj[key] !== null && !Array.isArray(obj[key])) {
      obj[key] = fixRangeFormats(obj[key]);
    } else if (Array.isArray(obj[key])) {
      obj[key] = obj[key].map(item => 
        typeof item === 'object' ? fixRangeFormats(item) : item
      );
    }
  }
  
  return obj;
}

/**
 * Fix field ordering in BlockItem objects (v3.0)
 */
function fixFieldOrdering(item) {
  if (!item.item_sequence && !item.exercises) return item;
  
  const correctOrder = [
    'item_sequence',
    'exercise_name',
    'exercise_options',
    'exercises',
    'equipment_key',
    'prescription',
    'performed',
    'circuit_config',
    'notes'
  ];
  
  const ordered = {};
  for (const key of correctOrder) {
    if (key in item) {
      ordered[key] = item[key];
    }
  }
  
  // Add any remaining fields
  for (const key in item) {
    if (!(key in ordered)) {
      ordered[key] = item[key];
    }
  }
  
  return ordered;
}

/**
 * Fix weight structure (legacy *_kg to v3.0 {value, unit})
 */
function fixWeightStructure(obj) {
  const weightFields = [
    { old: 'target_weight_kg', new: 'target_weight', unit: 'kg' },
    { old: 'target_weight_lbs', new: 'target_weight', unit: 'lbs' },
    { old: 'actual_weight_kg', new: 'actual_weight', unit: 'kg' },
    { old: 'actual_weight_lbs', new: 'actual_weight', unit: 'lbs' },
    { old: 'load_kg', new: 'load', unit: 'kg' },
    { old: 'load_lbs', new: 'load', unit: 'lbs' }
  ];
  
  for (const { old, new: newField, unit } of weightFields) {
    if (old in obj) {
      const value = obj[old];
      delete obj[old];
      obj[newField] = { value, unit };
    }
  }
  
  // Recursive
  for (const key in obj) {
    if (typeof obj[key] === 'object' && obj[key] !== null && !Array.isArray(obj[key])) {
      obj[key] = fixWeightStructure(obj[key]);
    } else if (Array.isArray(obj[key])) {
      obj[key] = obj[key].map(item => 
        typeof item === 'object' ? fixWeightStructure(item) : item
      );
    }
  }
  
  return obj;
}

/**
 * Apply all fixes to a workout object
 */
function fixWorkout(workout) {
  // Apply fixes in order
  workout = fixTypeErrors(workout);
  workout = fixRangeFormats(workout);
  workout = fixWeightStructure(workout);
  
  // Fix field ordering in items
  if (workout.sessions) {
    workout.sessions = workout.sessions.map(session => {
      if (session.blocks) {
        session.blocks = session.blocks.map(block => {
          if (block.items) {
            block.items = block.items.map(item => fixFieldOrdering(item));
          }
          return block;
        });
      }
      return session;
    });
  }
  
  return workout;
}

// ============================================
// Main Logic
// ============================================

function fixParserErrors({ dryRun = false, targetFile = null } = {}) {
  console.log('🔧 Parser Auto-Fix Tool');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  
  if (dryRun) {
    console.log('⚠️  DRY RUN MODE - No files will be modified\n');
  }
  
  // Get list of expected.json files
  let files = fs.readdirSync(GOLDEN_SET_DIR)
    .filter(f => f.endsWith('_expected.json'));
  
  // Filter to specific file if provided
  if (targetFile) {
    const targetPattern = targetFile.replace('.txt', '').replace('_expected.json', '');
    files = files.filter(f => f.includes(targetPattern));
    if (files.length === 0) {
      console.error(`❌ No matching file found for: ${targetFile}`);
      process.exit(1);
    }
  }
  
  console.log(`Processing ${files.length} file(s)...\n`);
  
  let fixedCount = 0;
  let errorCount = 0;
  
  for (const file of files) {
    const filePath = path.join(GOLDEN_SET_DIR, file);
    
    try {
      // Read file
      const content = fs.readFileSync(filePath, 'utf8');
      const original = JSON.parse(content);
      
      // Apply fixes
      const fixed = fixWorkout(JSON.parse(content));
      
      // Check if changes were made
      const originalStr = JSON.stringify(original, null, 2);
      const fixedStr = JSON.stringify(fixed, null, 2);
      
      if (originalStr !== fixedStr) {
        console.log(`🔧 ${file}`);
        console.log('   Changes detected:');
        
        // Show what changed (simplified)
        if (JSON.stringify(original) !== JSON.stringify(fixWorkout(original))) {
          console.log('   - Applied type fixes, range formats, weight structure, field ordering');
        }
        
        if (!dryRun) {
          // Backup original
          const backupPath = filePath + '.backup';
          fs.writeFileSync(backupPath, originalStr);
          
          // Write fixed version
          fs.writeFileSync(filePath, fixedStr);
          console.log('   ✅ Fixed (backup created)\n');
        } else {
          console.log('   ⚠️  Would fix (dry run)\n');
        }
        
        fixedCount++;
      } else {
        console.log(`✅ ${file} - No fixes needed`);
      }
      
    } catch (error) {
      console.error(`❌ ${file} - Error: ${error.message}`);
      errorCount++;
    }
  }
  
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('Summary:');
  console.log(`  Files processed: ${files.length}`);
  console.log(`  Files fixed: ${fixedCount}`);
  console.log(`  Errors: ${errorCount}`);
  
  if (!dryRun && fixedCount > 0) {
    console.log('\nNext steps:');
    console.log('  1. Review changes: git diff data/golden_set/');
    console.log('  2. Run validation: ./scripts/validate_golden_set.sh');
    console.log('  3. Commit if ok: git add data/golden_set/ && git commit');
    console.log('\nTo restore backups: rm data/golden_set/*_expected.json && mv data/golden_set/*.backup data/golden_set/*_expected.json');
  }
}

// ============================================
// CLI Entry Point
// ============================================

if (require.main === module) {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');
  const targetFile = args.find(arg => !arg.startsWith('--'));
  
  fixParserErrors({ dryRun, targetFile });
}

module.exports = { fixParserErrors, fixTypeErrors, fixRangeFormats, fixFieldOrdering, fixWeightStructure };
