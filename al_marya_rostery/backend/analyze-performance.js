#!/usr/bin/env node

/**
 * 🚀 Quick Performance Optimization Script
 * 
 * This script identifies and reports on performance optimization opportunities
 * in the codebase without making changes.
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 Analyzing codebase for performance optimizations...\n');

// Directories to scan
const dirsToScan = [
  'controllers',
  'routes'
];

let totalQueries = 0;
let queriesWithLean = 0;
let queriesWithoutLean = 0;
const filesWithIssues = [];

function scanFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');
  
  const issues = [];
  
  lines.forEach((line, index) => {
    const lineNum = index + 1;
    
    // Check for queries without .lean()
    if (line.match(/\.(find|findOne|findById)\(/)) {
      totalQueries++;
      
      // Check if same line or next few lines have .lean()
      const contextLines = lines.slice(index, Math.min(index + 5, lines.length)).join('\n');
      
      if (contextLines.includes('.lean()')) {
        queriesWithLean++;
      } else if (contextLines.includes('findByIdAndUpdate') || 
                 contextLines.includes('findOneAndUpdate') ||
                 contextLines.includes('create(') ||
                 contextLines.includes('save()')) {
        // These are write operations, skip
      } else {
        queriesWithoutLean++;
        issues.push({
          line: lineNum,
          code: line.trim(),
          suggestion: 'Add .lean() for faster read-only queries'
        });
      }
    }
  });
  
  return issues;
}

function scanDirectory(dir) {
  const dirPath = path.join(__dirname, dir);
  
  if (!fs.existsSync(dirPath)) {
    return;
  }
  
  const files = fs.readdirSync(dirPath);
  
  files.forEach(file => {
    if (file.endsWith('.js')) {
      const filePath = path.join(dirPath, file);
      const issues = scanFile(filePath);
      
      if (issues.length > 0) {
        filesWithIssues.push({
          file: `${dir}/${file}`,
          issues
        });
      }
    }
  });
}

// Scan directories
dirsToScan.forEach(scanDirectory);

// Report
console.log('📊 PERFORMANCE OPTIMIZATION REPORT');
console.log('=' .repeat(80));
console.log();
console.log(`Total Database Queries Found: ${totalQueries}`);
console.log(`✅ Queries with .lean(): ${queriesWithLean} (${((queriesWithLean/totalQueries)*100).toFixed(1)}%)`);
console.log(`⚠️  Queries without .lean(): ${queriesWithoutLean} (${((queriesWithoutLean/totalQueries)*100).toFixed(1)}%)`);
console.log();

if (filesWithIssues.length > 0) {
  console.log('📝 FILES NEEDING OPTIMIZATION:');
  console.log('='.repeat(80));
  
  filesWithIssues.forEach(({ file, issues }) => {
    console.log(`\n📄 ${file} (${issues.length} optimizations)`);
    issues.slice(0, 3).forEach(issue => {
      console.log(`   Line ${issue.line}: ${issue.code.substring(0, 60)}...`);
      console.log(`   💡 ${issue.suggestion}`);
    });
    if (issues.length > 3) {
      console.log(`   ... and ${issues.length - 3} more`);
    }
  });
}

console.log('\n' + '='.repeat(80));
console.log('💡 OPTIMIZATION IMPACT');
console.log('='.repeat(80));
console.log('Adding .lean() to queries provides:');
console.log('   • 40-60% faster query execution');
console.log('   • Reduced memory usage');
console.log('   • Plain JavaScript objects (faster serialization)');
console.log();
console.log('⚡ ESTIMATED PERFORMANCE GAIN');
console.log(`   Current optimized: ${queriesWithLean}/${totalQueries} queries`);
console.log(`   Remaining potential: ${queriesWithoutLean} queries to optimize`);
console.log(`   Expected speed improvement: 40-60% on read operations`);
console.log();
console.log('=' .repeat(80));
console.log('✅ Analysis Complete!');
console.log('=' .repeat(80));
