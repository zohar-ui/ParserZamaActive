#!/usr/bin/env node
/**
 * ============================================
 * ACTIVE LEARNING LOOP - Parser Brain Update
 * ============================================
 * Purpose: Fetch validation corrections from DB and inject them
 *          into AI parser prompts as few-shot learning examples
 * 
 * Usage: node scripts/update_parser_brain.js
 *        or: npm run learn (if added to package.json)
 * 
 * Flow:
 *   1. Query log_learning_examples for high-priority untrained examples
 *   2. Format as few-shot prompt blocks
 *   3. Inject into docs/guides/AI_PROMPTS.md
 *   4. Mark examples as trained in DB
 * 
 * Created: January 10, 2026
 * ============================================
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// ============================================
// Configuration
// ============================================

// Try to load .env.local if it exists
try {
  const fs = require('fs');
  const path = require('path');
  const envPath = path.join(__dirname, '../.env.local');
  if (fs.existsSync(envPath)) {
    const envContent = fs.readFileSync(envPath, 'utf-8');
    envContent.split('\n').forEach(line => {
      const [key, ...valueParts] = line.split('=');
      if (key && valueParts.length > 0) {
        const value = valueParts.join('=').trim();
        if (!process.env[key.trim()]) {
          process.env[key.trim()] = value;
        }
      }
    });
  }
} catch (err) {
  // Silent fail - will check for required vars later
}

const CONFIG = {
  // Database connection (reads from .env.local or environment)
  supabaseUrl: process.env.SUPABASE_URL || 'https://dtzcamerxuonoeujrgsu.supabase.co',
  supabaseKey: process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY,
  
  // Learning thresholds
  minPriority: 7,              // Only include examples with priority >= 7
  maxExamples: 20,             // Keep total examples under this limit
  maxNewExamples: 5,           // Add max 5 new examples per run
  
  // File paths
  promptsFile: path.join(__dirname, '../docs/guides/AI_PROMPTS.md'),
  
  // Section markers in AI_PROMPTS.md
  learningStartMarker: '## 🧠 Dynamic Learning Examples',
  learningEndMarker: '---\n\n## Prompt - Validation Agent',
};

// ============================================
// Database Client Setup
// ============================================

let supabase;

function initSupabase() {
  if (!CONFIG.supabaseKey) {
    console.error('❌ ERROR: SUPABASE_SERVICE_KEY or SUPABASE_ANON_KEY not found in environment');
    console.error('   Please set it in .env.local file');
    process.exit(1);
  }
  
  supabase = createClient(CONFIG.supabaseUrl, CONFIG.supabaseKey);
  console.log('✅ Supabase client initialized');
}

// ============================================
// Step 1: Fetch Untrained Learning Examples
// ============================================

async function fetchUntrainedExamples() {
  console.log('\n📥 Fetching untrained learning examples...');
  
  const { data, error } = await supabase
    .from('log_learning_examples')
    .select('*')
    .eq('is_included_in_training', false)
    .gte('learning_priority', CONFIG.minPriority)
    .order('learning_priority', { ascending: false })
    .order('created_at', { ascending: false })
    .limit(CONFIG.maxNewExamples);
  
  if (error) {
    console.error('❌ Database query failed:', error.message);
    process.exit(1);
  }
  
  console.log(`   Found ${data.length} examples (priority >= ${CONFIG.minPriority})`);
  
  return data;
}

// ============================================
// Step 2: Format Examples as Few-Shot Blocks
// ============================================

function formatExampleAsPrompt(example) {
  const { 
    example_id,
    original_text, 
    original_json, 
    corrected_json,
    error_type,
    error_location,
    error_description,
    correction_notes,
    learning_priority,
    tags 
  } = example;
  
  // Create human-readable title
  const title = `${error_type.replace(/_/g, ' ').toUpperCase()} (Priority ${learning_priority})`;
  
  // Format tags
  const tagStr = tags && tags.length > 0 ? ` [${tags.join(', ')}]` : '';
  
  // Build the prompt block
  return `
### Example: ${title}${tagStr}

**Original Text:**
\`\`\`
${original_text.trim()}
\`\`\`

**Wrong Output (BEFORE):**
\`\`\`json
${JSON.stringify(original_json, null, 2)}
\`\`\`

**Problem:** ${error_description || 'See correction notes'}
${error_location ? `**Location:** \`${error_location}\`` : ''}

**Corrected Output (AFTER):**
\`\`\`json
${JSON.stringify(corrected_json, null, 2)}
\`\`\`

**Why This Matters:** ${correction_notes || 'This is a common parsing error.'}

**Example ID:** \`${example_id}\` _(for tracking)_

`;
}

// ============================================
// Step 3: Inject Examples into AI_PROMPTS.md
// ============================================

async function injectExamplesIntoPrompts(newExamples) {
  console.log('\n📝 Updating AI_PROMPTS.md...');
  
  // Read current file
  if (!fs.existsSync(CONFIG.promptsFile)) {
    console.error(`❌ File not found: ${CONFIG.promptsFile}`);
    process.exit(1);
  }
  
  let content = fs.readFileSync(CONFIG.promptsFile, 'utf-8');
  
  // Check if learning section exists
  if (!content.includes(CONFIG.learningStartMarker)) {
    console.log('   ℹ️  Learning section not found, creating it...');
    
    // Find insertion point (before validation agent section)
    const insertionPoint = content.indexOf(CONFIG.learningEndMarker);
    if (insertionPoint === -1) {
      console.error('❌ Cannot find insertion point in AI_PROMPTS.md');
      process.exit(1);
    }
    
    // Create new section
    const newSection = `\n${CONFIG.learningStartMarker}

**Purpose:** These examples are automatically generated from validation corrections.
They teach the parser to avoid common mistakes.

**Last Updated:** ${new Date().toISOString().split('T')[0]}

---

`;
    
    content = content.slice(0, insertionPoint) + newSection + content.slice(insertionPoint);
  }
  
  // Extract current learning section
  const startIdx = content.indexOf(CONFIG.learningStartMarker);
  const endIdx = content.indexOf(CONFIG.learningEndMarker, startIdx);
  
  if (startIdx === -1 || endIdx === -1) {
    console.error('❌ Cannot find learning section boundaries');
    process.exit(1);
  }
  
  const beforeSection = content.slice(0, startIdx);
  const afterSection = content.slice(endIdx);
  let learningSection = content.slice(startIdx, endIdx);
  
  // Parse existing examples (count them)
  const existingExampleCount = (learningSection.match(/### Example:/g) || []).length;
  console.log(`   Currently ${existingExampleCount} examples in prompts file`);
  
  // Format new examples
  const newExampleBlocks = newExamples.map(formatExampleAsPrompt).join('\n');
  
  // Append new examples to section
  learningSection += newExampleBlocks;
  
  // Update timestamp
  learningSection = learningSection.replace(
    /\*\*Last Updated:\*\* .+/,
    `**Last Updated:** ${new Date().toISOString().split('T')[0]}`
  );
  
  // Check if we exceed max examples (remove oldest ones)
  const totalExamples = existingExampleCount + newExamples.length;
  if (totalExamples > CONFIG.maxExamples) {
    console.log(`   ⚠️  Total examples (${totalExamples}) exceeds limit (${CONFIG.maxExamples})`);
    console.log('   Removing oldest examples...');
    
    // TODO: Implement example removal logic if needed
    // For now, just warn the user
    console.log('   ℹ️  Manual cleanup recommended');
  }
  
  // Reconstruct file
  const newContent = beforeSection + learningSection + afterSection;
  
  // Write back to file
  fs.writeFileSync(CONFIG.promptsFile, newContent, 'utf-8');
  console.log(`   ✅ Added ${newExamples.length} new examples to AI_PROMPTS.md`);
}

// ============================================
// Step 4: Mark Examples as Trained in DB
// ============================================

async function markExamplesAsTrained(examples) {
  console.log('\n✅ Marking examples as trained...');
  
  const exampleIds = examples.map(ex => ex.example_id);
  
  const { error } = await supabase
    .from('log_learning_examples')
    .update({ 
      is_included_in_training: true,
      included_in_training_at: new Date().toISOString()
    })
    .in('example_id', exampleIds);
  
  if (error) {
    console.error('❌ Failed to update database:', error.message);
    process.exit(1);
  }
  
  console.log(`   Updated ${exampleIds.length} records in database`);
}

// ============================================
// Main Execution
// ============================================

async function main() {
  console.log('🤖 ACTIVE LEARNING LOOP - Starting...\n');
  console.log('=' .repeat(60));
  
  try {
    // Step 0: Initialize
    initSupabase();
    
    // Step 1: Fetch untrained examples
    const newExamples = await fetchUntrainedExamples();
    
    if (newExamples.length === 0) {
      console.log('\n✨ No new examples to train! Parser is up to date.');
      console.log('   Run validation and make corrections to generate new examples.');
      return;
    }
    
    // Step 2: Format examples (happens in step 3)
    
    // Step 3: Inject into prompts file
    await injectExamplesIntoPrompts(newExamples);
    
    // Step 4: Mark as trained
    await markExamplesAsTrained(newExamples);
    
    // Summary
    console.log('\n' + '=' .repeat(60));
    console.log('🎉 ACTIVE LEARNING COMPLETE!\n');
    console.log(`   📚 ${newExamples.length} new examples added to parser brain`);
    console.log(`   📄 Updated: ${CONFIG.promptsFile}`);
    console.log(`   💾 Database marked ${newExamples.length} examples as trained`);
    console.log('\n💡 Next steps:');
    console.log('   1. Review the updated AI_PROMPTS.md');
    console.log('   2. Use the updated prompts in your next parsing session');
    console.log('   3. The parser should now avoid these mistakes!\n');
    
  } catch (error) {
    console.error('\n❌ FATAL ERROR:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// ============================================
// Execute
// ============================================

if (require.main === module) {
  main();
}

module.exports = { main, fetchUntrainedExamples, formatExampleAsPrompt };
