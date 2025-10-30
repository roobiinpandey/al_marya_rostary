# TaskMaster Aliases for Al Marya Rostery Project
# Add these to your ~/.zshrc or ~/.bash_profile

# Navigate to project directory
alias cdproject="cd '/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery'"

# Quick TaskMaster commands
alias tm="node taskmaster.js"
alias tadd="node taskmaster.js add"
alias tdone="node taskmaster.js done"
alias tlist="node taskmaster.js list"
alias tstats="node taskmaster.js stats"
alias ttoday="node taskmaster.js today"
alias tproject="node taskmaster.js project"

# Simple bash script commands
alias tasks="./tasks.sh"

# Quick project navigation + task management
alias project="cd '/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery' && node taskmaster.js stats"

# Usage Examples:
# tm add "Fix bug in checkout" high
# tdone "Test feature"
# tlist
# tstats
# project (shows stats immediately)

echo "🛠️ TaskMaster aliases loaded!"
echo "Usage examples:"
echo "  tm add 'Task description' high"
echo "  tdone 'Task description'"
echo "  tlist"
echo "  tstats"
echo "  project (navigate + show stats)"
