#!/usr/bin/env node
/**
 * scripts/docs/update_schema_docs.js
 *
 * Purpose: Automatically update schema documentation after migrations
 * Generates: docs/reference/VERIFIED_TABLE_NAMES.md
 *
 * Usage:
 *   node scripts/docs/update_schema_docs.js
 *   npm run update-docs
 *
 * Requirements:
 *   - SUPABASE_DB_URL environment variable must be set
 *   - Database must be accessible
 */

const { Client } = require('pg');
const fs = require('fs').promises;
const path = require('path');

// Configuration
const SCHEMA_NAME = 'zamm';
const OUTPUT_FILE = path.join(__dirname, '../../docs/reference/VERIFIED_TABLE_NAMES.md');

// Known table categorizations (prefix-based)
const TABLE_CATEGORIES = {
  'workout_': 'Core Workout Tables',
  'res_': 'Result Tables',
  'lib_': 'Library/Catalog Tables',
  'stg_': 'Staging/Import Tables',
  'cfg_': 'Configuration Tables',
  'log_': 'Logging Tables',
  'evt_': 'Event Tables',
  'dim_': 'Dimension/Backup Tables'
};

// Known incorrect table names to warn about
const COMMON_MISTAKES = [
  { wrong: 'workouts', correct: 'workout_main' },
  { wrong: 'block_type_catalog', correct: 'lib_block_types' },
  { wrong: 'block_code_aliases', correct: 'lib_block_aliases' },
  { wrong: 'workout_block_results', correct: 'res_blocks' },
  { wrong: 'item_set_results', correct: 'res_item_sets' }
];

/**
 * Connect to the database
 */
async function connectToDatabase() {
  const connectionString = process.env.SUPABASE_DB_URL;

  if (!connectionString) {
    throw new Error('SUPABASE_DB_URL environment variable is not set');
  }

  const client = new Client({ connectionString });
  await client.connect();
  return client;
}

/**
 * Fetch all tables in the zamm schema
 */
async function fetchAllTables(client) {
  const query = `
    SELECT
      table_name,
      (
        SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema = $1
          AND table_name = t.table_name
      ) as column_count
    FROM information_schema.tables t
    WHERE table_schema = $1
      AND table_type = 'BASE TABLE'
    ORDER BY table_name;
  `;

  const result = await client.query(query, [SCHEMA_NAME]);
  return result.rows;
}

/**
 * Get sample columns for important tables
 */
async function getSampleColumns(client, tableName) {
  const query = `
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = $1
      AND table_name = $2
    ORDER BY ordinal_position
    LIMIT 15;
  `;

  const result = await client.query(query, [SCHEMA_NAME, tableName]);
  return result.rows.map(r => r.column_name);
}

/**
 * Categorize tables by prefix
 */
function categorizeTables(tables) {
  const categorized = {};
  const uncategorized = [];

  for (const table of tables) {
    let matched = false;

    for (const [prefix, category] of Object.entries(TABLE_CATEGORIES)) {
      if (table.table_name.startsWith(prefix)) {
        if (!categorized[category]) {
          categorized[category] = [];
        }
        categorized[category].push(table);
        matched = true;
        break;
      }
    }

    if (!matched) {
      uncategorized.push(table);
    }
  }

  return { categorized, uncategorized };
}

/**
 * Generate markdown documentation
 */
async function generateMarkdown(tables, client) {
  const timestamp = new Date().toISOString().split('T')[0];
  const totalTables = tables.length;
  const { categorized, uncategorized } = categorizeTables(tables);

  let markdown = `# Verified Table Names (zamm Schema)

**Last Verified:** ${timestamp}
**Method:** Automated query via update_schema_docs.js
**Total Tables:** ${totalTables}

---

## ✅ ACTUAL TABLE NAMES

`;

  // Add categorized tables
  for (const [category, categoryTables] of Object.entries(categorized)) {
    markdown += `### ${category} (${categoryTables.length})\n`;

    for (const table of categoryTables) {
      const columns = await getSampleColumns(client, table.table_name);
      markdown += `- \`${table.table_name}\` ✅ (${table.column_count} columns)\n`;
    }

    markdown += '\n';
  }

  // Add uncategorized tables if any
  if (uncategorized.length > 0) {
    markdown += `### Other Tables (${uncategorized.length})\n`;
    for (const table of uncategorized) {
      markdown += `- \`${table.table_name}\` ✅ (${table.column_count} columns)\n`;
    }
    markdown += '\n';
  }

  // Add common mistakes section
  markdown += `---

## ❌ COMMON MISTAKES (Tables That DON'T Exist)

| WRONG Name | CORRECT Name |
|------------|--------------|
`;

  for (const mistake of COMMON_MISTAKES) {
    markdown += `| \`${mistake.wrong}\` | \`${mistake.correct}\` |\n`;
  }

  // Add verification commands
  markdown += `
---

## 🔍 Verification Commands

### Verify a specific table:
\`\`\`bash
./scripts/utils/inspect_db.sh <table_name>
\`\`\`

### List all tables:
\`\`\`bash
psql "$SUPABASE_DB_URL" -c "SELECT tablename FROM pg_tables WHERE schemaname = '${SCHEMA_NAME}' ORDER BY tablename;"
\`\`\`

### Update this documentation:
\`\`\`bash
npm run update-docs
\`\`\`

---

## 📊 Sample Table Structures

`;

  // Add sample structures for key tables
  const keyTables = ['workout_main', 'lib_block_types', 'res_blocks', 'stg_imports'];

  for (const tableName of keyTables) {
    const table = tables.find(t => t.table_name === tableName);
    if (table) {
      const columns = await getSampleColumns(client, tableName);
      markdown += `### ${tableName} (${table.column_count} columns)\n\`\`\`\n`;
      markdown += columns.join(', ');
      if (table.column_count > columns.length) {
        markdown += `, ... (${table.column_count - columns.length} more)`;
      }
      markdown += `\n\`\`\`\n\n`;
    }
  }

  markdown += `---

**IMPORTANT:** This documentation is automatically generated. Always verify table names using the inspection tool before writing SQL.

**Last Updated:** ${timestamp} (automated)
`;

  return markdown;
}

/**
 * Main execution
 */
async function main() {
  console.log('🔍 Connecting to database...');

  let client;
  try {
    client = await connectToDatabase();
    console.log('✅ Connected successfully');

    console.log(`\n📋 Fetching all tables from '${SCHEMA_NAME}' schema...`);
    const tables = await fetchAllTables(client);
    console.log(`✅ Found ${tables.length} tables`);

    console.log('\n📝 Generating markdown documentation...');
    const markdown = await generateMarkdown(tables, client);

    console.log(`\n💾 Writing to ${OUTPUT_FILE}...`);
    await fs.writeFile(OUTPUT_FILE, markdown, 'utf8');
    console.log('✅ Documentation updated successfully');

    console.log('\n📊 Summary:');
    console.log(`   - Total tables: ${tables.length}`);
    console.log(`   - Output file: ${OUTPUT_FILE}`);
    console.log(`   - Timestamp: ${new Date().toISOString()}`);

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  } finally {
    if (client) {
      await client.end();
    }
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { main };
