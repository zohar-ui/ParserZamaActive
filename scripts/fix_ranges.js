#!/usr/bin/env node
/**
 * Fix Range Values in Golden Set
 * 
 * According to STAGE2_PARSING_STRATEGY.md:
 * - Ranges like "22-24" should become { min: 22, max: 24 }
 * - Averaged values like 5.75 (from "5.5 to 6") should become { min: 5.5, max: 6 }
 * - target_tempo is NOT a range (it's "3-0-2-0" format)
 */

const fs = require('fs');
const path = require('path');

const GOLDEN_SET_DIR = path.join(__dirname, '../data/golden_set');

// Fields that use range format
const RANGE_FIELDS = [
    'target_rpe',
    'target_stroke_rate', 
    'target_spm',
    'target_damper',
    'target_weight_kg',
    'target_load',
    'target_reps'  // Only if it's a range string
];

// Known averaged values that should be ranges
const AVERAGED_VALUES = {
    5.75: { min: 5.5, max: 6 },
    4.5: { min: 4, max: 5 }
};

function isRangeString(value) {
    if (typeof value !== 'string') return false;
    // Match "X-Y" pattern but NOT tempo "X-X-X-X"
    return /^\d+(\.\d+)?-\d+(\.\d+)?$/.test(value);
}

function parseRangeString(value) {
    const match = value.match(/^(\d+(?:\.\d+)?)-(\d+(?:\.\d+)?)$/);
    if (match) {
        return {
            min: parseFloat(match[1]),
            max: parseFloat(match[2])
        };
    }
    return null;
}

function fixObject(obj, parentKey = '') {
    if (!obj || typeof obj !== 'object') return;
    
    if (Array.isArray(obj)) {
        obj.forEach((item, idx) => fixObject(item, `${parentKey}[${idx}]`));
        return;
    }
    
    // Process each key
    const keys = Object.keys(obj);
    for (const key of keys) {
        const value = obj[key];
        
        // Check if this is a range field
        if (RANGE_FIELDS.some(f => key === f || key.startsWith(f))) {
            // String range like "22-24"
            if (isRangeString(value)) {
                const range = parseRangeString(value);
                if (range) {
                    delete obj[key];
                    obj[`${key}_min`] = range.min;
                    obj[`${key}_max`] = range.max;
                    console.log(`  Fixed: ${key}: "${value}" → ${key}_min: ${range.min}, ${key}_max: ${range.max}`);
                }
            }
            // Averaged number like 5.75
            else if (typeof value === 'number' && AVERAGED_VALUES[value]) {
                const range = AVERAGED_VALUES[value];
                delete obj[key];
                obj[`${key}_min`] = range.min;
                obj[`${key}_max`] = range.max;
                console.log(`  Fixed: ${key}: ${value} → ${key}_min: ${range.min}, ${key}_max: ${range.max}`);
            }
        }
        
        // Recurse into nested objects
        if (typeof value === 'object') {
            fixObject(value, key);
        }
    }
}

function processFile(filePath) {
    const content = fs.readFileSync(filePath, 'utf-8');
    let data;
    
    try {
        data = JSON.parse(content);
    } catch (e) {
        console.error(`Error parsing ${path.basename(filePath)}: ${e.message}`);
        return false;
    }
    
    console.log(`\n📄 ${path.basename(filePath)}`);
    
    const originalStr = JSON.stringify(data);
    fixObject(data);
    
    const changed = JSON.stringify(data) !== originalStr;
    
    if (changed) {
        fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n');
    } else {
        console.log('  No changes needed');
    }
    
    return changed;
}

// Main
console.log('🔧 Fixing Range Values in Golden Set\n');
console.log('Rule: "X-Y" → { _min: X, _max: Y }');
console.log('Rule: averaged values → min/max pairs\n');

const files = fs.readdirSync(GOLDEN_SET_DIR)
    .filter(f => f.endsWith('.json'))
    .map(f => path.join(GOLDEN_SET_DIR, f));

let changedCount = 0;

for (const file of files) {
    if (processFile(file)) {
        changedCount++;
    }
}

console.log(`\n${'='.repeat(50)}`);
console.log(`Total: ${changedCount} files modified`);
