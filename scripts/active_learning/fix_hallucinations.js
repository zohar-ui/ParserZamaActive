#!/usr/bin/env node
/**
 * Fix Golden Set - Remove Hallucinated performed Data
 * 
 * According to STAGE2_PARSING_STRATEGY.md:
 * - "completed: true" without explicit evidence = HALLUCINATION
 * - performed that mirrors prescription = HALLUCINATION  
 * - Only keep performed with REAL evidence (Hebrew notes, actual weights)
 */

const fs = require('fs');
const path = require('path');

const GOLDEN_SET_DIR = path.join(__dirname, '../data/golden_set');

function containsHebrew(text) {
    return text && /[\u0590-\u05FF]/.test(text);
}

function isHallucinatedPerformed(performed, prescription) {
    if (!performed) return false;
    
    // "completed: true" is always hallucination unless we have proof
    if (performed.completed === true) {
        // Only real evidence that could justify this:
        // - Hebrew notes
        // - actual_weight different from target
        const hasHebrewNotes = containsHebrew(performed.notes);
        const hasRealWeight = performed.actual_weight_kg && 
            (!prescription?.target_weight_kg || performed.actual_weight_kg !== prescription.target_weight_kg);
        
        if (!hasHebrewNotes && !hasRealWeight) {
            return true;
        }
    }
    
    // Check if performed just mirrors prescription values
    if (prescription) {
        const performedStr = JSON.stringify(performed);
        
        // If performed just copies target values as actual values
        if (performed.actual_sets === prescription.target_sets &&
            performed.actual_reps === prescription.target_reps &&
            !performed.notes &&
            !performed.actual_weight_kg) {
            return true;
        }
        
        // If performed has actual_rounds = target_rounds without evidence
        if (performed.actual_rounds === prescription.target_rounds &&
            !performed.notes &&
            !containsHebrew(JSON.stringify(performed))) {
            return true;
        }
    }
    
    return false;
}

function cleanPerformed(performed) {
    if (!performed) return null;
    
    const cleaned = {};
    
    // Keep only evidence-based fields
    if (performed.notes && containsHebrew(performed.notes)) {
        cleaned.notes = performed.notes;
    }
    
    if (performed.actual_weight_kg) {
        cleaned.actual_weight_kg = performed.actual_weight_kg;
    }
    
    if (Array.isArray(performed.actual_weight_kg)) {
        cleaned.actual_weight_kg = performed.actual_weight_kg;
    }
    
    return Object.keys(cleaned).length > 0 ? cleaned : null;
}

function processFile(filePath) {
    const content = fs.readFileSync(filePath, 'utf-8');
    let data;
    
    try {
        data = JSON.parse(content);
    } catch (e) {
        return { file: path.basename(filePath), changes: 0, error: e.message };
    }
    
    let changes = 0;
    
    // Process sessions -> blocks -> items
    if (data.sessions) {
        for (const session of data.sessions) {
            if (session.blocks) {
                for (const block of session.blocks) {
                    // Check block-level performed
                    if (block.performed) {
                        if (isHallucinatedPerformed(block.performed, block.prescription)) {
                            block.performed = cleanPerformed(block.performed);
                            changes++;
                        }
                    }
                    
                    // Check item-level performed
                    if (block.items) {
                        for (const item of block.items) {
                            if (item.performed) {
                                if (isHallucinatedPerformed(item.performed, item.prescription)) {
                                    item.performed = cleanPerformed(item.performed);
                                    changes++;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Write back if changes made
    if (changes > 0) {
        fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n');
    }
    
    return { file: path.basename(filePath), changes };
}

// Main
console.log('🧹 Removing hallucinated performed data from Golden Set\n');
console.log('Rules:');
console.log('  ❌ "completed: true" without Hebrew notes = HALLUCINATION');
console.log('  ❌ actual_* = target_* without notes = HALLUCINATION');
console.log('  ✅ Keep: Hebrew notes, actual_weight_kg with real values\n');

const files = fs.readdirSync(GOLDEN_SET_DIR)
    .filter(f => f.endsWith('.json'))
    .map(f => path.join(GOLDEN_SET_DIR, f));

let totalChanges = 0;

for (const file of files) {
    const result = processFile(file);
    if (result.changes > 0) {
        console.log(`✏️  ${result.file}: ${result.changes} hallucinations removed`);
        totalChanges += result.changes;
    } else {
        console.log(`✓  ${result.file}`);
    }
}

console.log(`\n${'='.repeat(50)}`);
console.log(`Total: ${totalChanges} hallucinations removed`);
