#!/usr/bin/env node

/**
 * Schema v3.0 Migration Script
 * 
 * Changes:
 * 1. Reorder item fields: item_sequence → exercise_name → equipment_key → prescription → performed
 * 2. Convert weight fields from simple values to {value, unit} structure
 * 
 * Usage: node scripts/migrate_schema_v3.js
 */

const fs = require('fs');
const path = require('path');

const GOLDEN_SET_DIR = path.join(__dirname, '..', 'data', 'golden_set');

// Weight field patterns to transform
const WEIGHT_FIELDS = [
  'actual_weight_kg',
  'target_weight_kg',
  'target_weight_kg_min',
  'target_weight_kg_max',
  'target_load',
  'actual_load'
];

// Statistics
let stats = {
  filesProcessed: 0,
  itemsReordered: 0,
  weightFieldsConverted: 0,
  errors: []
};

/**
 * Convert weight value to new structure
 */
function convertWeight(value, field) {
  if (value === null || value === undefined) {
    return null;
  }

  // Handle arrays (multiple sets)
  if (Array.isArray(value)) {
    return value.map(v => ({ value: v, unit: 'kg' }));
  }

  // Handle single values
  return { value: value, unit: 'kg' };
}

/**
 * Transform weight fields in an object
 */
function transformWeights(obj) {
  if (!obj || typeof obj !== 'object') {
    return;
  }

  // Handle min/max range pattern
  if (obj.target_weight_kg_min !== undefined && obj.target_weight_kg_max !== undefined) {
    obj.target_weight = {
      value_min: obj.target_weight_kg_min,
      value_max: obj.target_weight_kg_max,
      unit: 'kg'
    };
    delete obj.target_weight_kg_min;
    delete obj.target_weight_kg_max;
    stats.weightFieldsConverted += 2;
  }

  // Handle individual weight fields
  WEIGHT_FIELDS.forEach(field => {
    if (obj[field] !== undefined) {
      // Determine new field name
      let newField = field.replace('_kg', '');
      
      // Skip if already converted as part of min/max
      if (field === 'target_weight_kg_min' || field === 'target_weight_kg_max') {
        return;
      }

      obj[newField] = convertWeight(obj[field], field);
      delete obj[field];
      stats.weightFieldsConverted++;
    }
  });

  // Recursively process nested objects and arrays
  Object.keys(obj).forEach(key => {
    if (Array.isArray(obj[key])) {
      obj[key].forEach(item => transformWeights(item));
    } else if (typeof obj[key] === 'object' && obj[key] !== null) {
      transformWeights(obj[key]);
    }
  });
}

/**
 * Reorder fields in an item object
 */
function reorderItemFields(item) {
  if (!item || typeof item !== 'object') {
    return item;
  }

  // Check if this is an item with exercise_name (identity fields)
  if (!item.exercise_name && !item.exercises && !item.exercise_options) {
    return item;
  }

  // Create new object with desired field order
  const orderedItem = {};
  
  // 1. Sequence
  if (item.item_sequence !== undefined) {
    orderedItem.item_sequence = item.item_sequence;
  }

  // 2. Identity fields (exercise_name, equipment_key)
  if (item.exercise_name !== undefined) {
    orderedItem.exercise_name = item.exercise_name;
  }
  if (item.equipment_key !== undefined) {
    orderedItem.equipment_key = item.equipment_key;
  }

  // 3. Prescription
  if (item.prescription !== undefined) {
    orderedItem.prescription = item.prescription;
  }

  // 4. Performed
  if (item.performed !== undefined) {
    orderedItem.performed = item.performed;
  }

  // 5. All other fields (circuit_config, exercises, exercise_options, etc.)
  Object.keys(item).forEach(key => {
    if (!orderedItem.hasOwnProperty(key)) {
      orderedItem[key] = item[key];
    }
  });

  stats.itemsReordered++;
  return orderedItem;
}

/**
 * Process all items in blocks recursively
 */
function processItems(obj) {
  if (!obj || typeof obj !== 'object') {
    return;
  }

  // If this is an items array, reorder each item
  if (obj.items && Array.isArray(obj.items)) {
    obj.items = obj.items.map(item => {
      // Reorder top-level item
      let reorderedItem = reorderItemFields(item);
      
      // Process nested exercises/exercise_options
      if (reorderedItem.exercises && Array.isArray(reorderedItem.exercises)) {
        reorderedItem.exercises = reorderedItem.exercises.map(ex => reorderItemFields(ex));
      }
      if (reorderedItem.exercise_options && Array.isArray(reorderedItem.exercise_options)) {
        reorderedItem.exercise_options = reorderedItem.exercise_options.map(ex => reorderItemFields(ex));
      }
      
      return reorderedItem;
    });
  }

  // Recursively process nested structures
  Object.keys(obj).forEach(key => {
    if (Array.isArray(obj[key])) {
      obj[key].forEach(item => processItems(item));
    } else if (typeof obj[key] === 'object' && obj[key] !== null) {
      processItems(obj[key]);
    }
  });
}

/**
 * Process a single JSON file
 */
function processFile(filename) {
  const filepath = path.join(GOLDEN_SET_DIR, filename);
  
  try {
    console.log(`Processing: ${filename}`);
    
    // Read and parse JSON
    const content = fs.readFileSync(filepath, 'utf8');
    const data = JSON.parse(content);
    
    // Step 1: Reorder fields
    processItems(data);
    
    // Step 2: Transform weights
    transformWeights(data);
    
    // Write back with pretty formatting
    fs.writeFileSync(filepath, JSON.stringify(data, null, 2) + '\n', 'utf8');
    
    stats.filesProcessed++;
    console.log(`✓ ${filename} updated`);
    
  } catch (error) {
    stats.errors.push({ file: filename, error: error.message });
    console.error(`✗ Error processing ${filename}:`, error.message);
  }
}

/**
 * Main execution
 */
function main() {
  console.log('🚀 Starting Schema v3.0 Migration\n');
  console.log('Changes:');
  console.log('  1. Reorder item fields (exercise_name, equipment_key before prescription/performed)');
  console.log('  2. Convert weight fields to {value, unit} structure\n');
  
  // Get all JSON files
  const files = fs.readdirSync(GOLDEN_SET_DIR)
    .filter(f => f.endsWith('.json'))
    .sort();
  
  console.log(`Found ${files.length} JSON files\n`);
  
  // Process each file
  files.forEach(processFile);
  
  // Print summary
  console.log('\n' + '='.repeat(60));
  console.log('📊 Migration Summary');
  console.log('='.repeat(60));
  console.log(`Files processed: ${stats.filesProcessed}/${files.length}`);
  console.log(`Items reordered: ${stats.itemsReordered}`);
  console.log(`Weight fields converted: ${stats.weightFieldsConverted}`);
  
  if (stats.errors.length > 0) {
    console.log(`\n❌ Errors: ${stats.errors.length}`);
    stats.errors.forEach(err => {
      console.log(`  - ${err.file}: ${err.error}`);
    });
  } else {
    console.log('\n✅ Schema v3.0 migration complete!');
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { processFile, transformWeights, reorderItemFields };
