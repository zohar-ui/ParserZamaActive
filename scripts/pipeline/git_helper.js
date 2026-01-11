#!/usr/bin/env node

/**
 * git_helper.js - Git Automation for Workout Processing
 *
 * Handles:
 * - Creating workout-specific branches
 * - Saving processed artifacts (raw, parsed, validation)
 * - Committing with descriptive messages
 * - Returning to main branch
 *
 * Usage:
 *   node scripts/pipeline/git_helper.js --athlete="Tomer Yacov" --date="2025-11-02" --workout-id="abc-123"
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Parse command line arguments
function parseArgs() {
  const args = process.argv.slice(2);
  const options = {
    athlete: null,
    date: null,
    workoutId: null,
    importId: null,
    draftId: null,
    blocks: 0,
    items: 0,
    rawText: null,
    parsedJson: null,
    validationJson: null
  };

  args.forEach(arg => {
    const match = arg.match(/--([^=]+)=(.*)/);
    if (match) {
      const key = match[1].replace(/-([a-z])/g, (_, letter) => letter.toUpperCase());
      options[key] = match[2];
    }
  });

  return options;
}

// Convert athlete name to slug format
function slugify(text) {
  return text
    .toString()
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '-')     // Replace spaces with -
    .replace(/[^\w\-]+/g, '') // Remove non-word chars
    .replace(/\-\-+/g, '-');  // Replace multiple - with single -
}

// Execute git command safely
function gitExec(command, description) {
  try {
    console.log(`   Running: ${description}`);
    const result = execSync(command, { encoding: 'utf8', stdio: 'pipe' });
    return result.trim();
  } catch (error) {
    console.error(`   ❌ Git error: ${error.message}`);
    throw error;
  }
}

// Check if git repo is clean
function isGitClean() {
  try {
    const status = execSync('git status --porcelain', { encoding: 'utf8' });
    return status.trim().length === 0;
  } catch {
    return false;
  }
}

// Get current git branch
function getCurrentBranch() {
  try {
    return execSync('git branch --show-current', { encoding: 'utf8' }).trim();
  } catch {
    return 'main';
  }
}

// Main git workflow
async function createWorkoutBranch(options) {
  console.log('\n🎯 Stage 5: Git Tracking\n');
  console.log('=' .repeat(60));

  // Validate required fields
  if (!options.athlete || !options.date) {
    console.error('❌ Error: Missing required fields (athlete, date)');
    console.error('Usage: --athlete="Name" --date="YYYY-MM-DD"');
    process.exit(1);
  }

  const athleteSlug = slugify(options.athlete);
  const branchName = `data/workout-${athleteSlug}-${options.date}`;
  const originalBranch = getCurrentBranch();

  console.log(`👤 Athlete: ${options.athlete}`);
  console.log(`📅 Date: ${options.date}`);
  console.log(`🌿 Branch: ${branchName}`);
  console.log(`📍 Current branch: ${originalBranch}`);
  console.log();

  // Check if working directory is clean
  if (!isGitClean()) {
    console.warn('⚠️  Warning: Working directory has uncommitted changes');
    console.warn('   Stashing changes before creating branch...');
    gitExec('git stash', 'Stash changes');
  }

  // Create and checkout new branch
  console.log('🔨 Creating workout branch...');
  try {
    gitExec(`git checkout -b ${branchName}`, 'Create branch');
  } catch (error) {
    // Branch might already exist
    console.log('   Branch exists, checking out...');
    gitExec(`git checkout ${branchName}`, 'Checkout existing branch');
  }

  // Create processed directory structure
  const processedDir = path.join(process.cwd(), 'data/processed', athleteSlug);
  fs.mkdirSync(processedDir, { recursive: true });

  console.log('\n💾 Saving artifacts...');

  // Save raw text
  if (options.rawText) {
    const rawPath = path.join(processedDir, `${options.date}_raw.txt`);
    fs.writeFileSync(rawPath, options.rawText);
    console.log(`   ✓ Raw text: ${path.relative(process.cwd(), rawPath)}`);
  }

  // Save parsed JSON
  if (options.parsedJson) {
    const parsedPath = path.join(processedDir, `${options.date}_parsed.json`);
    const parsedContent = typeof options.parsedJson === 'string'
      ? options.parsedJson
      : JSON.stringify(JSON.parse(options.parsedJson), null, 2);
    fs.writeFileSync(parsedPath, parsedContent);
    console.log(`   ✓ Parsed JSON: ${path.relative(process.cwd(), parsedPath)}`);
  }

  // Save validation report
  if (options.validationJson) {
    const validationPath = path.join(processedDir, `${options.date}_validation.json`);
    const validationContent = typeof options.validationJson === 'string'
      ? options.validationJson
      : JSON.stringify(JSON.parse(options.validationJson), null, 2);
    fs.writeFileSync(validationPath, validationContent);
    console.log(`   ✓ Validation: ${path.relative(process.cwd(), validationPath)}`);
  }

  // Stage files
  console.log('\n📦 Staging files...');
  gitExec(`git add data/processed/${athleteSlug}/`, 'Stage processed files');

  // Create commit message
  const commitMessage = `feat: Process workout ${options.athlete} ${options.date}

- Import ID: ${options.importId || 'N/A'}
- Draft ID: ${options.draftId || 'N/A'}
- Workout ID: ${options.workoutId || 'N/A'}
- Blocks: ${options.blocks || 0}
- Items: ${options.items || 0}

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>`;

  // Commit changes
  console.log('\n✍️  Committing changes...');
  gitExec(`git commit -m "${commitMessage.replace(/"/g, '\\"')}"`, 'Commit workout');

  // Return to original branch
  console.log(`\n🔙 Returning to ${originalBranch}...`);
  gitExec(`git checkout ${originalBranch}`, 'Checkout original branch');

  // Restore stash if needed
  try {
    const stashList = execSync('git stash list', { encoding: 'utf8' });
    if (stashList.includes('stash@{0}')) {
      console.log('   Restoring stashed changes...');
      gitExec('git stash pop', 'Restore stash');
    }
  } catch {
    // No stash to restore
  }

  console.log('\n=' .repeat(60));
  console.log('✅ Git tracking complete');
  console.log(`\n📝 Workout branch created: ${branchName}`);
  console.log('   View with: git log --oneline --graph data/processed/');
  console.log('   Merge later: git merge ' + branchName);
  console.log();

  return {
    branchName,
    athleteSlug,
    processedDir
  };
}

// Run if called directly
if (require.main === module) {
  const options = parseArgs();
  createWorkoutBranch(options).catch(error => {
    console.error('\n❌ Git Error:', error.message);
    process.exit(1);
  });
}

module.exports = { createWorkoutBranch, slugify };
