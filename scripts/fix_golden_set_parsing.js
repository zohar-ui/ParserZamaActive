#!/usr/bin/env node
/**
 * Fix Golden Set Parsing Issues
 * Based on STAGE2_PARSING_STRATEGY.md rules
 * 
 * Key Rules Applied:
 * 1. NULL Rule: If not explicit in source text → null (no inference)
 * 2. Hebrew text = performed notes
 * 3. "Status: completed" alone does NOT mean performed data exists
 * 4. performed.completed: true is a HALLUCINATION if no evidence
 * 5. Only actual numbers from source become performed values
 */

const fs = require('fs');
const path = require('path');

const GOLDEN_SET_DIR = path.join(__dirname, '../data/golden_set');

// Load source text for a JSON file
function loadSourceText(jsonFile) {
    const txtFile = jsonFile.replace('.json', '.txt');
    if (fs.existsSync(txtFile)) {
        return fs.readFileSync(txtFile, 'utf-8');
    }
    return null;
}

// Check if text contains Hebrew
function containsHebrew(text) {
    return /[\u0590-\u05FF]/.test(text);
}

// Extract performed evidence from source text for a specific block
function extractPerformedEvidence(sourceText, blockLabel) {
    if (!sourceText) return { hasEvidence: false, notes: null, values: {} };
    
    // Find the block section
    const blockPattern = new RegExp(`${blockLabel}\\)[^]*?(?=[A-Z]\\)|$)`, 'g');
    const blockMatch = sourceText.match(blockPattern);
    
    if (!blockMatch) return { hasEvidence: false, notes: null, values: {} };
    
    const blockText = blockMatch[0];
    
    // Check for Hebrew notes (performance indicators)
    const hebrewLines = [];
    const lines = blockText.split('\n');
    
    for (const line of lines) {
        // Hebrew text with leading whitespace = performance note
        if (/^\s+.*[\u0590-\u05FF]/.test(line)) {
            hebrewLines.push(line.trim());
        }
    }
    
    // Extract actual weight values (e.g., "10 ק")
    const weightMatch = blockText.match(/(\d+(?:\.\d+)?)\s*ק/);
    const actualWeight = weightMatch ? parseFloat(weightMatch[1]) : null;
    
    // Check for explicit completion notes
    const hasCompletionNote = /תקין|עשיתי|הצלחתי|בוצע/.test(blockText);
    
    return {
        hasEvidence: hebrewLines.length > 0 || actualWeight !== null,
        notes: hebrewLines.length > 0 ? hebrewLines.join(' | ') : null,
        values: {
            actual_weight_kg: actualWeight
        },
        hasCompletionNote
    };
}

// Fix a single item's performed field
function fixItemPerformed(item, evidence, sourceText, itemIndex, totalItems) {
    const originalPerformed = item.performed;
    
    // If no evidence at all, performed should be null
    if (!evidence.hasEvidence && !originalPerformed?.notes) {
        // Check if original performed just copied prescription
        if (originalPerformed && JSON.stringify(originalPerformed).includes('"completed"')) {
            // HALLUCINATION: "completed: true" without evidence
            return null;
        }
        
        // Check if performed has actual values vs just copied prescription
        if (originalPerformed) {
            const hasActualData = originalPerformed.actual_weight_kg || 
                                  (originalPerformed.notes && containsHebrew(originalPerformed.notes)) ||
                                  (Array.isArray(originalPerformed.actual_reps) && 
                                   originalPerformed.actual_reps.some(r => r !== item.prescription?.target_reps));
            
            if (!hasActualData) {
                // Performed just mirrors prescription - it's inference, not evidence
                return null;
            }
        }
    }
    
    // Check if item-level has specific Hebrew note
    if (originalPerformed?.notes && containsHebrew(originalPerformed.notes)) {
        // Only keep if notes are specifically about this exercise
        // Block-level notes should stay at block level, not propagate to all items
        const exerciseName = item.exercise_name?.toLowerCase() || '';
        const notesLower = originalPerformed.notes.toLowerCase();
        
        // Generic block completion notes shouldn't propagate
        if (/^(תקין|בוצע|בסדר|ok)$/i.test(originalPerformed.notes.trim())) {
            // This is a block-level completion note, not item-specific
            // Only keep on last item in block (where it appeared in text)
            if (itemIndex !== totalItems - 1) {
                return null;
            }
        }
        
        return { notes: originalPerformed.notes };
    }
    
    // If there's block-level evidence with weight, only apply to items that match
    if (evidence.values.actual_weight_kg) {
        // Weight evidence - only if original had it (was parsed correctly)
        if (originalPerformed?.actual_weight_kg) {
            return { actual_weight_kg: originalPerformed.actual_weight_kg };
        }
    }
    
    return null;
}

// Fix a single block's performed field
function fixBlockPerformed(block, evidence) {
    const originalPerformed = block.performed;
    
    // Block-level performed should only have notes, not completion status
    if (!evidence.hasEvidence) {
        // Check for hallucinated completion
        if (originalPerformed?.completed === true && !evidence.hasCompletionNote) {
            return null;
        }
        if (originalPerformed?.actual_sets && !evidence.hasEvidence) {
            return null;
        }
    }
    
    // Keep only evidence-based data
    if (evidence.notes) {
        return { notes: evidence.notes };
    }
    
    return null;
}

// Process a single JSON file
function processJsonFile(jsonPath) {
    const content = fs.readFileSync(jsonPath, 'utf-8');
    let workout;
    
    try {
        workout = JSON.parse(content);
    } catch (e) {
        console.error(`Error parsing ${jsonPath}: ${e.message}`);
        return { changes: 0, errors: 1 };
    }
    
    const sourceText = loadSourceText(jsonPath);
    let changes = 0;
    
    // Process each session
    if (workout.sessions) {
        for (const session of workout.sessions) {
            if (session.blocks) {
                for (const block of session.blocks) {
                    const evidence = extractPerformedEvidence(sourceText, block.block_label);
                    
                    // Fix block-level performed
                    const originalBlockPerformed = JSON.stringify(block.performed);
                    block.performed = fixBlockPerformed(block, evidence);
                    if (JSON.stringify(block.performed) !== originalBlockPerformed) {
                        changes++;
                    }
                    
                    // Fix item-level performed
                    if (block.items) {
                        const totalItems = block.items.length;
                        block.items.forEach((item, idx) => {
                            const originalItemPerformed = JSON.stringify(item.performed);
                            item.performed = fixItemPerformed(item, evidence, sourceText, idx, totalItems);
                            if (JSON.stringify(item.performed) !== originalItemPerformed) {
                                changes++;
                            }
                        });
                    }
                }
            }
        }
    }
    
    // Write back
    fs.writeFileSync(jsonPath, JSON.stringify(workout, null, 2) + '\n', 'utf-8');
    
    return { changes, errors: 0 };
}

// Main execution
function main() {
    console.log('🔧 Fixing Golden Set Parsing based on STAGE2_PARSING_STRATEGY.md\n');
    console.log('Rules applied:');
    console.log('  1. NULL Rule: No evidence → null (not inference)');
    console.log('  2. "completed: true" is hallucination without proof');
    console.log('  3. Keep only Hebrew notes and explicit values\n');
    
    const jsonFiles = fs.readdirSync(GOLDEN_SET_DIR)
        .filter(f => f.endsWith('.json'))
        .map(f => path.join(GOLDEN_SET_DIR, f));
    
    let totalChanges = 0;
    let totalErrors = 0;
    
    for (const jsonFile of jsonFiles) {
        const fileName = path.basename(jsonFile);
        const result = processJsonFile(jsonFile);
        
        if (result.changes > 0) {
            console.log(`✏️  ${fileName}: ${result.changes} changes`);
            totalChanges += result.changes;
        } else {
            console.log(`✓  ${fileName}: no changes needed`);
        }
        
        totalErrors += result.errors;
    }
    
    console.log('\n' + '='.repeat(50));
    console.log(`Total: ${totalChanges} changes across ${jsonFiles.length} files`);
    if (totalErrors > 0) {
        console.log(`⚠️  ${totalErrors} errors encountered`);
    }
}

main();
