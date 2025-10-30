#!/bin/bash
# Simple Task Manager for Al Marya Rostery Project
# Usage: ./tasks.sh [command] [task]

TASKS_FILE="PROJECT_TASKS.md"
DAILY_FILE="DAILY_TASKS.md"

case "$1" in
    "add")
        if [ -z "$2" ]; then
            echo "Usage: ./tasks.sh add \"Your task description\""
            exit 1
        fi
        echo "- [ ] $2" >> "$DAILY_FILE"
        echo "✅ Task added: $2"
        ;;
    
    "done")
        if [ -z "$2" ]; then
            echo "Usage: ./tasks.sh done \"Task description\""
            exit 1
        fi
        # Mark task as done by replacing [ ] with [x]
        sed -i '' "s/- \[ \] $2/- [x] $2/" "$DAILY_FILE"
        echo "✅ Task completed: $2"
        ;;
    
    "list")
        echo "📋 TODAY'S TASKS:"
        echo "=================="
        grep "- \[ \]" "$DAILY_FILE" | nl
        echo ""
        echo "✅ COMPLETED TASKS:"
        echo "==================="
        grep "- \[x\]" "$DAILY_FILE" | nl
        ;;
    
    "today")
        echo "📅 TODAY'S PRIORITIES - $(date)"
        echo "================================"
        cat "$DAILY_FILE"
        ;;
    
    "project")
        echo "🎯 PROJECT STATUS"
        echo "=================="
        cat "$TASKS_FILE"
        ;;
    
    "help"|"--help"|"-h"|"")
        echo "🛠️  Simple Task Manager for Al Marya Rostery"
        echo "=============================================="
        echo ""
        echo "Commands:"
        echo "  add \"task\"     - Add a new task"
        echo "  done \"task\"    - Mark a task as completed"
        echo "  list           - Show all tasks"
        echo "  today          - Show today's task file"
        echo "  project        - Show project overview"
        echo "  help           - Show this help"
        echo ""
        echo "Examples:"
        echo "  ./tasks.sh add \"Test checkout flow\""
        echo "  ./tasks.sh done \"Fix cart issue\""
        echo "  ./tasks.sh list"
        ;;
    
    *)
        echo "❌ Unknown command: $1"
        echo "Run './tasks.sh help' for usage information"
        exit 1
        ;;
esac
