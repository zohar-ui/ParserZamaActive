#!/usr/bin/env node

/**
 * commit_draft.js - Stage 4: Atomic Commit to Database
 *
 * Commits a validated workout draft to the database using the
 * commit_full_workout_v3() stored procedure.
 *
 * Usage:
 *   node scripts/pipeline/commit_draft.js --draft=<draft_id>
 *   npm run commit-draft -- --draft=abc-123-def
 *
 * Prerequisites:
 * - Draft must exist in stg_parse_drafts
 * - Draft must have passed validation (is_valid = true)
 * - User must have approved (if warnings present)
 *
 * This script provides the CLI interface, but the actual commit
 * is performed by the AI agent using MCP.
 */

const fs = require('fs');
const path = require('path');

// Parse command line arguments
function parseArgs() {
  const args = process.argv.slice(2);
  const options = {
    draftId: null,
    force: false,
    dryRun: false
  };

  args.forEach(arg => {
    if (arg.startsWith('--draft=')) {
      options.draftId = arg.split('=')[1];
    } else if (arg === '--force') {
      options.force = true;
    } else if (arg === '--dry-run') {
      options.dryRun = true;
    }
  });

  return options;
}

// Main commit function
async function commitDraft(options) {
  console.log('💾 Stage 4: Atomic Commit to Database\n');
  console.log('=' .repeat(60));

  // Validate draft ID provided
  if (!options.draftId) {
    console.error('❌ Error: No draft ID specified');
    console.error('Usage: npm run commit-draft -- --draft=<draft_id>');
    process.exit(1);
  }

  const draftId = options.draftId;

  console.log(`📝 Draft ID: ${draftId}`);
  console.log(`⚙️  Options:`);
  console.log(`   - Force: ${options.force}`);
  console.log(`   - Dry Run: ${options.dryRun}`);
  console.log();

  // Save context for AI agent
  const context = {
    draftId,
    options,
    timestamp: new Date().toISOString()
  };

  const contextPath = path.join(__dirname, '../../.tmp/commit_context.json');
  fs.mkdirSync(path.dirname(contextPath), { recursive: true });
  fs.writeFileSync(contextPath, JSON.stringify(context, null, 2));

  console.log('=' .repeat(60));
  console.log('\n📋 NEXT STEPS FOR AI AGENT:\n');
  console.log('1️⃣  Retrieve draft from database:');
  console.log(`    SELECT * FROM zamm.stg_parse_drafts WHERE draft_id = '${draftId}'\n`);
  console.log('2️⃣  Check validation status:');
  console.log(`    SELECT * FROM zamm.log_validation_reports`);
  console.log(`    WHERE draft_id = '${draftId}' ORDER BY created_at DESC LIMIT 1\n`);
  console.log('3️⃣  If validation passed:');
  console.log(`    - is_valid = true: Proceed with commit`);
  console.log(`    - has warnings + force=false: Ask user to approve`);
  console.log(`    - has errors: STOP, show errors\n`);
  console.log('4️⃣  Call stored procedure:');
  console.log('    SELECT zamm.commit_full_workout_v3(');
  console.log('      p_import_id := (SELECT import_id FROM zamm.stg_parse_drafts WHERE draft_id = \'${draftId}\'),');
  console.log('      p_draft_id := \'${draftId}\',');
  console.log('      p_ruleset_id := (SELECT ruleset_id FROM zamm.stg_parse_drafts WHERE draft_id = \'${draftId}\'),');
  console.log('      p_athlete_id := (SELECT athlete_id FROM zamm.stg_imports WHERE import_id = ...),');
  console.log('      p_normalized_json := (SELECT normalized_draft FROM zamm.stg_parse_drafts WHERE draft_id = \'${draftId}\')');
  console.log('    );\n');
  console.log('5️⃣  Verify commit:');
  console.log('    - Check workout_id returned');
  console.log('    - Verify records created in workout_main, workout_sessions, etc.');
  console.log('    - Update draft status to \'approved\'\n');
  console.log('6️⃣  Display success summary');
  console.log('=' .repeat(60));
  console.log('\n💡 TIP: Use MCP to execute these queries and handle the commit process.\n');

  // Return context for programmatic use
  return context;
}

// Run if called directly
if (require.main === module) {
  const options = parseArgs();
  commitDraft(options).catch(error => {
    console.error('\n❌ Commit Error:', error.message);
    process.exit(1);
  });
}

module.exports = { commitDraft };
