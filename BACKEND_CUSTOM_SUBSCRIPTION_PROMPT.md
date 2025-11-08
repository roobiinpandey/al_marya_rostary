# Backend Copilot Prompt: Custom Coffee Subscription Feature

## Context
You are working on an Al Marya Coffee subscription system built with Node.js, Express, MongoDB, and Stripe. The system currently supports subscription plans loaded from the database, but we need to enhance it to allow users to build personalized coffee subscriptions by selecting specific coffee products.

## Current Implementation

### Existing Files
- `backend/routes/subscriptions.js` - Subscription routes
- `backend/models/Subscription.js` - Subscription, SubscriptionPlan, SubscriptionDelivery models
- `backend/controllers/subscriptionController.js` - Subscription business logic (if exists)

### Current Subscription Plan Schema
```javascript
{
  planId: String,
  name: String,
  description: String,
  frequency: String, // 'weekly', 'monthly', etc.
  discountPercentage: Number,
  minCommitmentMonths: Number,
  benefits: [String],
  isActive: Boolean,
  sortOrder: Number
}
```

### Current API Endpoints
- `GET /api/subscriptions/plans` - Get all subscription plans
- `POST /api/subscriptions` - Create new subscription
- `GET /api/subscriptions` - Get user subscriptions
- `PATCH /api/subscriptions/:id` - Update subscription
- `POST /api/subscriptions/:id/pause` - Pause subscription
- `POST /api/subscriptions/:id/resume` - Resume subscription
- `POST /api/subscriptions/:id/cancel` - Cancel subscription

## Required Enhancement

### Task: Extend Subscription System for Custom Coffee Selection

Users should be able to:
1. Select a subscription plan (frequency, discount, etc.)
2. Choose multiple coffee products from the catalog
3. Create a subscription with their custom coffee selection
4. View their selected products in subscription details

### Backend Changes Required

#### 1. Update Subscription Model Schema

File: `backend/models/Subscription.js`

Add to the `Subscription` schema:
```javascript
selectedProducts: [{
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Coffee',
    required: true
  },
  productName: String,  // Cache for quick display
  productImage: String, // Cache product image
  quantity: {
    type: String,
    default: '250g'  // Default size
  },
  priceAtSelection: Number, // Lock price at time of subscription
  addedAt: {
    type: Date,
    default: Date.now
  }
}],
totalPrice: {
  type: Number,
  required: true,
  default: 0
},
basePlanPrice: Number, // Store base plan price separately
```

**Important**: Keep all existing fields intact. Only ADD new fields.

#### 2. Extend POST /api/subscriptions Endpoint

File: `backend/routes/subscriptions.js`

Update the subscription creation logic to:

**Accept new request body format**:
```javascript
{
  userId: String,           // Firebase UID
  planId: String,           // Selected subscription plan ID
  selectedProducts: [       // NEW: Array of selected coffee products
    {
      id: String,           // Product MongoDB _id
      name: String,         // Product name (for display)
      quantity: String      // Size/quantity (e.g., "250g", "500g")
    }
  ],
  totalPrice: Number,       // NEW: Calculated total price
  deliveryAddress: Object,  // Existing field
  preferences: String,      // Existing field (optional)
  customization: Object     // Existing field (optional)
}
```

**Implementation Steps**:

1. **Validate Input**:
```javascript
// Validate selectedProducts array
if (!Array.isArray(selectedProducts) || selectedProducts.length === 0) {
  return res.status(400).json({
    success: false,
    message: 'At least one coffee product must be selected'
  });
}

// Validate each product exists in database
const productIds = selectedProducts.map(p => p.id);
const coffeeProducts = await Coffee.find({ _id: { $in: productIds } });

if (coffeeProducts.length !== selectedProducts.length) {
  return res.status(400).json({
    success: false,
    message: 'One or more selected products are invalid'
  });
}
```

2. **Fetch Plan Details**:
```javascript
const plan = await SubscriptionPlan.findOne({ planId: planId });
if (!plan) {
  return res.status(404).json({
    success: false,
    message: 'Subscription plan not found'
  });
}
```

3. **Build Product Details Array**:
```javascript
const productDetails = selectedProducts.map(selected => {
  const product = coffeeProducts.find(p => p._id.toString() === selected.id);
  return {
    productId: product._id,
    productName: product.name.en || product.name || selected.name,
    productImage: product.image || product.imageUrl || '',
    quantity: selected.quantity || '250g',
    priceAtSelection: product.price || 0,
    addedAt: new Date()
  };
});
```

4. **Calculate Pricing**:
```javascript
// Calculate base plan discount
const basePlanPrice = 0; // Or set a base subscription fee if applicable

// Sum up all product prices
const productsTotal = productDetails.reduce((sum, item) => {
  return sum + (item.priceAtSelection || 0);
}, 0);

// Apply plan discount
const discountAmount = (productsTotal * plan.discountPercentage) / 100;
const finalPrice = basePlanPrice + productsTotal - discountAmount;

// Verify client-sent total matches server calculation (security)
const priceDifference = Math.abs(finalPrice - totalPrice);
if (priceDifference > 0.01) {
  console.warn(`Price mismatch: Client sent ${totalPrice}, Server calculated ${finalPrice}`);
  // You can either reject or use server-calculated price
}
```

5. **Create Subscription Document**:
```javascript
const subscription = new Subscription({
  userId: userId,
  planId: plan._id,
  planName: plan.name,
  frequency: plan.frequency,
  selectedProducts: productDetails,
  basePlanPrice: basePlanPrice,
  totalPrice: finalPrice,
  discountPercentage: plan.discountPercentage,
  deliveryAddress: deliveryAddress,
  preferences: preferences,
  customization: customization,
  status: 'active',
  startDate: new Date(),
  nextDelivery: calculateNextDelivery(plan.frequency),
  // ... other existing fields
});

await subscription.save();
```

6. **Return Response**:
```javascript
res.status(201).json({
  success: true,
  message: 'Custom subscription created successfully',
  data: {
    subscription: subscription.toObject(),
    selectedProductsCount: productDetails.length
  }
});
```

#### 3. Update GET /api/subscriptions/:userId

Ensure this endpoint returns `selectedProducts` when fetching user subscriptions:

```javascript
router.get('/', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    
    const subscriptions = await Subscription.find({ userId })
      .populate('selectedProducts.productId', 'name image price stock')
      .sort({ createdAt: -1 })
      .lean();
    
    res.json({
      success: true,
      data: {
        subscriptions,
        total: subscriptions.length
      }
    });
  } catch (error) {
    console.error('Error fetching user subscriptions:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch subscriptions',
      error: error.message
    });
  }
});
```

#### 4. Add GET /api/subscriptions/:id/products Endpoint

Create new endpoint to fetch product details for a specific subscription:

```javascript
router.get('/:id/products', verifyFirebaseToken, async (req, res) => {
  try {
    const subscription = await Subscription.findById(req.params.id)
      .populate('selectedProducts.productId', 'name image price stock origin roastLevel')
      .lean();
    
    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Subscription not found'
      });
    }
    
    // Verify user owns this subscription
    if (subscription.userId !== req.user.uid) {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized access to subscription'
      });
    }
    
    res.json({
      success: true,
      data: {
        products: subscription.selectedProducts,
        totalPrice: subscription.totalPrice,
        planName: subscription.planName
      }
    });
  } catch (error) {
    console.error('Error fetching subscription products:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch subscription products',
      error: error.message
    });
  }
});
```

#### 5. Update PATCH /api/subscriptions/:id

Allow users to modify their product selection:

```javascript
router.patch('/:id', verifyFirebaseToken, async (req, res) => {
  try {
    const { selectedProducts, totalPrice } = req.body;
    
    const subscription = await Subscription.findById(req.params.id);
    
    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'Subscription not found'
      });
    }
    
    // Verify ownership
    if (subscription.userId !== req.user.uid) {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized'
      });
    }
    
    // If updating products
    if (selectedProducts) {
      // Validate and process new product selection (same logic as create)
      const productIds = selectedProducts.map(p => p.id);
      const coffeeProducts = await Coffee.find({ _id: { $in: productIds } });
      
      const productDetails = selectedProducts.map(selected => {
        const product = coffeeProducts.find(p => p._id.toString() === selected.id);
        return {
          productId: product._id,
          productName: product.name.en || product.name,
          productImage: product.image || '',
          quantity: selected.quantity || '250g',
          priceAtSelection: product.price || 0,
          addedAt: new Date()
        };
      });
      
      subscription.selectedProducts = productDetails;
      subscription.totalPrice = totalPrice;
    }
    
    await subscription.save();
    
    res.json({
      success: true,
      message: 'Subscription updated successfully',
      data: subscription
    });
  } catch (error) {
    console.error('Error updating subscription:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update subscription',
      error: error.message
    });
  }
});
```

### Helper Function: Calculate Next Delivery

```javascript
function calculateNextDelivery(frequency) {
  const now = new Date();
  const next = new Date(now);
  
  switch (frequency.toLowerCase()) {
    case 'weekly':
      next.setDate(next.getDate() + 7);
      break;
    case 'bi-weekly':
      next.setDate(next.getDate() + 14);
      break;
    case 'monthly':
      next.setMonth(next.getMonth() + 1);
      break;
    case 'quarterly':
      next.setMonth(next.getMonth() + 3);
      break;
    default:
      next.setMonth(next.getMonth() + 1); // Default to monthly
  }
  
  return next;
}
```

## Testing Checklist

After implementing changes, test:

1. ✅ Create subscription with multiple products
2. ✅ Fetch user subscriptions - verify selectedProducts is included
3. ✅ Update subscription products
4. ✅ Price calculation matches plan discount
5. ✅ Product validation (invalid product IDs rejected)
6. ✅ Authorization (users can only access their subscriptions)
7. ✅ Existing subscriptions still work (backward compatibility)

## Example API Calls

### Create Custom Subscription
```bash
POST /api/subscriptions
Authorization: Bearer <firebase-token>
Content-Type: application/json

{
  "userId": "firebase-uid-123",
  "planId": "monthly-premium",
  "selectedProducts": [
    {
      "id": "67891011121314151617abcd",
      "name": "Ethiopian Yirgacheffe",
      "quantity": "250g"
    },
    {
      "id": "67891011121314151617abce",
      "name": "Colombian Supremo",
      "quantity": "500g"
    }
  ],
  "totalPrice": 189.00,
  "deliveryAddress": {
    "name": "Ahmed Ali",
    "phone": "+971501234567",
    "street": "Al Wasl Road",
    "city": "Dubai",
    "emirate": "Dubai",
    "area": "Jumeirah"
  }
}
```

### Response
```json
{
  "success": true,
  "message": "Custom subscription created successfully",
  "data": {
    "subscription": {
      "_id": "subscription-id-123",
      "userId": "firebase-uid-123",
      "planId": "monthly-premium",
      "planName": "Monthly Premium Plan",
      "selectedProducts": [
        {
          "productId": "67891011121314151617abcd",
          "productName": "Ethiopian Yirgacheffe",
          "productImage": "https://...",
          "quantity": "250g",
          "priceAtSelection": 85.00
        },
        {
          "productId": "67891011121314151617abce",
          "productName": "Colombian Supremo",
          "productImage": "https://...",
          "quantity": "500g",
          "priceAtSelection": 120.00
        }
      ],
      "totalPrice": 189.00,
      "basePlanPrice": 0,
      "discountPercentage": 10,
      "status": "active",
      "startDate": "2025-11-08T10:30:00Z",
      "nextDelivery": "2025-12-08T10:30:00Z"
    },
    "selectedProductsCount": 2
  }
}
```

## Important Notes

1. **Backward Compatibility**: Existing subscriptions without `selectedProducts` should continue working
2. **Price Locking**: Store `priceAtSelection` to lock product prices when subscription is created
3. **Security**: Always verify product IDs exist and user owns the subscription
4. **Stripe Integration**: If using Stripe, update subscription creation to include product line items
5. **Delivery Logic**: Ensure delivery scheduling accounts for multiple products
6. **Stock Management**: Consider checking product stock before allowing subscription creation

## Migration Script (Optional)

If you need to migrate existing subscriptions:

```javascript
// backend/scripts/migrate-subscriptions.js
const { Subscription } = require('../models/Subscription');

async function migrateSubscriptions() {
  const subscriptions = await Subscription.find({ selectedProducts: { $exists: false } });
  
  for (const sub of subscriptions) {
    sub.selectedProducts = [];
    sub.basePlanPrice = 0;
    // totalPrice should already exist
    await sub.save();
  }
  
  console.log(`Migrated ${subscriptions.length} subscriptions`);
}
```

---

**End of Backend Copilot Prompt**

This prompt provides all the context and code examples needed to update the backend subscription system to support custom coffee product selection while maintaining backward compatibility with existing subscriptions.
