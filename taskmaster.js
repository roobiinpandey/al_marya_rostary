#!/usr/bin/env node
// Advanced Task Manager for Al Marya Rostery Project
// Usage: node taskmaster.js [command] [options]

const fs = require('fs');
const path = require('path');

const TASKS_FILE = 'PROJECT_TASKS.md';
const DAILY_FILE = 'DAILY_TASKS.md';
const ARCHIVE_DIR = 'task_archive';

class TaskMaster {
    constructor() {
        this.ensureArchiveDir();
    }

    ensureArchiveDir() {
        if (!fs.existsSync(ARCHIVE_DIR)) {
            fs.mkdirSync(ARCHIVE_DIR);
        }
    }

    addTask(taskText, priority = 'medium') {
        const date = new Date().toISOString().split('T')[0];
        const time = new Date().toLocaleTimeString();
        const priorityEmoji = this.getPriorityEmoji(priority);
        
        const taskLine = `- [ ] ${priorityEmoji} ${taskText} (Added: ${time})`;
        
        if (fs.existsSync(DAILY_FILE)) {
            let content = fs.readFileSync(DAILY_FILE, 'utf8');
            
            // Find the TODO section and add the task
            if (content.includes('### **🔴 HIGH PRIORITY**')) {
                const section = priority === 'high' ? '### **🔴 HIGH PRIORITY**' :
                              priority === 'medium' ? '### **🟡 MEDIUM PRIORITY**' :
                              '### **🟢 LOW PRIORITY**';
                
                content = content.replace(
                    section,
                    `${section}\n${taskLine}`
                );
            } else {
                content += `\n${taskLine}`;
            }
            
            fs.writeFileSync(DAILY_FILE, content);
            console.log(`✅ Task added: ${taskText}`);
        } else {
            console.log('❌ DAILY_TASKS.md not found');
        }
    }

    completeTask(taskText) {
        if (fs.existsSync(DAILY_FILE)) {
            let content = fs.readFileSync(DAILY_FILE, 'utf8');
            
            // Find and mark the task as complete
            const searchPattern = new RegExp(`- \\[ \\] (.*)${taskText}(.*)`, 'i');
            const replacePattern = `- [x] $1${taskText}$2`;
            
            if (content.match(searchPattern)) {
                content = content.replace(searchPattern, replacePattern);
                
                // Also add to completed section
                const completedTime = new Date().toLocaleTimeString();
                const completedLine = `- [x] ${taskText} (Completed: ${completedTime})`;
                
                if (content.includes('## ✅ **COMPLETED TODAY**')) {
                    content = content.replace(
                        '## ✅ **COMPLETED TODAY**',
                        `## ✅ **COMPLETED TODAY**\n${completedLine}`
                    );
                }
                
                fs.writeFileSync(DAILY_FILE, content);
                console.log(`✅ Task completed: ${taskText}`);
            } else {
                console.log(`❌ Task not found: ${taskText}`);
            }
        }
    }

    listTasks() {
        if (fs.existsSync(DAILY_FILE)) {
            const content = fs.readFileSync(DAILY_FILE, 'utf8');
            const lines = content.split('\n');
            
            console.log('📋 TODAY\'S TASKS:');
            console.log('==================');
            
            let todoCount = 0;
            let doneCount = 0;
            
            lines.forEach((line, index) => {
                if (line.includes('- [ ]')) {
                    console.log(`${todoCount + 1}. ${line.replace('- [ ]', '⚪')}`);
                    todoCount++;
                } else if (line.includes('- [x]')) {
                    doneCount++;
                }
            });
            
            console.log(`\n📊 Status: ${doneCount} completed, ${todoCount} remaining`);
            
            if (todoCount === 0) {
                console.log('🎉 All tasks completed!');
            }
        }
    }

    showToday() {
        if (fs.existsSync(DAILY_FILE)) {
            const content = fs.readFileSync(DAILY_FILE, 'utf8');
            console.log(content);
        } else {
            console.log('❌ DAILY_TASKS.md not found');
        }
    }

    showProject() {
        if (fs.existsSync(TASKS_FILE)) {
            const content = fs.readFileSync(TASKS_FILE, 'utf8');
            console.log(content);
        } else {
            console.log('❌ PROJECT_TASKS.md not found');
        }
    }

    archiveToday() {
        const date = new Date().toISOString().split('T')[0];
        const archiveFile = path.join(ARCHIVE_DIR, `tasks_${date}.md`);
        
        if (fs.existsSync(DAILY_FILE)) {
            fs.copyFileSync(DAILY_FILE, archiveFile);
            console.log(`✅ Tasks archived to: ${archiveFile}`);
        }
    }

    getPriorityEmoji(priority) {
        switch (priority.toLowerCase()) {
            case 'high': return '🔴';
            case 'medium': return '🟡';
            case 'low': return '🟢';
            default: return '⚪';
        }
    }

    showStats() {
        if (fs.existsSync(DAILY_FILE)) {
            const content = fs.readFileSync(DAILY_FILE, 'utf8');
            const lines = content.split('\n');
            
            const totalTasks = lines.filter(line => line.includes('- [')).length;
            const completedTasks = lines.filter(line => line.includes('- [x]')).length;
            const pendingTasks = lines.filter(line => line.includes('- [ ]')).length;
            
            const progressPercent = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;
            
            console.log('📊 TASK STATISTICS');
            console.log('==================');
            console.log(`Total Tasks: ${totalTasks}`);
            console.log(`Completed: ${completedTasks}`);
            console.log(`Pending: ${pendingTasks}`);
            console.log(`Progress: ${progressPercent}%`);
            
            // Progress bar
            const barLength = 20;
            const filledLength = Math.round((progressPercent / 100) * barLength);
            const progressBar = '█'.repeat(filledLength) + '░'.repeat(barLength - filledLength);
            console.log(`[${progressBar}] ${progressPercent}%`);
        }
    }

    showHelp() {
        console.log('🛠️  TaskMaster - Al Marya Rostery Project Manager');
        console.log('================================================');
        console.log('');
        console.log('Commands:');
        console.log('  add <task> [priority]    - Add a new task (priority: high/medium/low)');
        console.log('  done <task>              - Mark a task as completed');
        console.log('  list                     - Show all pending tasks');
        console.log('  today                    - Show today\'s task file');
        console.log('  project                  - Show project overview');
        console.log('  stats                    - Show task statistics');
        console.log('  archive                  - Archive today\'s tasks');
        console.log('  help                     - Show this help');
        console.log('');
        console.log('Examples:');
        console.log('  node taskmaster.js add "Test checkout flow" high');
        console.log('  node taskmaster.js done "Fix cart issue"');
        console.log('  node taskmaster.js list');
        console.log('  node taskmaster.js stats');
    }
}

// CLI Interface
const taskmaster = new TaskMaster();
const [,, command, ...args] = process.argv;

switch (command) {
    case 'add':
        const task = args.slice(0, -1).join(' ') || args.join(' ');
        const priority = args.length > 1 && ['high', 'medium', 'low'].includes(args[args.length - 1].toLowerCase()) 
                        ? args[args.length - 1] : 'medium';
        const taskText = args.length > 1 && ['high', 'medium', 'low'].includes(args[args.length - 1].toLowerCase())
                        ? args.slice(0, -1).join(' ') : args.join(' ');
        taskmaster.addTask(taskText, priority);
        break;
    
    case 'done':
    case 'complete':
        taskmaster.completeTask(args.join(' '));
        break;
    
    case 'list':
        taskmaster.listTasks();
        break;
    
    case 'today':
        taskmaster.showToday();
        break;
    
    case 'project':
        taskmaster.showProject();
        break;
    
    case 'stats':
    case 'status':
        taskmaster.showStats();
        break;
    
    case 'archive':
        taskmaster.archiveToday();
        break;
    
    case 'help':
    case '--help':
    case '-h':
    default:
        taskmaster.showHelp();
        break;
}
