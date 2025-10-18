#!/bin/bash
# Test script for verifying separated admin panel files

echo "🧪 Testing Al Marya Rostery Admin Panel - Separated Files"
echo "========================================================"

# Check if all required files exist
echo "📁 Checking file structure..."

files=(
    "index-new.html"
    "admin.css"
    "js/admin.js"
    "js/dashboard.js"
    "js/products.js"
    "js/orders.js"
    "js/users.js"
    "js/categories.js"
    "js/firebase.js"
    "js/utils.js"
)

missing_files=()

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file - Found"
    else
        echo "❌ $file - Missing"
        missing_files+=("$file")
    fi
done

echo ""

if [ ${#missing_files[@]} -eq 0 ]; then
    echo "🎉 All files are present!"
    echo ""
    echo "📊 File sizes:"
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            size=$(wc -c < "$file")
            echo "   $file: $size bytes"
        fi
    done
    
    echo ""
    echo "🔍 Checking JavaScript syntax..."
    for js_file in js/*.js; do
        if [ -f "$js_file" ]; then
            if node -c "$js_file" 2>/dev/null; then
                echo "✅ $js_file - Syntax OK"
            else
                echo "❌ $js_file - Syntax Error"
            fi
        fi
    done
    
    echo ""
    echo "🌐 Testing HTML structure..."
    if grep -q "admin.css" index-new.html; then
        echo "✅ CSS link found"
    else
        echo "❌ CSS link missing"
    fi
    
    if grep -q "js/admin.js" index-new.html; then
        echo "✅ Main JS link found"
    else
        echo "❌ Main JS link missing"
    fi
    
    echo ""
    echo "🎯 Summary: File separation appears successful!"
    echo "   - Original monolithic file was 6,279+ lines"
    echo "   - Now split into $(echo ${files[@]} | wc -w) organized files"
    echo "   - CSS: Separated into admin.css"
    echo "   - JS: Modularized into $(ls js/*.js | wc -l) specialized modules"
    echo "   - HTML: Clean structure with external references"
    
else
    echo "❌ Missing files: ${missing_files[*]}"
    echo "Please ensure all files are created properly."
fi

echo ""
echo "✨ Test complete!"
