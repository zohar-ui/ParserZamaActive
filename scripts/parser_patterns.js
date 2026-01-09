/**
 * ZAMM Parser - Regex Patterns Library
 * =====================================
 * 
 * ספריית דפוסים לפרסור טקסט אימונים
 * כל pattern מתועד עם דוגמאות ו-edge cases
 * 
 * Usage:
 *   const { PATTERNS, parseExerciseLine } = require('./parser_patterns');
 */

// ============================================
// DATE PATTERNS
// ============================================

const DATE_PATTERNS = {
    // ISO format: 2025-11-09
    ISO: /(\d{4})-(\d{2})-(\d{2})/,
    
    // Human readable: Sunday November 9, 2025
    HUMAN_LONG: /(\w+)\s+(\w+)\s+(\d{1,2}),?\s+(\d{4})/,
    
    // Short: 9/11/2025 or 11/9/2025
    SHORT_SLASH: /(\d{1,2})\/(\d{1,2})\/(\d{2,4})/,
    
    // European: 9.11.2025
    EUROPEAN: /(\d{1,2})\.(\d{1,2})\.(\d{2,4})/,
};

// ============================================
// SETS & REPS PATTERNS
// ============================================

const SETS_REPS_PATTERNS = {
    // Basic: 3x5, 3X5, 3×5
    BASIC: /(\d+)\s*[xX×]\s*(\d+)/,
    
    // With load: 3x5 @ 100kg, 3x5 @100kg
    WITH_LOAD: /(\d+)\s*[xX×]\s*(\d+)\s*@\s*(\d+(?:\.\d+)?)\s*(kg|lb|%)?/i,
    
    // Per side: 8/8, 10/10
    PER_SIDE: /(\d+)\/(\d+)/,
    
    // Sets x Reps/Side: 3x10/10
    SETS_REPS_SIDE: /(\d+)\s*[xX×]\s*(\d+)\/(\d+)/,
    
    // Just reps: "10 Push-ups"
    REPS_ONLY: /^(\d+)\s+([A-Za-z])/,
    
    // Range: 8-12 reps
    REP_RANGE: /(\d+)\s*-\s*(\d+)\s*(?:reps?)?/i,
};

// Examples:
// "3x5"           → { sets: 3, reps: 5 }
// "3x5 @ 100kg"   → { sets: 3, reps: 5, load: 100, unit: 'kg' }
// "8/8"           → { reps: 8, per_side: true }
// "3x10/10"       → { sets: 3, reps: 10, per_side: true }

// ============================================
// DURATION PATTERNS
// ============================================

const DURATION_PATTERNS = {
    // Minutes: 5 min, 5min, 5 minutes
    MINUTES: /(\d+(?:\.\d+)?)\s*(?:min(?:ute)?s?)/i,
    
    // Seconds: 30 sec, 30sec, 30 seconds
    SECONDS: /(\d+)\s*(?:sec(?:ond)?s?)/i,
    
    // Time format: 5:00, 12:30
    TIME_FORMAT: /(\d+):(\d{2})/,
    
    // Duration with per side: 20/20sec
    DURATION_SIDE: /(\d+)\/(\d+)\s*(?:sec|min)/i,
};

// ============================================
// REST PATTERNS
// ============================================

const REST_PATTERNS = {
    // Rest 2 min, rest 90 sec
    BASIC: /rest\s*(\d+(?:\.\d+)?)\s*(min|sec)?/i,
    
    // Rest 1.5 min, Rest 1:30
    DETAILED: /rest\s*(\d+(?:\.\d+)?)\s*(min(?:ute)?s?|sec(?:ond)?s?)/i,
    
    // **Rest 30 sec btw exercise
    BETWEEN: /\*+\s*rest\s*(\d+)\s*(sec|min)?\s*(?:btw|between)/i,
    
    // E2MOM, E90S
    EMOM: /E(\d+)(?:MOM|S)/i,
};

// ============================================
// INTENSITY PATTERNS
// ============================================

const INTENSITY_PATTERNS = {
    // RPE: @RPE 6, RPE 7, @ RPE 5.5
    RPE_SINGLE: /@?\s*RPE\s*(\d+(?:\.\d+)?)/i,
    
    // RPE Range: RPE 5.5 to 6, RPE 6-7
    RPE_RANGE: /@?\s*RPE\s*(\d+(?:\.\d+)?)\s*(?:to|-)\s*(\d+(?:\.\d+)?)/i,
    
    // Percentage: @70%, @ 80% 1RM
    PERCENTAGE: /@?\s*(\d+)\s*%\s*(?:of\s*)?(1RM|max)?/i,
    
    // RIR (Reps in Reserve): RIR 2, 2 RIR
    RIR: /(?:RIR\s*(\d+)|(\d+)\s*RIR)/i,
};

// ============================================
// TEMPO PATTERNS
// ============================================

const TEMPO_PATTERNS = {
    // Tempo 3-1-2-0, Tempo: 3-1-2-0
    STANDARD: /tempo[:\s]*(\d+)[\s-]+(\d+)[\s-]+(\d+)[\s-]+(\d+)/i,
    
    // Tempo: 3 sec down 2 sec up
    VERBAL: /tempo[:\s]*(\d+)\s*sec\s*down[\s,]*(\d+)\s*sec\s*up/i,
    
    // 31X0 format (compressed)
    COMPRESSED: /tempo[:\s]*(\d)(\d)([X\d])(\d)/i,
};

// ============================================
// BLOCK PATTERNS
// ============================================

const BLOCK_PATTERNS = {
    // A) Block Name, B) Something:
    LETTER_PAREN: /^([A-Z])\)\s*(.+?)(?::|$)/m,
    
    // Block A - Name, Block B: Something
    BLOCK_KEYWORD: /^Block\s*([A-Z])\s*[-:]\s*(.+)/im,
    
    // 1. First block, 2. Second block
    NUMBERED: /^(\d+)\.\s*(.+?)(?::|$)/m,
};

// ============================================
// HEBREW PATTERNS
// ============================================

const HEBREW_PATTERNS = {
    // Any Hebrew text
    ANY_HEBREW: /[\u0590-\u05FF]+/,
    
    // Weight in Hebrew: 100 ק, 50 קילו
    WEIGHT: /(\d+(?:\.\d+)?)\s*(?:ק(?:ילו)?|קג|kg)/,
    
    // Pain scale: 5/10
    PAIN_SCALE: /(\d+)\/10/,
    
    // Common Hebrew instructions
    INSTRUCTION: /נא ל|יש ל|צריך ל|שים לב/,
};

// ============================================
// EXERCISE EXTRACTION PATTERNS
// ============================================

const EXERCISE_PATTERNS = {
    // Exercise: 3x5 @ weight
    COLON_FORMAT: /^([^:]+):\s*(\d+)\s*[xX×]\s*(\d+)/,
    
    // 3x5 Exercise Name
    PREFIX_FORMAT: /^(\d+)\s*[xX×]\s*(\d+)(?:\/\d+)?\s+(.+)/,
    
    // 10 Exercise Name (reps only)
    REPS_PREFIX: /^(\d+)\s+([A-Za-z][A-Za-z\s]+)/,
    
    // Exercise Name (no numbers - for blocks like "Bike / Row")
    NAME_ONLY: /^([A-Za-z][A-Za-z\s\/]+)$/,
};

// ============================================
// PARSER FUNCTIONS
// ============================================

/**
 * Parse a line for exercise information
 * @param {string} line - Single line from workout text
 * @returns {object|null} - Parsed exercise data or null
 */
function parseExerciseLine(line) {
    line = line.trim();
    if (!line) return null;
    
    let match;
    
    // Pattern 1: "Exercise Name: 3x5 @ 100kg"
    match = line.match(/^([^:]+):\s*(\d+)\s*[xX×]\s*(\d+)\s*(?:@\s*(\d+(?:\.\d+)?)\s*(kg|lb|%)?)?/);
    if (match) {
        return {
            name: normalizeExerciseName(match[1]),
            prescription: {
                target_sets: parseInt(match[2]),
                target_reps: parseInt(match[3]),
                ...(match[4] && { target_load_kg: parseFloat(match[4]) }),
                ...(match[5] && { load_unit: match[5].toLowerCase() })
            }
        };
    }
    
    // Pattern 2: "3x10/10 Exercise Name" (with per-side)
    match = line.match(/^(\d+)\s*[xX×]\s*(\d+)\/(\d+)\s+(.+)/);
    if (match) {
        return {
            name: normalizeExerciseName(match[4]),
            prescription: {
                target_sets: parseInt(match[1]),
                target_reps: parseInt(match[2]),
                per_side: true
            }
        };
    }
    
    // Pattern 3: "3x10 Exercise Name"
    match = line.match(/^(\d+)\s*[xX×]\s*(\d+)\s+(.+)/);
    if (match) {
        return {
            name: normalizeExerciseName(match[3]),
            prescription: {
                target_sets: parseInt(match[1]),
                target_reps: parseInt(match[2])
            }
        };
    }
    
    // Pattern 4: "10 Exercise Name" (reps only)
    match = line.match(/^(\d+)\s+([A-Za-z][A-Za-z\s]+)/);
    if (match) {
        return {
            name: normalizeExerciseName(match[2]),
            prescription: {
                target_reps: parseInt(match[1])
            }
        };
    }
    
    // Pattern 5: "5 min Exercise" (duration)
    match = line.match(/^(\d+(?:\.\d+)?)\s*min\s+(.+)/i);
    if (match) {
        return {
            name: normalizeExerciseName(match[2]),
            prescription: {
                target_duration_min: parseFloat(match[1])
            }
        };
    }
    
    return null;
}

/**
 * Parse prescription modifiers from text
 * @param {string} text - Text containing modifiers
 * @returns {object} - Parsed modifiers
 */
function parsePrescriptionModifiers(text) {
    const modifiers = {};
    
    // RPE
    let match = text.match(INTENSITY_PATTERNS.RPE_RANGE);
    if (match) {
        modifiers.target_rpe_min = parseFloat(match[1]);
        modifiers.target_rpe_max = parseFloat(match[2]);
    } else {
        match = text.match(INTENSITY_PATTERNS.RPE_SINGLE);
        if (match) {
            modifiers.target_rpe = parseFloat(match[1]);
        }
    }
    
    // Rest
    match = text.match(REST_PATTERNS.DETAILED);
    if (match) {
        const value = parseFloat(match[1]);
        const unit = (match[2] || 'sec').toLowerCase();
        modifiers.target_rest_sec = unit.startsWith('min') ? value * 60 : value;
    }
    
    // Tempo
    match = text.match(TEMPO_PATTERNS.STANDARD);
    if (match) {
        modifiers.target_tempo = `${match[1]}-${match[2]}-${match[3]}-${match[4]}`;
    } else {
        match = text.match(TEMPO_PATTERNS.VERBAL);
        if (match) {
            modifiers.target_tempo = `${match[1]}-0-${match[2]}-0`;
        }
    }
    
    // Percentage
    match = text.match(INTENSITY_PATTERNS.PERCENTAGE);
    if (match) {
        modifiers.target_intensity_percent = parseInt(match[1]);
        if (match[2]) {
            modifiers.target_intensity_reference = match[2];
        }
    }
    
    return modifiers;
}

/**
 * Classify a note line as prescription or performance
 * @param {string} line - Note line to classify
 * @returns {string} - 'prescription' or 'performance'
 */
function classifyNote(line) {
    // Hebrew = almost always performance
    if (HEBREW_PATTERNS.ANY_HEBREW.test(line)) {
        // Exception: Hebrew instructions
        if (HEBREW_PATTERNS.INSTRUCTION.test(line)) {
            return 'prescription';
        }
        return 'performance';
    }
    
    // Prescription indicators
    const prescriptionIndicators = [
        /^@\s*RPE/i,
        /^Rest\s/i,
        /^Tempo/i,
        /^\*+/,
        /build/i,
        /keep/i,
        /focus/i,
        /target/i,
        /goal/i,
    ];
    
    for (const pattern of prescriptionIndicators) {
        if (pattern.test(line)) return 'prescription';
    }
    
    // Performance indicators
    const performanceIndicators = [
        /did\s/i,
        /got\s/i,
        /felt/i,
        /pain/i,
        /failed/i,
        /hard/i,
        /easy/i,
        /missed/i,
        /used\s*\d/i,
        /^\s*\d+\s*(?:kg|ק)/,
        /completed/i,
        /finished/i,
    ];
    
    for (const pattern of performanceIndicators) {
        if (pattern.test(line)) return 'performance';
    }
    
    // Default to prescription
    return 'prescription';
}

/**
 * Normalize exercise name to title case
 * @param {string} name - Raw exercise name
 * @returns {string} - Normalized name
 */
function normalizeExerciseName(name) {
    return name
        .trim()
        .replace(/\s+/g, ' ')
        .split(' ')
        .map(word => {
            // Keep abbreviations uppercase (DB, PVC, etc.)
            if (word.length <= 3 && word === word.toUpperCase()) {
                return word;
            }
            return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
        })
        .join(' ');
}

/**
 * Parse duration text to minutes
 * @param {string} text - Duration text
 * @returns {number|null} - Duration in minutes
 */
function parseToMinutes(text) {
    let match = text.match(DURATION_PATTERNS.MINUTES);
    if (match) return parseFloat(match[1]);
    
    match = text.match(DURATION_PATTERNS.SECONDS);
    if (match) return parseInt(match[1]) / 60;
    
    match = text.match(DURATION_PATTERNS.TIME_FORMAT);
    if (match) return parseInt(match[1]) + parseInt(match[2]) / 60;
    
    return null;
}

/**
 * Parse duration text to seconds
 * @param {string} text - Duration text
 * @returns {number|null} - Duration in seconds
 */
function parseToSeconds(text) {
    let match = text.match(DURATION_PATTERNS.SECONDS);
    if (match) return parseInt(match[1]);
    
    match = text.match(DURATION_PATTERNS.MINUTES);
    if (match) return parseFloat(match[1]) * 60;
    
    match = text.match(DURATION_PATTERNS.TIME_FORMAT);
    if (match) return parseInt(match[1]) * 60 + parseInt(match[2]);
    
    return null;
}

/**
 * Extract Hebrew weight note (e.g., "10 ק")
 * @param {string} text - Text to search
 * @returns {number|null} - Weight in kg
 */
function extractHebrewWeight(text) {
    const match = text.match(HEBREW_PATTERNS.WEIGHT);
    return match ? parseFloat(match[1]) : null;
}

/**
 * Validate JSON for hallucinations
 * @param {object} json - Parsed workout JSON
 * @param {string} sourceText - Original source text
 * @returns {string[]} - Array of issues found
 */
function validateNoHallucinations(json, sourceText) {
    const issues = [];
    const jsonStr = JSON.stringify(json);
    
    // Check for UUID patterns (likely hallucinated athlete_id)
    const uuidPattern = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi;
    if (jsonStr.match(uuidPattern)) {
        issues.push("CRITICAL: UUID found - likely hallucinated athlete_id");
    }
    
    // Check for assumed session_code
    if (json.sessions?.[0]?.session_code) {
        const hasTimeInSource = /\b(AM|PM|morning|afternoon|evening|בוקר|ערב)\b/i.test(sourceText);
        if (!hasTimeInSource) {
            issues.push("CRITICAL: session_code without evidence in source text");
        }
    }
    
    // Check for numbers not in source
    const jsonNumbers = jsonStr.match(/:\s*(\d{2,})/g) || [];
    for (const numMatch of jsonNumbers) {
        const num = numMatch.replace(/[:\s]/g, '');
        if (parseInt(num) > 20 && !sourceText.includes(num)) {
            issues.push(`WARNING: Number ${num} not found in source text`);
        }
    }
    
    return issues;
}

// ============================================
// EXPORTS
// ============================================

module.exports = {
    // Pattern collections
    DATE_PATTERNS,
    SETS_REPS_PATTERNS,
    DURATION_PATTERNS,
    REST_PATTERNS,
    INTENSITY_PATTERNS,
    TEMPO_PATTERNS,
    BLOCK_PATTERNS,
    HEBREW_PATTERNS,
    EXERCISE_PATTERNS,
    
    // Parser functions
    parseExerciseLine,
    parsePrescriptionModifiers,
    classifyNote,
    normalizeExerciseName,
    parseToMinutes,
    parseToSeconds,
    extractHebrewWeight,
    validateNoHallucinations,
};

// ============================================
// TEST EXAMPLES (run with: node parser_patterns.js)
// ============================================

if (require.main === module) {
    console.log("=== Parser Patterns Test ===\n");
    
    // Test exercise parsing
    const testLines = [
        "Back Squat: 3x5 @ 100kg",
        "3x10/10 Banded Pulldown",
        "3x8 Dumbbell Row",
        "10 PVC Thoracic Rotation",
        "5 min Bike",
    ];
    
    console.log("Exercise Parsing:");
    for (const line of testLines) {
        console.log(`  "${line}"`);
        console.log(`  →`, JSON.stringify(parseExerciseLine(line), null, 2));
        console.log();
    }
    
    // Test note classification
    const testNotes = [
        "@ RPE 5.5 to 6",
        "Rest 1.5 min",
        "כתף ימין כואבת",
        "10 ק",
        "felt easy",
        "Tempo: 3 sec down",
    ];
    
    console.log("\nNote Classification:");
    for (const note of testNotes) {
        console.log(`  "${note}" → ${classifyNote(note)}`);
    }
    
    // Test prescription modifiers
    console.log("\nPrescription Modifiers:");
    const modText = "@ RPE 5.5 to 6, Rest 1.5 min, Tempo: 3-1-2-0";
    console.log(`  "${modText}"`);
    console.log(`  →`, JSON.stringify(parsePrescriptionModifiers(modText), null, 2));
}
