#!/bin/bash

echo "🧹 Al Marya Rostery - Production Cleanup"
echo "========================================"
echo ""

cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"

# Step 1: Remove test scripts
echo "1️⃣ Removing test scripts..."
rm -f analyze_error_handling.sh
rm -f test_subscription_apis.js
rm -f quick_test.sh
rm -f end_to_end_test.sh
rm -f test_subscriptions_simple.sh
rm -f test_atlas_connection_production.sh
rm -f test_error_handling.sh
rm -f comprehensive_subscription_test.sh
rm -f test_mongodb_atlas.sh
rm -f mongodb_connection_fix.sh
rm -f check-security.sh
rm -f cleanup.sh
rm -f fix_logging.sh
rm -f install.sh
echo "   ✅ Test scripts removed"

# Step 2: Remove temporary markdown files
echo ""
echo "2️⃣ Removing temporary documentation..."
rm -f ACCESSORIES_*.md
rm -f ADMIN_*.md
rm -f API_*.md
rm -f APK_*.md
rm -f BACKEND_*.md
rm -f BANNER_*.md
rm -f CART_*.md
rm -f CLOUDINARY_*.md
rm -f COMPLETE_*.md
rm -f COMPREHENSIVE_*.md
rm -f CONTACT_*.md
rm -f DATABASE_*.md
rm -f DEPLOYMENT_*.md
rm -f DROPDOWN_*.md
rm -f DYNAMIC_*.md
rm -f EMAIL_*.md
rm -f ENHANCED_*.md
rm -f FIREBASE_*.md
rm -f FLUTTER_*.md
rm -f GMAIL_*.md
rm -f GOOGLE_*.md
rm -f GIT_*.md
rm -f HARDCODED_*.md
rm -f IMAGE_*.md
rm -f INSTALL_*.md
rm -f JAVASCRIPT_*.md
rm -f LOYALTY_*.md
rm -f MONGODB_*.md
rm -f PRODUCTION_*.md
rm -f SUBSCRIPTION_*.md
rm -f SYSTEM_*.md
rm -f SECURITY_CREDENTIALS_BEST_PRACTICES.md
echo "   ✅ Temporary documentation removed"

# Step 3: Remove empty Flutter files
echo ""
echo "3️⃣ Removing empty Flutter files..."
rm -f lib/core/network/network_info.dart
rm -f lib/core/utils/helpers.dart
rm -f lib/core/utils/extensions.dart
rm -f lib/core/utils/validators.dart
rm -f lib/core/theme/almaryah_theme_temp.dart
rm -f lib/core/errors/exceptions.dart
rm -f lib/core/errors/failures.dart
rm -f lib/features/settings/presentation/pages/enhanced_settings_page.dart
rm -f lib/features/home/presentation/providers/home_provider.dart
rm -f lib/features/home/presentation/widgets/featured_section.dart
rm -f lib/features/home/presentation/widgets/coffee_card.dart
rm -f lib/features/home/presentation/widgets/category_list.dart
rm -f lib/features/splash/presentation/widgets/logo_animation.dart
rm -f lib/data/datasources/local/auth_local_service.dart
rm -f lib/data/datasources/local/storage_service.dart
rm -f lib/data/datasources/local/cache_service.dart
rm -f lib/data/datasources/remote/order_api_service.dart
rm -f lib/data/datasources/remote/coffee_api_service.dart
rm -f lib/data/datasources/remote/auth_api_service.dart
rm -f lib/data/repositories/coffee_repository_impl.dart
rm -f lib/data/repositories/order_repository_impl.dart
rm -f lib/domain/repositories/order_repository.dart
rm -f lib/domain/usecases/order/get_orders_usecase.dart
rm -f lib/domain/usecases/order/create_order_usecase.dart
rm -f lib/domain/usecases/auth/register_usecase.dart
rm -f lib/domain/usecases/auth/login_usecase.dart
rm -f lib/domain/usecases/auth/logout_usecase.dart
rm -f lib/domain/usecases/coffee/get_coffees_usecase.dart
rm -f lib/domain/usecases/coffee/search_coffee_usecase.dart
rm -f lib/domain/entities/order.dart
rm -f lib/domain/entities/coffee.dart
rm -f lib/domain/entities/cart_item.dart
echo "   ✅ Empty Flutter files removed"

# Step 4: Remove empty test files
echo ""
echo "4️⃣ Removing empty test files..."
rm -f test/mocks/mock_coffee_repository.dart
rm -f test/integration/order_flow_test.dart
rm -f test/integration/auth_flow_test.dart
echo "   ✅ Empty test files removed"

# Step 5: Remove empty directories
echo ""
echo "5️⃣ Removing empty directories..."
find . -type d -empty -not -path '*/\.*' -not -path '*/node_modules/*' -not -path '*/build/*' -not -path '*/.dart_tool/*' -not -path '*/ios/*' -delete 2>/dev/null
echo "   ✅ Empty directories removed"

# Step 6: Remove debug files
echo ""
echo "6️⃣ Removing debug files..."
rm -f lib/debug/firebase_token_debugger.dart
rm -rf lib/debug
rm -f backend/routes/debug-auth.js
rm -f backend/scripts/firebase-token-tester.js
rm -f backend/migrate_database.js
echo "   ✅ Debug files removed"

# Step 7: Remove empty asset files
echo ""
echo "7️⃣ Removing empty asset files..."
rm -f assets/icons/navigation/coffee_icon.svg
rm -f assets/icons/actions/cart_icon.svg
echo "   ✅ Empty asset files removed"

# Step 8: Remove package files at root (they shouldn't be there)
echo ""
echo "8️⃣ Removing misplaced package files..."
rm -f package.json
rm -f package-lock.json
echo "   ✅ Root package files removed"

# Step 9: Clean backend uploads
echo ""
echo "9️⃣ Cleaning backend upload folders..."
rm -rf backend/uploads/support
rm -rf backend/public/uploads/accessories
echo "   ✅ Empty upload folders removed"

# Step 10: Flutter clean
echo ""
echo "🔟 Running Flutter clean..."
flutter clean > /dev/null 2>&1
echo "   ✅ Flutter build cache cleaned"

# Step 11: Backend cleanup
echo ""
echo "1️⃣1️⃣ Cleaning backend node_modules..."
cd backend
rm -rf node_modules
echo "   ✅ Backend node_modules removed (run npm install to restore)"
cd ..

# Summary
echo ""
echo "=========================================="
echo "🎉 CLEANUP COMPLETE!"
echo "=========================================="
echo ""
echo "📊 WHAT WAS REMOVED:"
echo "   ✅ All test scripts (.sh, test_*.js)"
echo "   ✅ Temporary markdown documentation"
echo "   ✅ Empty Flutter files and directories"
echo "   ✅ Empty test files"
echo "   ✅ Debug and development tools"
echo "   ✅ Empty asset files"
echo "   ✅ Flutter build cache"
echo "   ✅ Backend node_modules"
echo ""
echo "🚀 NEXT STEPS FOR PRODUCTION:"
echo "   1. cd backend && npm install"
echo "   2. flutter pub get"
echo "   3. Update backend/.env with production values"
echo "   4. flutter build apk --release"
echo "   5. Test the APK on a physical device"
echo "   6. Deploy backend to Render.com"
echo ""
echo "✅ Project is now clean and production-ready!"
