#!/usr/bin/env node
/**
 * Parse Itamar's December 11, 2025 Workout
 * =========================================
 * 
 * Input: Raw text from zamm.stg_imports
 * Output: Structured JSON ready for commit_workout_idempotent()
 */

const fs = require('fs');

// ============================================
// MAIN PARSER
// ============================================

function parseWorkout(rawText) {
    const lines = rawText.split('\n').map(l => l.trim()).filter(l => l);
    
    const workout = {
        workout_date: null,
        title: null,
        status: null,
        sessions: [{
            session_code: null,
            session_order: 1,
            blocks: []
        }]
    };
    
    let currentBlock = null;
    let i = 0;
    
    // Parse header (first 3 lines)
    if (lines[i].match(/^\w+ \w+ \d+, \d{4}$/)) {
        workout.workout_date = parseDateFromHuman(lines[i]);
        i++;
    }
    
    if (lines[i] && lines[i].startsWith('Title:')) {
        workout.title = lines[i].replace('Title:', '').trim();
        i++;
    }
    
    if (lines[i] && lines[i].startsWith('Status:')) {
        workout.status = lines[i].replace('Status:', '').trim();
        i++;
    }
    
    // Parse blocks (A), B), C), etc.)
    for (; i < lines.length; i++) {
        const line = lines[i];
        
        // Check if this is a block header: "A) Mobility:"
        const blockMatch = line.match(/^([A-Z])\)\s*(.+?):\s*(.*)$/);
        if (blockMatch) {
            // Save previous block
            if (currentBlock) {
                workout.sessions[0].blocks.push(currentBlock);
            }
            
            // Start new block
            const blockLabel = blockMatch[1];
            const blockType = blockMatch[2].trim();
            const firstItem = blockMatch[3].trim();
            
            currentBlock = {
                block_label: blockLabel,
                block_code: classifyBlockType(blockType),
                block_type: classifyBlockType(blockType),
                block_title: blockType,
                items: []
            };
            
            // If there's text after the colon, it's the first item
            if (firstItem) {
                const item = parseExerciseLine(firstItem);
                if (item) {
                    currentBlock.items.push(item);
                }
            }
        } else if (currentBlock) {
            // This line belongs to the current block
            // Check if it's an exercise, a note, or data
            const item = parseExerciseLine(line);
            if (item) {
                currentBlock.items.push(item);
            } else if (line.match(/^\d+\s*(rounds?|strokes|מטר|דופק|קצב)/i)) {
                // This is performance data
                addPerformanceNote(currentBlock, line);
            } else if (line.match(/^then\.\.\./i) || line.match(/^rest/i)) {
                // Skip connective text
                continue;
            } else {
                // It's a note
                addNoteToLastItem(currentBlock, line);
            }
        }
    }
    
    // Add last block
    if (currentBlock) {
        workout.sessions[0].blocks.push(currentBlock);
    }
    
    return workout;
}

// ============================================
// BLOCK TYPE CLASSIFIER
// ============================================

function classifyBlockType(text) {
    text = text.toLowerCase();
    
    if (text.match(/mobility|stretch|foam roll|lacrosse/)) return 'MOB';
    if (text.match(/warmup|warm.up|חימום/)) return 'WU';
    if (text.match(/erobic|cardio|row|bike|run|conditioning/)) return 'COND';
    if (text.match(/accessory|accsesory|core|plank/)) return 'ACC';
    if (text.match(/strength|str/)) return 'STR';
    if (text.match(/metcon|amrap|for time/)) return 'METCON';
    if (text.match(/skill/)) return 'SKILL';
    if (text.match(/interval/)) return 'INTV';
    
    return 'OTH';
}

// ============================================
// EXERCISE LINE PARSER
// ============================================

function parseExerciseLine(line) {
    line = line.trim();
    if (!line) return null;
    
    // Pattern 1: "Exercise Name Duration Right/Left"
    // "Foam Roller Lat sweep 40 Sec Right"
    const sidePattern = /^(.+?)\s+(\d+)\s*(sec|min|s)\s+(right|left|r|l)$/i;
    const sideMatch = line.match(sidePattern);
    if (sideMatch) {
        const exerciseName = sideMatch[1].trim();
        const duration = parseInt(sideMatch[2]);
        const unit = sideMatch[3].toLowerCase();
        const side = sideMatch[4].toLowerCase();
        
        return {
            exercise_name: exerciseName,
            equipment_key: guessEquipment(exerciseName),
            prescription: {
                target_duration: { 
                    value: unit === 'min' ? duration * 60 : duration, 
                    unit: 'sec' 
                },
                target_side: side.startsWith('r') ? 'right' : 'left'
            },
            performed: null
        };
    }
    
    // Pattern 2: "Sets x Duration/side Exercise"
    // "2 x 20-25 s/side Side Plank Hold"
    const setsDurationSide = /^(\d+)\s*x\s*(\d+)(?:-(\d+))?\s*(s|sec|min)\/side\s+(.+)$/i;
    const sdsMatch = line.match(setsDurationSide);
    if (sdsMatch) {
        const sets = parseInt(sdsMatch[1]);
        const durationMin = parseInt(sdsMatch[2]);
        const durationMax = sdsMatch[3] ? parseInt(sdsMatch[3]) : durationMin;
        const unit = sdsMatch[4];
        const exerciseName = sdsMatch[5].trim();
        
        return {
            exercise_name: exerciseName,
            equipment_key: guessEquipment(exerciseName),
            prescription: {
                target_sets: sets,
                target_duration_min: { 
                    value: unit === 'min' ? durationMin * 60 : durationMin, 
                    unit: 'sec' 
                },
                target_duration_max: { 
                    value: unit === 'min' ? durationMax * 60 : durationMax, 
                    unit: 'sec' 
                },
                per_side: true
            },
            performed: null
        };
    }
    
    // Pattern 3: "Sets x Duration Exercise"
    // "4 x 10 s McGill Curl-Up"
    const setsDuration = /^(\d+)\s*x\s*(\d+)\s*(s|sec|min)\s+(.+)$/i;
    const sdMatch = line.match(setsDuration);
    if (sdMatch) {
        const sets = parseInt(sdMatch[1]);
        const duration = parseInt(sdMatch[2]);
        const unit = sdMatch[3];
        const exerciseName = sdMatch[4].trim();
        
        return {
            exercise_name: exerciseName,
            equipment_key: guessEquipment(exerciseName),
            prescription: {
                target_sets: sets,
                target_duration: { 
                    value: unit === 'min' ? duration * 60 : duration, 
                    unit: 'sec' 
                }
            },
            performed: null
        };
    }
    
    // Pattern 4: "Duration exercise @ modifier"
    // "5 min easy row @ 22 spm"
    const durationExercise = /^(\d+)\s*(min|sec)\s+([^@]+)(?:@\s*(.+))?$/i;
    const deMatch = line.match(durationExercise);
    if (deMatch) {
        const duration = parseInt(deMatch[1]);
        const unit = deMatch[2].toLowerCase();
        const exerciseName = deMatch[3].trim();
        const modifiers = deMatch[4] ? deMatch[4].trim() : null;
        
        const item = {
            exercise_name: exerciseName,
            equipment_key: guessEquipment(exerciseName),
            prescription: {
                target_duration: { 
                    value: unit === 'min' ? duration * 60 : duration, 
                    unit: 'sec' 
                }
            },
            performed: null
        };
        
        // Parse modifiers (e.g., "22 spm")
        if (modifiers) {
            const spmMatch = modifiers.match(/(\d+)\s*spm/i);
            if (spmMatch) {
                item.prescription.target_spm = parseInt(spmMatch[1]);
            }
        }
        
        return item;
    }
    
    // Pattern 5: "Rounds: Duration exercise @ spm-range"
    // "2:00 row @ 22-24 spm"
    const roundsInterval = /^(\d+):(\d{2})\s+(.+?)(?:@\s*(\d+)-(\d+)\s*spm)?/i;
    const riMatch = line.match(roundsInterval);
    if (riMatch) {
        const minutes = parseInt(riMatch[1]);
        const seconds = parseInt(riMatch[2]);
        const exerciseName = riMatch[3].trim();
        const spmMin = riMatch[4] ? parseInt(riMatch[4]) : null;
        const spmMax = riMatch[5] ? parseInt(riMatch[5]) : null;
        
        const item = {
            exercise_name: exerciseName,
            equipment_key: guessEquipment(exerciseName),
            prescription: {
                target_duration: { 
                    value: minutes * 60 + seconds, 
                    unit: 'sec' 
                }
            },
            performed: null
        };
        
        if (spmMin) {
            item.prescription.target_spm_min = spmMin;
            item.prescription.target_spm_max = spmMax;
        }
        
        return item;
    }
    
    // Pattern 6: "Rounds:" header
    if (line.match(/^(\d+)\s*rounds?:/i)) {
        // This will be handled by the block structure
        return null;
    }
    
    return null;
}

// ============================================
// HELPER FUNCTIONS
// ============================================

function guessEquipment(exerciseName) {
    const name = exerciseName.toLowerCase();
    
    if (name.includes('foam roller')) return 'foam_roller';
    if (name.includes('lacrosse ball')) return 'lacrosse_ball';
    if (name.includes('row')) return 'rowing_machine';
    if (name.includes('plank')) return 'bodyweight';
    if (name.includes('curl') || name.includes('mcgill')) return 'bodyweight';
    
    return null;
}

function parseDateFromHuman(line) {
    // "Thursday December 11, 2025" -> "2025-12-11"
    const match = line.match(/(\w+)\s+(\w+)\s+(\d+),?\s+(\d{4})/);
    if (!match) return null;
    
    const month = match[2];
    const day = String(match[3]).padStart(2, '0');
    const year = match[4];
    
    const months = {
        'January': '01', 'February': '02', 'March': '03', 'April': '04',
        'May': '05', 'June': '06', 'July': '07', 'August': '08',
        'September': '09', 'October': '10', 'November': '11', 'December': '12'
    };
    
    return `${year}-${months[month]}-${day}`;
}

function addPerformanceNote(block, line) {
    if (!block.performed) {
        block.performed = { notes: [] };
    }
    if (!block.performed.notes) {
        block.performed.notes = [];
    }
    block.performed.notes.push(line);
}

function addNoteToLastItem(block, line) {
    if (block.items.length === 0) return;
    
    const lastItem = block.items[block.items.length - 1];
    if (!lastItem.notes) {
        lastItem.notes = [];
    }
    lastItem.notes.push(line);
}

// ============================================
// MAIN EXECUTION
// ============================================

if (require.main === module) {
    const inputFile = process.argv[2] || '/tmp/itamar_dec11_workout.txt';
    
    console.log(`📖 Reading workout from: ${inputFile}`);
    const rawText = fs.readFileSync(inputFile, 'utf-8');
    
    console.log(`🔍 Parsing workout...`);
    const workout = parseWorkout(rawText);
    
    // Add athlete_id (Itamar's UUID)
    workout.athlete_id = '32a29c13-5a35-45a8-85d9-823a590d4b8d';
    
    const outputFile = '/tmp/itamar_dec11_parsed.json';
    fs.writeFileSync(outputFile, JSON.stringify(workout, null, 2), 'utf-8');
    
    console.log(`✅ Parsed successfully!`);
    console.log(`📄 Output saved to: ${outputFile}`);
    console.log(`\n📊 Summary:`);
    console.log(`   - Date: ${workout.workout_date}`);
    console.log(`   - Title: ${workout.title}`);
    console.log(`   - Blocks: ${workout.sessions[0].blocks.length}`);
    
    workout.sessions[0].blocks.forEach(block => {
        console.log(`   - Block ${block.block_label} (${block.block_type}): ${block.items.length} exercises`);
    });
}

module.exports = { parseWorkout };
