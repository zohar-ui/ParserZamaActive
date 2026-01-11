#!/usr/bin/env node

/**
 * parse_workout.js - Master Orchestrator for Workout Parsing Pipeline
 *
 * Stages 1-3: Ingest → Parse → Validate
 *
 * Usage:
 *   node scripts/pipeline/parse_workout.js --file=path/to/workout.txt
 *   npm run pipeline -- --file=data/golden_set/tomer_2025-11-02_simple_deadlift.txt
 *
 * This script is designed to work WITH Claude Code + MCP, not as a standalone parser.
 * The AI agent drives the actual parsing logic using MCP database queries.
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Parse command line arguments
function parseArgs() {
  const args = process.argv.slice(2);
  const options = {
    file: null,
    validateOnly: false,
    dryRun: false,
    noGit: false,
    force: false
  };

  args.forEach(arg => {
    if (arg.startsWith('--file=')) {
      options.file = arg.split('=')[1];
    } else if (arg === '--validate-only') {
      options.validateOnly = true;
    } else if (arg === '--dry-run') {
      options.dryRun = true;
    } else if (arg === '--no-git') {
      options.noGit = true;
    } else if (arg === '--force') {
      options.force = true;
    }
  });

  return options;
}

// Calculate SHA-256 checksum for idempotency
function calculateChecksum(text) {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}

// Extract athlete name and date from filename
function parseFilename(filename) {
  const basename = path.basename(filename, '.txt');
  const parts = basename.split('_');

  // Format: athlete_YYYY-MM-DD_description.txt
  // Example: tomer_2025-11-02_simple_deadlift.txt

  let athleteName = null;
  let workoutDate = null;

  if (parts.length >= 2) {
    // First part is athlete name (can have spaces if using dashes)
    athleteName = parts[0].replace(/-/g, ' ');

    // Second part should be date
    const dateMatch = parts[1].match(/(\d{4}-\d{2}-\d{2})/);
    if (dateMatch) {
      workoutDate = dateMatch[1];
    }
  }

  return { athleteName, workoutDate };
}

// Main pipeline function
async function runPipeline(options) {
  console.log('🚀 Master Orchestrator - Workout Parsing Pipeline\n');
  console.log('=' .repeat(60));

  // Validate file exists
  if (!options.file) {
    console.error('❌ Error: No file specified');
    console.error('Usage: npm run pipeline -- --file=path/to/workout.txt');
    process.exit(1);
  }

  const filePath = path.resolve(options.file);
  if (!fs.existsSync(filePath)) {
    console.error(`❌ Error: File not found: ${filePath}`);
    process.exit(1);
  }

  // Read workout file
  console.log(`📄 Reading file: ${path.basename(filePath)}`);
  const rawText = fs.readFileSync(filePath, 'utf8');
  const checksum = calculateChecksum(rawText);
  const fileInfo = parseFilename(filePath);

  console.log(`   Size: ${rawText.length} characters`);
  console.log(`   Checksum: ${checksum.substring(0, 16)}...`);
  if (fileInfo.athleteName) {
    console.log(`   Detected athlete: ${fileInfo.athleteName}`);
  }
  if (fileInfo.workoutDate) {
    console.log(`   Detected date: ${fileInfo.workoutDate}`);
  }
  console.log();

  // Create context object for AI agent
  const context = {
    filePath,
    rawText,
    checksum,
    athleteName: fileInfo.athleteName,
    workoutDate: fileInfo.workoutDate,
    options,
    timestamp: new Date().toISOString()
  };

  // Save context to temp file for AI agent to read
  const contextPath = path.join(__dirname, '../../.tmp/pipeline_context.json');
  fs.mkdirSync(path.dirname(contextPath), { recursive: true });
  fs.writeFileSync(contextPath, JSON.stringify(context, null, 2));

  console.log('=' .repeat(60));
  console.log('\n✅ Stage 1: Context & Ingestion - Ready');
  console.log('\n📋 NEXT STEPS FOR AI AGENT:\n');
  console.log('The workout file is loaded and ready for processing.');
  console.log('Context saved to: .tmp/pipeline_context.json\n');
  console.log('AI Agent should now:\n');
  console.log('1️⃣  Find athlete in database using MCP:');
  console.log('    "Find athlete named \'${athleteName}\' in lib_athletes table"\n');
  console.log('2️⃣  Get active parser ruleset:');
  console.log('    "Get active ruleset from cfg_parser_rules"\n');
  console.log('3️⃣  Import raw text with idempotency check:');
  console.log('    "Import this workout with checksum ${checksum.substring(0, 16)}"\n');
  console.log('4️⃣  Parse the workout following CANONICAL_JSON_SCHEMA.md');
  console.log('    - Separate prescription from performance');
  console.log('    - Lookup exercises in catalog');
  console.log('    - Resolve equipment aliases');
  console.log('    - Normalize block codes\n');
  console.log('5️⃣  Validate parsed JSON:');
  console.log('    "Run validate_workout_draft() on the parsed JSON"\n');
  console.log('6️⃣  If validation passes:');
  console.log('    "Commit using commit_full_workout_v3()"\n');
  console.log('=' .repeat(60));
  console.log('\n💡 TIP: This script prepares the data. The AI agent (you!) performs');
  console.log('       the actual parsing using MCP database queries.\n');

  // Return context for programmatic use
  return context;
}

// Run if called directly
if (require.main === module) {
  const options = parseArgs();
  runPipeline(options).catch(error => {
    console.error('\n❌ Pipeline Error:', error.message);
    process.exit(1);
  });
}

module.exports = { runPipeline, calculateChecksum, parseFilename };
