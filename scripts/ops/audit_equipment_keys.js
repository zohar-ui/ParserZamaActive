#!/usr/bin/env node
/**
 * Audit equipment_key assignments in golden set JSON files
 * Cross-reference with original text files to verify equipment mentions
 */

const fs = require('fs');
const path = require('path');

const GOLDEN_SET_DIR = path.join(__dirname, '../data/golden_set');

// Equipment keywords to search for in text
const EQUIPMENT_PATTERNS = {
  bike: /\b(bike|assault\s*bike|c2\s*bike|air\s*bike)\b/i,
  rowing_machine: /\b(row|rowing|erg|c2|concept2)\b/i,
  treadmill: /\btreadmill\b/i,
  barbell: /\b(barbell|bar|@\s*\d+kg|bb)\b/i,
  dumbbell: /\b(dumbbell|db|dumbell)\b/i,
  kettlebell: /\b(kettlebell|kb)\b/i,
  cable_machine: /\bcable\b/i,
  resistance_band: /\b(band|banded|mini-band|miniband)\b/i,
  pvc_pipe: /\bpvc\b/i,
  foam_roller: /\bfoam\s*roll/i,
  lacrosse_ball: /\blacrosse\s*ball\b/i,
  assault_bike: /\bassault\s*bike\b/i,
  // Bodyweight needs special handling - default for no equipment
  bodyweight: null
};

function findJsonFiles() {
  return fs.readdirSync(GOLDEN_SET_DIR)
    .filter(f => f.endsWith('.json'))
    .sort();
}

function readTextFile(jsonFile) {
  const txtFile = jsonFile.replace('.json', '.txt');
  const txtPath = path.join(GOLDEN_SET_DIR, txtFile);
  if (fs.existsSync(txtPath)) {
    return fs.readFileSync(txtPath, 'utf8').toLowerCase();
  }
  return null;
}

function extractEquipmentKeys(obj, results = []) {
  if (typeof obj !== 'object' || obj === null) return results;
  
  if (obj.equipment_key) {
    results.push({
      equipment_key: obj.equipment_key,
      exercise_name: obj.exercise_name || null,
      context: obj
    });
  }
  
  for (const key in obj) {
    if (Array.isArray(obj[key])) {
      obj[key].forEach(item => extractEquipmentKeys(item, results));
    } else if (typeof obj[key] === 'object') {
      extractEquipmentKeys(obj[key], results);
    }
  }
  
  return results;
}

function verifyEquipmentKey(equipmentKey, exerciseName, textContent) {
  // Bodyweight is always OK
  if (equipmentKey === 'bodyweight') {
    return { valid: true, reason: 'Bodyweight exercises are default' };
  }
  
  // If no text file, cannot verify
  if (!textContent) {
    return { valid: true, reason: 'No text file to verify', warning: true };
  }
  
  const pattern = EQUIPMENT_PATTERNS[equipmentKey];
  if (!pattern) {
    return { valid: false, reason: `Unknown equipment key: ${equipmentKey}` };
  }
  
  // Check if equipment is mentioned in text
  if (pattern.test(textContent)) {
    return { valid: true, reason: 'Equipment explicitly mentioned in text' };
  }
  
  // Special case: check if exercise name contains equipment
  if (exerciseName) {
    const lowerExercise = exerciseName.toLowerCase();
    if (pattern.test(lowerExercise)) {
      return { valid: true, reason: 'Equipment in exercise name' };
    }
  }
  
  return { valid: false, reason: 'Equipment NOT found in original text' };
}

function auditFile(jsonFile) {
  const jsonPath = path.join(GOLDEN_SET_DIR, jsonFile);
  const jsonContent = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  const textContent = readTextFile(jsonFile);
  
  const equipmentKeys = extractEquipmentKeys(jsonContent);
  const issues = [];
  const valid = [];
  
  equipmentKeys.forEach(item => {
    const verification = verifyEquipmentKey(
      item.equipment_key,
      item.exercise_name,
      textContent
    );
    
    if (!verification.valid || verification.warning) {
      issues.push({
        exercise: item.exercise_name,
        equipment_key: item.equipment_key,
        reason: verification.reason,
        warning: verification.warning || false
      });
    } else {
      valid.push({
        exercise: item.exercise_name,
        equipment_key: item.equipment_key
      });
    }
  });
  
  return {
    file: jsonFile,
    total_equipment_keys: equipmentKeys.length,
    valid_count: valid.length,
    issue_count: issues.length,
    issues,
    valid
  };
}

function main() {
  console.log('='.repeat(80));
  console.log('EQUIPMENT_KEY AUDIT REPORT');
  console.log('Golden Set JSON Files vs Original Text Files');
  console.log('='.repeat(80));
  console.log('');
  
  const jsonFiles = findJsonFiles();
  const allResults = [];
  let totalKeys = 0;
  let totalValid = 0;
  let totalIssues = 0;
  
  jsonFiles.forEach(file => {
    const result = auditFile(file);
    allResults.push(result);
    totalKeys += result.total_equipment_keys;
    totalValid += result.valid_count;
    totalIssues += result.issue_count;
    
    console.log(`\n### ${result.file}`);
    console.log(`Total equipment_keys: ${result.total_equipment_keys}`);
    console.log(`Valid: ${result.valid_count} | Issues: ${result.issue_count}`);
    
    if (result.issues.length > 0) {
      console.log('\n⚠️  ISSUES FOUND:');
      result.issues.forEach(issue => {
        const icon = issue.warning ? '⚡' : '❌';
        console.log(`  ${icon} ${issue.exercise || '(no exercise name)'}`);
        console.log(`     equipment_key: "${issue.equipment_key}"`);
        console.log(`     reason: ${issue.reason}`);
      });
    }
    
    // Show valid ones
    if (result.valid_count > 0 && result.valid_count <= 10) {
      console.log('\n✅ Valid equipment assignments:');
      result.valid.forEach(v => {
        console.log(`  • ${v.exercise || '(no name)'}: ${v.equipment_key}`);
      });
    } else if (result.valid_count > 10) {
      console.log(`\n✅ ${result.valid_count} valid equipment assignments`);
    }
  });
  
  console.log('\n' + '='.repeat(80));
  console.log('SUMMARY');
  console.log('='.repeat(80));
  console.log(`Files audited: ${jsonFiles.length}`);
  console.log(`Total equipment_key fields: ${totalKeys}`);
  console.log(`Valid: ${totalValid} (${(totalValid/totalKeys*100).toFixed(1)}%)`);
  console.log(`Issues: ${totalIssues} (${(totalIssues/totalKeys*100).toFixed(1)}%)`);
  console.log('');
  
  // Create detailed report
  const reportPath = path.join(GOLDEN_SET_DIR, 'EQUIPMENT_KEY_AUDIT_REPORT.md');
  let report = `# Equipment Key Audit Report\n\n`;
  report += `**Date:** ${new Date().toISOString().split('T')[0]}\n`;
  report += `**Files Audited:** ${jsonFiles.length}\n`;
  report += `**Total Equipment Keys:** ${totalKeys}\n`;
  report += `**Valid:** ${totalValid} (${(totalValid/totalKeys*100).toFixed(1)}%)\n`;
  report += `**Issues:** ${totalIssues} (${(totalIssues/totalKeys*100).toFixed(1)}%)\n\n`;
  report += `---\n\n`;
  
  allResults.forEach(result => {
    report += `## ${result.file}\n\n`;
    report += `- Total: ${result.total_equipment_keys}\n`;
    report += `- Valid: ${result.valid_count}\n`;
    report += `- Issues: ${result.issue_count}\n\n`;
    
    if (result.issues.length > 0) {
      report += `### Issues\n\n`;
      result.issues.forEach(issue => {
        report += `- **${issue.exercise || '(no exercise name)'}**\n`;
        report += `  - equipment_key: \`${issue.equipment_key}\`\n`;
        report += `  - reason: ${issue.reason}\n\n`;
      });
    }
    
    report += `\n---\n\n`;
  });
  
  fs.writeFileSync(reportPath, report);
  console.log(`Detailed report saved to: ${reportPath}`);
  console.log('');
}

main();
