#!/usr/bin/env node

/**
 * Scheduled API Health Monitor
 * Runs connectivity checks every 30 minutes using node-cron
 */

const cron = require('node-cron');
const chalk = require('chalk');
const { exec } = require('child_process');
const path = require('path');

// Run API connectivity check
function runCheck() {
  const timestamp = new Date().toLocaleString();
  console.log(chalk.cyan(`\n⏰ [${timestamp}] Starting scheduled API check...\n`));
  
  const scriptPath = path.join(__dirname, 'api_connectivity_check.js');
  
  exec(`node ${scriptPath}`, (error, stdout, stderr) => {
    console.log(stdout);
    
    if (error) {
      console.error(chalk.red(`❌ Check failed with exit code ${error.code}`));
      console.error(stderr);
    } else {
      console.log(chalk.green(`✅ Check completed successfully`));
    }
    
    console.log(chalk.gray(`\n⏰ Next check in 30 minutes...\n`));
  });
}

// Schedule checks every 30 minutes
console.log(chalk.bold.cyan('🕒 API Health Monitor Started'));
console.log(chalk.gray('Running connectivity checks every 30 minutes'));
console.log(chalk.gray('Press Ctrl+C to stop\n'));

// Run immediately on start
runCheck();

// Schedule every 30 minutes: "*/30 * * * *"
cron.schedule('*/30 * * * *', () => {
  runCheck();
});

// Keep the process running
process.on('SIGINT', () => {
  console.log(chalk.yellow('\n\n👋 Stopping health monitor...'));
  process.exit(0);
});
