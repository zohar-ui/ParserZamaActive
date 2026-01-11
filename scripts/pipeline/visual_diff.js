#!/usr/bin/env node

/**
 * visual_diff.js - Display Prescription vs Performance Comparison
 *
 * Creates a visual side-by-side or tree-view comparison showing:
 * - What was prescribed (planned)
 * - What was performed (actual)
 * - Differences and warnings
 *
 * Usage:
 *   node scripts/pipeline/visual_diff.js --json=path/to/parsed.json
 *   const { displayDiff } = require('./visual_diff');
 *   displayDiff(parsedWorkoutJson);
 */

// ANSI color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
  gray: '\x1b[90m'
};

// Format value with unit
function formatValue(obj) {
  if (typeof obj === 'object' && obj !== null && 'value' in obj && 'unit' in obj) {
    return `${obj.value}${obj.unit}`;
  }
  return String(obj);
}

// Display block header
function displayBlockHeader(block) {
  const code = block.block_code || '??';
  const type = block.block_type || 'unknown';
  const name = block.name || 'Unnamed';

  console.log(`\n${colors.cyan}${'═'.repeat(60)}${colors.reset}`);
  console.log(`${colors.bright}Block: ${code} - ${type}${colors.reset}`);
  console.log(`${colors.dim}${name}${colors.reset}`);
  console.log(`${colors.cyan}${'─'.repeat(60)}${colors.reset}`);
}

// Display exercise item comparison
function displayItemComparison(item) {
  const exerciseName = item.exercise_name || 'Unknown Exercise';
  const exerciseKey = item.exercise_key ? `(${item.exercise_key})` : '';
  const equipment = item.equipment_key ? `[${item.equipment_key}]` : '';

  console.log(`\n  ${colors.bright}${exerciseName}${colors.reset} ${colors.dim}${exerciseKey} ${equipment}${colors.reset}`);

  const prescription = item.prescription_data || item.prescription || {};
  const performed = item.performed_data || item.performed || {};

  // Check if performance data exists
  const hasPerformance = performed && Object.keys(performed).length > 0;

  if (!hasPerformance) {
    console.log(`  ${colors.gray}└─ Prescription only (no performance data)${colors.reset}`);
    displayPrescriptionOnly(prescription);
    return;
  }

  // Side-by-side comparison
  console.log(`\n  ${colors.cyan}PRESCRIPTION:${colors.reset}                 ${colors.green}PERFORMED:${colors.reset}`);

  // Compare sets
  if (prescription.target_sets) {
    const actualSets = performed.sets?.length || performed.actual_sets || '?';
    const match = prescription.target_sets === actualSets;
    const symbol = match ? '✓' : '⚠️';
    console.log(`  ├─ Sets: ${prescription.target_sets}                    ├─ Sets: ${actualSets} ${symbol}`);
  }

  // Compare reps (if not tracked per set)
  if (prescription.target_reps && !performed.sets) {
    const actualReps = performed.actual_reps || '?';
    const match = prescription.target_reps === actualReps;
    const symbol = match ? '✓' : '⚠️';
    console.log(`  ├─ Reps: ${prescription.target_reps}                    ├─ Reps: ${actualReps} ${symbol}`);
  }

  // Compare weight
  if (prescription.target_weight) {
    const prescribedWeight = formatValue(prescription.target_weight);
    const actualWeight = performed.load ? formatValue(performed.load) : '?';
    const match = prescribedWeight === actualWeight;
    const symbol = match ? '✓' : '⚠️';
    console.log(`  ├─ Load: ${prescribedWeight}                 ├─ Load: ${actualWeight} ${symbol}`);
  }

  // Compare duration
  if (prescription.target_duration) {
    const prescribedDuration = formatValue(prescription.target_duration);
    const actualDuration = performed.actual_duration ? formatValue(performed.actual_duration) : '?';
    console.log(`  ├─ Duration: ${prescribedDuration}            ├─ Duration: ${actualDuration}`);
  }

  // Compare distance
  if (prescription.target_distance) {
    const prescribedDistance = formatValue(prescription.target_distance);
    const actualDistance = performed.actual_distance ? formatValue(performed.actual_distance) : '?';
    console.log(`  ├─ Distance: ${prescribedDistance}            ├─ Distance: ${actualDistance}`);
  }

  // RPE/RIR
  if (prescription.target_rpe) {
    console.log(`  └─ RPE: ${prescription.target_rpe}                     └─ RPE: ${performed.rpe || '?'}`);
  }

  // Display set-by-set breakdown if available
  if (performed.sets && Array.isArray(performed.sets)) {
    displaySetBreakdown(prescription, performed.sets);
  }

  // Display notes if present
  if (performed.notes) {
    console.log(`  ${colors.dim}  💬 Notes: ${performed.notes}${colors.reset}`);
  }
}

// Display prescription-only data (no performance)
function displayPrescriptionOnly(prescription) {
  if (prescription.target_sets) {
    console.log(`  ${colors.dim}  ├─ Sets: ${prescription.target_sets}${colors.reset}`);
  }
  if (prescription.target_reps) {
    console.log(`  ${colors.dim}  ├─ Reps: ${prescription.target_reps}${colors.reset}`);
  }
  if (prescription.target_weight) {
    console.log(`  ${colors.dim}  ├─ Load: ${formatValue(prescription.target_weight)}${colors.reset}`);
  }
  if (prescription.target_duration) {
    console.log(`  ${colors.dim}  ├─ Duration: ${formatValue(prescription.target_duration)}${colors.reset}`);
  }
  if (prescription.target_rpe) {
    console.log(`  ${colors.dim}  └─ RPE: ${prescription.target_rpe}${colors.reset}`);
  }
}

// Display set-by-set breakdown
function displaySetBreakdown(prescription, sets) {
  console.log(`\n  ${colors.cyan}Set-by-Set Breakdown:${colors.reset}`);

  const targetReps = prescription.target_reps;
  const targetWeight = prescription.target_weight ? formatValue(prescription.target_weight) : null;

  sets.forEach((set, index) => {
    const setNum = set.set_index || index + 1;
    const reps = set.reps || '?';
    const load = set.load ? formatValue(set.load) : targetWeight || '?';
    const rpe = set.rpe || set.rir !== undefined ? `RPE ${set.rpe || 10 - set.rir}` : '';

    // Check if set matches prescription
    let status = '';
    if (targetReps && reps < targetReps) {
      status = `${colors.yellow}⚠️  (target: ${targetReps})${colors.reset}`;
    } else if (targetReps && reps === targetReps) {
      status = `${colors.green}✓${colors.reset}`;
    }

    const notes = set.notes ? `${colors.dim}- ${set.notes}${colors.reset}` : '';

    console.log(`    Set ${setNum}: ${reps} reps @ ${load} ${rpe} ${status} ${notes}`);
  });
}

// Main display function
function displayDiff(workoutJson) {
  console.log(`\n${colors.bright}${colors.cyan}${'═'.repeat(60)}${colors.reset}`);
  console.log(`${colors.bright}  📋 PRESCRIPTION vs PERFORMANCE${colors.reset}`);
  console.log(`${colors.cyan}${'═'.repeat(60)}${colors.reset}`);

  // Validate input
  if (!workoutJson || !workoutJson.sessions) {
    console.error(`${colors.red}❌ Invalid workout JSON: Missing sessions${colors.reset}`);
    return;
  }

  // Iterate through sessions and blocks
  workoutJson.sessions.forEach((session, sessionIndex) => {
    if (session.sessionInfo) {
      console.log(`\n${colors.bright}Session ${sessionIndex + 1}:${colors.reset} ${session.sessionInfo.date || 'No date'}`);
      if (session.sessionInfo.title) {
        console.log(`${colors.dim}${session.sessionInfo.title}${colors.reset}`);
      }
    }

    if (!session.blocks || session.blocks.length === 0) {
      console.log(`${colors.gray}  (No blocks in this session)${colors.reset}`);
      return;
    }

    session.blocks.forEach(block => {
      displayBlockHeader(block);

      // Display block-level prescription/performance
      if (block.prescription || block.performed) {
        const blockPrescription = block.prescription || {};
        const blockPerformed = block.performed || {};

        if (blockPrescription.target_rounds) {
          const actual = blockPerformed.actual_rounds || '?';
          console.log(`  Rounds: ${blockPrescription.target_rounds} → ${actual}`);
        }

        if (blockPrescription.target_duration) {
          const prescribed = formatValue(blockPrescription.target_duration);
          const actual = blockPerformed.actual_duration ? formatValue(blockPerformed.actual_duration) : '?';
          console.log(`  Duration: ${prescribed} → ${actual}`);
        }

        if (blockPerformed.did_complete !== undefined) {
          const status = blockPerformed.did_complete
            ? `${colors.green}✓ Completed${colors.reset}`
            : `${colors.yellow}⚠️  Incomplete${colors.reset}`;
          console.log(`  Status: ${status}`);
        }
      }

      // Display items in the block
      if (!block.items || block.items.length === 0) {
        console.log(`${colors.gray}  (No items in this block)${colors.reset}`);
        return;
      }

      block.items.forEach(item => {
        displayItemComparison(item);
      });
    });
  });

  console.log(`\n${colors.cyan}${'═'.repeat(60)}${colors.reset}\n`);
}

// CLI interface
if (require.main === module) {
  const args = process.argv.slice(2);
  let jsonPath = null;

  args.forEach(arg => {
    if (arg.startsWith('--json=')) {
      jsonPath = arg.split('=')[1];
    }
  });

  if (!jsonPath) {
    console.error('Usage: node visual_diff.js --json=path/to/parsed.json');
    process.exit(1);
  }

  const fs = require('fs');
  const path = require('path');

  try {
    const fullPath = path.resolve(jsonPath);
    const content = fs.readFileSync(fullPath, 'utf8');
    const workoutJson = JSON.parse(content);
    displayDiff(workoutJson);
  } catch (error) {
    console.error(`${colors.red}❌ Error: ${error.message}${colors.reset}`);
    process.exit(1);
  }
}

module.exports = { displayDiff, formatValue };
