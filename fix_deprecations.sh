#!/bin/bash
# Fix all deprecation warnings in the project

echo "🔧 Fixing all deprecation warnings..."
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"

# Fix withOpacity → withValues(alpha:)
echo "Fixing withOpacity deprecations..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.withOpacity(\([^)]*\))/.withValues(alpha: \1)/g' {} \;

echo "✅ All deprecations fixed!"
echo ""
echo "Running flutter analyze to verify..."
flutter analyze
