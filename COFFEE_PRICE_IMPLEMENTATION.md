// COFFEE PRICE DISPLAY IMPLEMENTATION GUIDE
// ==========================================

// This file documents the price display requirements implementation

/*
REQUIREMENTS:
1. HOME PAGE: Show coffee beans prices PER KILOGRAM (1kg price)
2. PRODUCT DETAIL PAGE: Show multiple weight options - 250g, 500g, and 1kg prices

IMPLEMENTATION:
1. CoffeeProductModel.pricePerKgDisplay - shows "XX AED/kg" for home page cards
2. Featured Products uses pricePerKgDisplay instead of priceRangeText  
3. Product Grid Widget uses pricePerKgDisplay instead of price
4. Product Detail Page shows all 3 size options (250g, 500g, 1kg) with individual prices

USAGE EXAMPLES:
- Home Page Card: "45 AED/kg" (base price per kilogram)
- Product Detail: 
  * 250g - 27 AED (60% of base price)
  * 500g - 45 AED (100% of base price)  
  * 1kg - 81 AED (180% of base price)

FILES UPDATED:
✅ /lib/data/models/coffee_product_model.dart - Added pricePerKgDisplay getter
✅ /lib/features/home/presentation/widgets/featured_products.dart - Uses pricePerKgDisplay
✅ /lib/features/home/presentation/widgets/product_grid_widget.dart - Uses pricePerKgDisplay
✅ /lib/features/coffee/presentation/pages/product_detail_page.dart - Shows all 3 sizes

TESTING:
1. Run the app and check home page cards show "XX AED/kg"
2. Click on any coffee product to open detail page
3. Verify detail page shows 3 size options with different prices
4. Verify size selection works and updates total price correctly
*/

// Sample data for testing:
/*
const CoffeeProductModel(
  id: '1', 
  name: 'Ethiopian Yirgacheffe',
  price: 45.0, // This is the base price per kg
  // ... other properties
),

Expected Output:
- Home Page: "45 AED/kg"
- Detail Page: 
  * 250g: 27 AED (45 * 0.6)
  * 500g: 45 AED (45 * 1.0) 
  * 1kg: 81 AED (45 * 1.8)
*/
