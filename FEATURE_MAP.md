# Al Marya Rostery - Feature Module Map

## 📍 Visual Feature Map

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AL MARYA ROSTERY APP                                 │
│                          (Flutter + Firebase)                                │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                    ┌────────────────┴───────────────┐
                    │                                │
            ┌───────▼──────┐                 ┌──────▼────────┐
            │   SPLASH     │                 │     AUTH      │
            │   SCREEN     │────────────────▶│   (Firebase)  │
            └──────────────┘                 └───────────────┘
                    │                                │
                    │                        ┌───────┴────────┐
                    │                        │                │
                    │                   ┌────▼────┐     ┌────▼─────┐
                    │                   │  Login  │     │ Register │
                    │                   └─────────┘     └──────────┘
                    │                        │                │
                    └────────────────────────┴────────────────┘
                                             │
                    ┌────────────────────────▼─────────────────────────┐
                    │         MAIN NAVIGATION (Bottom Nav)             │
                    │    [Home] [Products] [Cart] [Rewards] [Profile] │
                    └──────────────────────────────────────────────────┘
                                             │
       ┌─────────────┬───────────────┬──────┴───────┬──────────────┬──────────┐
       │             │               │              │              │          │
  ┌────▼────┐  ┌────▼────┐    ┌─────▼─────┐  ┌─────▼─────┐  ┌────▼─────┐   │
  │  HOME   │  │ COFFEE  │    │   CART    │  │  REWARDS  │  │ PROFILE  │   │
  │  PAGE   │  │PRODUCTS │    │   PAGE    │  │   PAGE    │  │   PAGE   │   │
  └────┬────┘  └────┬────┘    └─────┬─────┘  └─────┬─────┘  └────┬─────┘   │
       │            │               │              │              │          │
       ├────────────┼───────────────┼──────────────┼──────────────┼──────────┘
       │            │               │              │              │
┌──────▼──────┐ ┌───▼────────┐ ┌───▼──────┐  ┌────▼────┐   ┌────▼────┐
│  SEARCH     │ │ CATEGORIES │ │ CHECKOUT │  │ ORDERS  │   │ ACCOUNT │
│  FEATURE    │ │            │ │  FLOW    │  │ HISTORY │   │ SETTINGS│
└─────────────┘ └────┬───────┘ └────┬─────┘  └─────────┘   └─────────┘
                     │              │
              ┌──────┴───────┐      │
              │              │      │
      ┌───────▼────┐  ┌──────▼──────▼────┐
      │ ACCESSORIES│  │    SUBSCRIPTIONS  │
      │  (Brewing  │  │  (Coffee Delivery)│
      │ Equipment) │  └───────────────────┘
      └────────────┘          │
              │               │
      ┌───────▼───────┐   ┌───▼─────────┐
      │ BREWING       │   │   GIFTS     │
      │ METHODS       │   │  (Gift Sets)│
      │ (Guides)      │   └─────────────┘
      └───────────────┘
              │
      ┌───────▼───────┐
      │  WISHLIST     │
      │  (Favorites)  │
      └───────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                            ADMIN FEATURES                                    │
│                         (Separate Admin Panel)                               │
└─────────────────────────────────────────────────────────────────────────────┘
       │
       ├─── Product Management (Add/Edit/Delete Products)
       ├─── Category Management
       ├─── Order Management (View/Update Orders)
       ├─── User Management
       ├─── Banner/Slider Management
       └─── Analytics Dashboard
```

---

## 🏗️ Feature Module Breakdown

### 1. 🎨 **SPLASH** (`features/splash/`)
**Purpose**: App initialization and loading screen

**Components**:
- Splash screen with logo animation
- Firebase initialization
- Check authentication state
- Load initial app data

**Navigation**:
```
Splash → Auth (if not logged in)
Splash → Home (if logged in)
```

---

### 2. 🔐 **AUTH** (`features/auth/`)
**Purpose**: User authentication and authorization

**Sub-features**:
- **Login** (`login_page.dart`)
  - Email/password login
  - Google Sign-In
  - Apple Sign-In (iOS)
  - "Forgot Password" link
  
- **Register** (`register_page.dart`)
  - Email/password signup
  - Email verification required
  - Terms & conditions acceptance
  
- **Forgot Password** (`forgot_password_page.dart`)
  - Password reset via email
  - Email verification
  
- **Email Verification** (`email_verification_page.dart`)
  - Verify email before accessing app
  - Resend verification link

**Providers**:
- `AuthProvider` - Manages auth state

**Services**:
- Firebase Authentication

---

### 3. 🏠 **HOME** (`features/home/`)
**Purpose**: Main landing page after login

**Components**:
- Hero banner/slider
- Featured products carousel
- Category grid
- New arrivals section
- Best sellers section
- Promotions/deals

**Navigation to**:
- Product details
- Category pages
- Search
- Cart

---

### 4. ☕ **COFFEE** (`features/coffee/`)
**Purpose**: Coffee product catalog

**Sub-features**:
- Product listing with filters
- Product detail page
- Product reviews
- Product variants (size, grind type)
- Add to cart
- Add to wishlist

**Data Models**:
- `Product` - Product entity
- `Category` - Product category
- `ProductVariant` - Size/grind options

**Providers**:
- `ProductProvider` - Product state management
- `CategoryProvider` - Category management

---

### 5. 🔍 **SEARCH** (`features/search/`)
**Purpose**: Product search functionality

**Components**:
- Search bar with autocomplete
- Search filters (category, price, rating)
- Search history
- Popular searches
- Search results grid

**Features**:
- Real-time search
- Filter by category
- Sort by price/rating
- Clear search history

---

### 6. 🛒 **CART** (`features/cart/`)
**Purpose**: Shopping cart management

**Components**:
- Cart item list
- Quantity adjustment (+/-)
- Remove items
- Cart summary (subtotal, tax, total)
- Empty cart state with "Continue Shopping" button
- Promo code input

**Navigation**:
- Continue to Checkout
- Continue Shopping (returns to Home tab)

**Providers**:
- `CartProvider` - Cart state management

**Recent Fix**: ✅ Fixed crash when clicking "Continue Shopping" with empty cart

---

### 7. 💳 **CHECKOUT** (`features/checkout/`)
**Purpose**: Complete purchase flow

**Multi-step Process**:
1. **Delivery Address**
   - Add/select delivery address
   - Address validation
   
2. **Delivery Schedule**
   - Select delivery date/time
   - Express delivery option
   
3. **Rewards & Payment**
   - View available reward points
   - Apply reward points discount
   - Select payment method (Cash on Delivery)
   
4. **Order Review**
   - Review order details
   - Confirm and place order

**Data Models**:
- `DeliveryAddress`
- `DeliverySchedule`
- `Order`

**Providers**:
- `CheckoutProvider`
- `RewardProvider` (for points calculation)

**File**: `checkout_page.dart` (1,006 lines - comprehensive)

---

### 8. 🎁 **REWARDS** (`features/rewards/`)
**Purpose**: Loyalty rewards program

**Components**:
- Points balance display
- Points history
- Rewards catalog
- Redeem rewards
- Earn points info
- Tier/level system (if applicable)

**Point System**:
- Earn points on purchases
- Redeem points for discounts
- Track points expiration

**Providers**:
- `RewardProvider`

**Integration**: Connected to Checkout for applying discounts

---

### 9. 📦 **ORDERS** (`features/orders/`)
**Purpose**: Order history and tracking

**Components**:
- Order list (all orders)
- Order detail page
- Order status tracking
- Reorder functionality
- Order cancellation (if allowed)
- Invoice download

**Order Statuses**:
- Pending
- Processing
- Out for Delivery
- Delivered
- Cancelled

---

### 10. 👤 **PROFILE** (`features/profile/`)
**Purpose**: User profile management

**Components**:
- Profile information display
- Edit profile (name, email, phone)
- Profile picture upload
- Delivery addresses management
- Preferences

**Navigation to**:
- Account settings
- Orders
- Wishlist
- Help & Support

---

### 11. ⚙️ **ACCOUNT** (`features/account/`)
**Purpose**: Account settings and preferences

**Components**:
- Change password
- Notification settings
- Language preferences
- Theme (light/dark mode)
- Delete account
- Logout

---

### 12. ❤️ **WISHLIST** (`features/wishlist/`)
**Purpose**: Save favorite products

**Components**:
- Wishlist item grid
- Remove from wishlist
- Add to cart from wishlist
- Empty wishlist state

**Providers**:
- `WishlistProvider`

---

### 13. 🎁 **GIFTS** (`features/gifts/`)
**Purpose**: Gift sets and gift cards

**Components**:
- Gift set catalog
- Gift card purchase
- Custom gift messages
- Gift wrapping options

---

### 14. 🔄 **SUBSCRIPTION** (`features/subscription/`)
**Purpose**: Coffee subscription service

**Components**:
- Subscription plans (weekly, monthly)
- Subscription management
- Pause/resume subscription
- Change delivery frequency
- Subscription billing

---

### 15. 📱 **SUBSCRIPTIONS** (`features/subscriptions/`)
**Status**: 🔄 **Review needed** (possible duplicate with `subscription/`)

**Action Required**: Verify if this is:
- A duplicate of `subscription/`
- A different feature (e.g., newsletter subscriptions)
- Should be merged or removed

---

### 16. ☕🔧 **ACCESSORIES** (`features/accessories/`)
**Purpose**: Brewing equipment catalog

**Components**:
- Accessories catalog (grinders, brewers, filters)
- Product details
- Add to cart
- Compatibility info

**Categories**:
- Coffee grinders
- Brewing equipment
- Storage containers
- Filters and accessories

---

### 17. 📖 **BREWING METHODS** (`features/brewing_methods/`)
**Purpose**: Coffee brewing guides and tutorials

**Components**:
- Brewing method list
- Detailed brewing guides
- Step-by-step instructions
- Video tutorials (if available)
- Equipment recommendations

**Methods**:
- Espresso
- French Press
- Pour Over
- Cold Brew
- AeroPress
- Turkish Coffee

---

### 18. 🧭 **NAVIGATION** (`features/navigation/`)
**Purpose**: App navigation structure

**Components**:
- Bottom navigation bar
- Navigation drawer (if applicable)
- Route management
- Deep linking

**Bottom Tabs**:
```
[🏠 Home] [☕ Products] [🛒 Cart] [🎁 Rewards] [👤 Profile]
   Index 0    Index 1      Index 2    Index 3      Index 4
```

**Key File**: `main_navigation_page.dart`

---

### 19. 🔧 **ADMIN** (`features/admin/`)
**Purpose**: Admin panel for managing app content

**Sub-features**:
- **Product Management**
  - Add new products
  - Edit product details
  - Delete products
  - Manage inventory
  
- **Category Management**
  - Create categories
  - Edit categories
  - Reorder categories
  
- **Order Management**
  - View all orders
  - Update order status
  - Process refunds
  
- **User Management**
  - View user list
  - Block/unblock users
  - View user activity
  
- **Banner Management**
  - Upload banners/sliders
  - Schedule banners
  - Banner analytics
  
- **Analytics**
  - Sales reports
  - User statistics
  - Product performance

**Access**: Admin role required

---

### 20. 🌐 **COMMON** (`features/common/`)
**Purpose**: Shared feature components

**Components**:
- About page
- Contact us
- Help & Support
- FAQ
- Privacy policy
- Terms & conditions
- Shipping policy
- Return policy

---

## 🔄 Feature Dependencies

### Primary User Flow
```
Splash → Auth → Home → Products → Cart → Checkout → Orders
                  ↓
                Search → Product Detail → Cart
                  ↓
              Rewards → Apply to Checkout
                  ↓
              Profile → Account Settings
```

### Supporting Features
```
Wishlist ←→ Products
Subscription ←→ Products
Gifts ←→ Products
Accessories ←→ Products
Brewing Methods ←→ Products (recommendations)
```

---

## 📊 Feature Complexity Matrix

| Feature | Complexity | Lines of Code | Providers | API Calls |
|---------|-----------|---------------|-----------|-----------|
| Auth | High | ~800 | 1 | 3 |
| Home | Medium | ~500 | 2 | 4 |
| Coffee | High | ~1200 | 2 | 6 |
| Cart | Medium | ~600 | 1 | 3 |
| Checkout | Very High | ~1000 | 2 | 5 |
| Rewards | Medium | ~400 | 1 | 3 |
| Orders | Medium | ~700 | 1 | 4 |
| Admin | Very High | ~1500 | 3 | 10+ |
| Search | Medium | ~400 | 1 | 2 |
| Profile | Low | ~300 | 1 | 2 |

---

## 🎯 Feature Status

### ✅ Production Ready
- Splash
- Auth (login, register, forgot password)
- Home
- Coffee (products catalog)
- Cart (✅ recently fixed empty state crash)
- Checkout (✅ comprehensive 1,006-line implementation)
- Rewards (integrated with checkout)
- Orders
- Profile
- Account
- Search
- Wishlist
- Gifts
- Accessories
- Brewing Methods
- Navigation
- Admin
- Common

### 🔄 Needs Review
- **Subscription** - Verify functionality
- **Subscriptions** - Possible duplicate?

---

## 📱 User Journey Examples

### First-Time User
```
1. App Launch → Splash Screen
2. No auth → Login/Register Page
3. Register → Email Verification
4. Email verified → Home Page
5. Browse products → Product Detail
6. Add to cart → Cart Page
7. Checkout → Delivery Address Setup
8. Complete order → Order Confirmation
9. View orders → Orders Page
```

### Returning User
```
1. App Launch → Splash Screen
2. Already logged in → Home Page
3. Search for product → Search Page
4. View product → Product Detail
5. Add to wishlist → Continue browsing
6. View cart → Checkout
7. Apply reward points → Discount applied
8. Complete order → Order Success
```

### Admin User
```
1. Login with admin credentials
2. Access Admin Panel
3. Add new product → Upload images
4. Set product details → Publish
5. View orders → Update order status
6. Check analytics → Generate report
```

---

## 🛠️ Integration Points

### Firebase Services
- **Authentication**: Login, Register, Password Reset
- **Firestore**: Real-time cart, rewards, notifications
- **Cloud Functions**: Order processing, notifications
- **Cloud Messaging**: Push notifications

### Backend API
- **Products**: CRUD operations
- **Orders**: Create, update, track
- **Users**: Profile management
- **Rewards**: Points calculation and redemption

### Cloudinary
- **Product Images**: Upload, transform, optimize
- **User Avatars**: Profile pictures
- **Banner Images**: Home page sliders

---

## 📈 Future Features (Potential)

- [ ] Live chat support
- [ ] Video product reviews
- [ ] AR coffee preview (augmented reality)
- [ ] Social sharing
- [ ] Referral program
- [ ] Multi-language support
- [ ] Dark mode (if not already implemented)
- [ ] Offline mode
- [ ] Voice search
- [ ] Barcode scanner for products

---

**Last Updated**: November 2, 2025
**Version**: 1.0.0
**Total Features**: 20 modules
