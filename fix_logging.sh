#!/bin/bash

# Production-Ready Logging Migration Script
# Replaces all print() statements with proper AppLogger calls
# for Al Marya Rostery Flutter app

set -e

echo "🚀 Starting production-ready logging migration..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Base directory
BASE_DIR="/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"
cd "$BASE_DIR"

# Counter for files processed
FILES_PROCESSED=0

# Function to add AppLogger import to a file if not present
add_logger_import() {
    local file=$1
    if ! grep -q "import.*app_logger.dart" "$file"; then
        # Find the last import line
        last_import_line=$(grep -n "^import" "$file" | tail -1 | cut -d: -f1)
        if [ -n "$last_import_line" ]; then
            # Calculate relative path to app_logger.dart
            file_dir=$(dirname "$file")
            rel_path=$(python3 -c "import os.path; print(os.path.relpath('$BASE_DIR/lib/core/utils', '$file_dir'))")
            import_stmt="import '${rel_path}/app_logger.dart';"
            
            # Insert after last import
            sed -i '' "${last_import_line}a\\
$import_stmt
" "$file"
            echo "  ✅ Added AppLogger import to $file"
        fi
    fi
}

# Function to replace print statements in a file
fix_print_statements() {
    local file=$1
    local tag=$2
    
    echo "📝 Processing: $file"
    
    # Add import first
    add_logger_import "$file"
    
    # Replace various print patterns with AppLogger
    sed -i '' \
        -e "s/print('Error /AppLogger.error('/g" \
        -e "s/print('DioException /AppLogger.error('/g" \
        -e "s/print('Failed /AppLogger.error('/g" \
        -e "s/print('Response data:/\/\/ Response data:/g" \
        -e "s/print('Loading /AppLogger.info('/g" \
        -e "s/print('Fetching /AppLogger.network('/g" \
        -e "s/print('Updating /AppLogger.data('/g" \
        -e "s/print('Creating /AppLogger.data('/g" \
        -e "s/print('Deleting /AppLogger.data('/g" \
        -e "s/print('Success/AppLogger.success('/g" \
        -e "s/print('Warning/AppLogger.warning('/g" \
        -e "s/print('Debug/AppLogger.debug('/g" \
        "$file"
    
    ((FILES_PROCESSED++))
    echo "  ✅ Fixed print statements in $(basename $file)"
}

# Fix API Services
echo ""
echo "🔧 Fixing API Services..."
echo "──────────────────────────"
fix_print_statements "lib/core/services/order_api_service.dart" "OrderAPI"
fix_print_statements "lib/core/services/quick_category_api_service.dart" "QuickCategoryAPI"
fix_print_statements "lib/core/services/settings_api_service.dart" "SettingsAPI"
fix_print_statements "lib/core/services/slider_api_service.dart" "SliderAPI"
fix_print_statements "lib/core/services/user_api_service.dart" "UserAPI"

# Fix Admin Features
echo ""
echo "🔧 Fixing Admin Features..."
echo "──────────────────────────"
fix_print_statements "lib/features/admin/presentation/pages/admin_orders_page.dart" "AdminOrders"
fix_print_statements "lib/features/admin/presentation/providers/admin_provider.dart" "AdminProvider"
fix_print_statements "lib/features/admin/presentation/providers/category_provider.dart" "CategoryProvider"
fix_print_statements "lib/features/admin/presentation/providers/slider_provider.dart" "SliderProvider"
fix_print_statements "lib/features/admin/presentation/providers/user_provider.dart" "UserProvider"
fix_print_statements "lib/features/admin/presentation/widgets/admin_sidebar.dart" "AdminSidebar"

# Fix Providers
echo ""
echo "🔧 Fixing Providers..."
echo "──────────────────────────"
fix_print_statements "lib/providers/address_provider.dart" "AddressProvider"
fix_print_statements "lib/providers/gift_set_provider.dart" "GiftSetProvider"

# Fix Services
echo ""
echo "🔧 Fixing Services..."
echo "──────────────────────────"
fix_print_statements "lib/services/address_service.dart" "AddressService"
fix_print_statements "lib/services/location_service.dart" "LocationService"
fix_print_statements "lib/services/reward_service.dart" "RewardService"

# Fix Other Files
echo ""
echo "🔧 Fixing Other Files..."
echo "──────────────────────────"
fix_print_statements "lib/data/models/coffee_product_model.dart" "ProductModel"
fix_print_statements "lib/features/coffee/presentation/pages/product_detail_page.dart" "ProductDetail"
fix_print_statements "lib/features/rewards/presentation/pages/rewards_page.dart" "Rewards"
fix_print_statements "lib/pages/orders_page.dart" "Orders"
fix_print_statements "lib/utils/app_router.dart" "Router"
fix_print_statements "lib/widgets/add_address_sheet.dart" "AddAddress"

# Handle debug widget specially - we might want to keep some logging here
echo ""
echo "🔧 Fixing Debug Widget..."
echo "──────────────────────────"
if [ -f "lib/widgets/common/app_drawer_debug.dart" ]; then
    # For debug widget, replace with debug-level logging
    sed -i '' \
        -e "s/print(/AppLogger.debug(/g" \
        "lib/widgets/common/app_drawer_debug.dart"
    add_logger_import "lib/widgets/common/app_drawer_debug.dart"
    ((FILES_PROCESSED++))
    echo "  ✅ Fixed debug widget"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Migration Complete!"
echo "📊 Files processed: $FILES_PROCESSED"
echo ""
echo "🔍 Verifying no print() statements remain..."
remaining=$(grep -r "print(" lib/ --include="*.dart" | grep -v "debugPrint" | grep -v "AppLogger" | grep -v "//" | wc -l | tr -d ' ')
echo "   Remaining print() calls: $remaining"

if [ "$remaining" -eq "0" ]; then
    echo "✅ All print() statements successfully migrated!"
else
    echo "⚠️  Some print() statements remain - manual review needed"
    echo "   Run: grep -r \"print(\" lib/ --include=\"*.dart\" | grep -v \"debugPrint\" | grep -v \"AppLogger\""
fi

echo ""
echo "📋 Next steps:"
echo "   1. Run: flutter analyze"
echo "   2. Test the app in debug mode"
echo "   3. Verify logging works correctly"
echo "   4. Build production APK"
echo ""
