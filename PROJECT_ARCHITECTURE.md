# Al Marya Rostery - Complete Project Architecture

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture Pattern](#architecture-pattern)
3. [Folder Structure](#folder-structure)
4. [Feature Modules](#feature-modules)
5. [Core Layers](#core-layers)
6. [State Management](#state-management)
7. [Navigation Architecture](#navigation-architecture)
8. [Backend Integration](#backend-integration)
9. [Legacy Structure](#legacy-structure)
10. [Development Guidelines](#development-guidelines)

---

## 🎯 Project Overview

**Al Marya Rostery** is a comprehensive Flutter e-commerce application for coffee products and accessories, featuring:
- User authentication (email, Google, Apple)
- Product catalog with categories
- Shopping cart and checkout
- Loyalty rewards program
- Order management
- User profile and account settings
- Admin panel
- Product subscriptions
- Gift sets

### Tech Stack
- **Frontend**: Flutter (Dart SDK >=3.8.0 <4.0.0)
- **Backend**: Node.js/Express on Render.com
- **Database**: MongoDB Atlas + Firebase Firestore
- **Authentication**: Firebase Auth
- **Image Storage**: Cloudinary
- **State Management**: Provider pattern

### Current Stats
- **Dart Files**: 237
- **Tracked Files**: 558
- **Library Size**: 3.1 MB
- **Feature Modules**: 20
- **Development Status**: Production Ready

---

## 🏛️ Architecture Pattern

This project follows **Clean Architecture** with **Feature-based Modularization**.

### Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                     │
│  (UI, Pages, Widgets, ViewModels/Providers)            │
├─────────────────────────────────────────────────────────┤
│                    DOMAIN LAYER                          │
│  (Business Logic, Entities, Repository Interfaces)      │
├─────────────────────────────────────────────────────────┤
│                     DATA LAYER                           │
│  (Models, Repository Implementations, Data Sources)     │
├─────────────────────────────────────────────────────────┤
│                     CORE LAYER                           │
│  (Shared Utilities, Constants, Theme, Services)        │
└─────────────────────────────────────────────────────────┘
```

### Benefits
✅ **Separation of Concerns**: Each layer has a single responsibility
✅ **Testability**: Business logic independent of UI and frameworks
✅ **Maintainability**: Changes in one layer don't affect others
✅ **Scalability**: Easy to add new features without impacting existing code
✅ **Reusability**: Core components shared across features

---

## 📁 Folder Structure

### Root Directory Structure

```
al_marya_rostery/
├── lib/                          # Flutter application code
│   ├── core/                     # Shared core functionality
│   ├── data/                     # Data layer (repositories, data sources)
│   ├── domain/                   # Domain layer (entities, business logic)
│   ├── features/                 # Feature modules (20 features)
│   ├── services/                 # Shared services
│   ├── utils/                    # Utilities and helpers
│   ├── l10n/                     # Localization files
│   ├── models/                   # ⚠️ Legacy - migrate to data/models/
│   ├── pages/                    # ⚠️ Legacy - migrate to features/
│   ├── providers/                # ⚠️ Legacy - migrate to features/
│   ├── widgets/                  # Shared widgets
│   ├── firebase_options.dart     # Firebase configuration
│   └── main.dart                 # Application entry point
│
├── backend/                      # Node.js/Express backend
│   ├── config/                   # Server configuration
│   ├── controllers/              # API controllers
│   ├── models/                   # MongoDB models
│   ├── routes/                   # API routes
│   ├── services/                 # Business logic services
│   ├── middleware/               # Authentication, error handling
│   ├── utils/                    # Backend utilities
│   └── server.js                 # Server entry point
│
├── assets/                       # Static assets
│   ├── images/                   # App images
│   ├── icons/                    # App icons
│   └── fonts/                    # Custom fonts
│
├── docs/                         # Project documentation
│   ├── CLOUDINARY_ACTION_PLAN.md
│   ├── DEPLOY_NOW.md
│   ├── FIREBASE_AUTH_FIX.md
│   ├── IMAGE_HOSTING_GUIDE.md
│   ├── PRODUCTION_CHECKLIST.md
│   └── SECURITY_CREDENTIALS_BEST_PRACTICES.md
│
├── android/                      # Android platform code
├── ios/                          # iOS platform code
├── web/                          # Web platform code
├── test/                         # Unit and widget tests
├── functions/                    # Firebase Cloud Functions
├── dataconnect/                  # Firebase Data Connect
└── pubspec.yaml                  # Flutter dependencies
```

---

## 🎨 Feature Modules

Each feature module is self-contained with its own presentation, domain, and data layers.

### Complete Feature List

| Feature | Purpose | Status |
|---------|---------|--------|
| **accessories** | Brewing equipment catalog | ✅ Active |
| **account** | User account management | ✅ Active |
| **admin** | Admin panel for content management | ✅ Active |
| **auth** | Authentication (login, register, password reset) | ✅ Active |
| **brewing_methods** | Coffee brewing guides and tutorials | ✅ Active |
| **cart** | Shopping cart with empty state handling | ✅ Active |
| **checkout** | Multi-step checkout with rewards integration | ✅ Active |
| **coffee** | Coffee products catalog | ✅ Active |
| **common** | Shared feature components | ✅ Active |
| **gifts** | Gift sets and gift cards | ✅ Active |
| **home** | Home page with featured products | ✅ Active |
| **navigation** | App navigation (bottom nav, drawer) | ✅ Active |
| **orders** | Order history and tracking | ✅ Active |
| **profile** | User profile and preferences | ✅ Active |
| **rewards** | Loyalty rewards program | ✅ Active |
| **search** | Product search functionality | ✅ Active |
| **splash** | Splash screen and app initialization | ✅ Active |
| **subscription** | Coffee subscription management | ✅ Active |
| **subscriptions** | Additional subscription features | 🔄 Review (possible duplicate) |
| **wishlist** | Saved favorites | ✅ Active |

### Feature Module Structure

Each feature follows this structure:

```
features/<feature_name>/
├── data/
│   ├── models/              # Data models (JSON serialization)
│   ├── repositories/        # Repository implementations
│   └── datasources/         # API/local data sources
├── domain/
│   ├── entities/            # Business entities
│   └── repositories/        # Repository interfaces
└── presentation/
    ├── pages/               # Feature screens
    ├── widgets/             # Feature-specific widgets
    └── providers/           # State management providers
```

### Example: Cart Feature Structure

```
features/cart/
├── data/
│   ├── models/
│   │   ├── cart_item_model.dart
│   │   └── cart_model.dart
│   └── repositories/
│       └── cart_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── cart_entity.dart
│   └── repositories/
│       └── cart_repository.dart
└── presentation/
    ├── pages/
    │   └── cart_page.dart          # Main cart screen
    ├── widgets/
    │   ├── cart_item_widget.dart
    │   ├── cart_summary.dart
    │   └── empty_cart_widget.dart
    └── providers/
        └── cart_provider.dart       # Cart state management
```

---

## 🔧 Core Layers

### lib/core/

Shared functionality used across all features.

```
core/
├── constants/
│   ├── app_colors.dart          # Color palette
│   ├── app_strings.dart         # Static text strings
│   ├── app_styles.dart          # Text styles
│   └── api_constants.dart       # API endpoints
├── errors/
│   ├── exceptions.dart          # Custom exceptions
│   └── failures.dart            # Failure types
├── network/
│   ├── network_info.dart        # Connection checker
│   └── api_client.dart          # HTTP client wrapper
├── theme/
│   ├── app_theme.dart           # Theme configuration
│   ├── dark_theme.dart          # Dark theme
│   └── light_theme.dart         # Light theme
└── usecases/
    └── usecase.dart             # Base usecase interface
```

### lib/services/

Application-wide services.

```
services/
├── auth_service.dart            # Firebase Authentication
├── firestore_service.dart       # Firestore database operations
├── storage_service.dart         # Local storage (secure storage)
├── notification_service.dart    # Push notifications
├── analytics_service.dart       # Analytics tracking
└── cloudinary_service.dart      # Image upload/management
```

### lib/utils/

Helper utilities and tools.

```
utils/
├── app_router.dart              # Named route configuration
├── validators.dart              # Input validation
├── formatters.dart              # Data formatting
├── date_helpers.dart            # Date utilities
├── string_helpers.dart          # String manipulation
├── image_helpers.dart           # Image processing
└── currency_helpers.dart        # Currency formatting
```

### lib/widgets/

Shared reusable widgets (to be reorganized by feature in Phase 2).

```
widgets/
├── buttons/
│   ├── primary_button.dart
│   ├── secondary_button.dart
│   └── icon_button.dart
├── inputs/
│   ├── custom_text_field.dart
│   ├── password_field.dart
│   └── search_bar.dart
├── cards/
│   ├── product_card.dart
│   └── order_card.dart
├── dialogs/
│   ├── loading_dialog.dart
│   └── confirmation_dialog.dart
└── common/
    ├── app_bar.dart
    ├── loading_indicator.dart
    └── error_widget.dart
```

---

## 🔄 State Management

### Provider Pattern

The app uses the **Provider** package for state management.

#### Provider Types Used

1. **ChangeNotifierProvider**: For mutable state
   ```dart
   ChangeNotifierProvider<CartProvider>(
     create: (_) => CartProvider(),
     child: MyApp(),
   )
   ```

2. **Provider**: For immutable services
   ```dart
   Provider<AuthService>(
     create: (_) => AuthService(),
   )
   ```

3. **StreamProvider**: For real-time data
   ```dart
   StreamProvider<User?>(
     create: (_) => authService.authStateChanges(),
     initialData: null,
   )
   ```

#### Provider Architecture

```
main.dart
  └─ MultiProvider
      ├─ AuthProvider         # User authentication state
      ├─ CartProvider         # Shopping cart state
      ├─ ProductProvider      # Product catalog
      ├─ OrderProvider        # Order management
      ├─ RewardProvider       # Loyalty rewards
      ├─ ProfileProvider      # User profile
      └─ NavigationProvider   # App navigation state
```

#### Example Provider Implementation

```dart
// features/cart/presentation/providers/cart_provider.dart
class CartProvider extends ChangeNotifier {
  final CartRepository repository;
  List<CartItem> _items = [];
  
  List<CartItem> get items => _items;
  
  double get total => _items.fold(
    0, 
    (sum, item) => sum + (item.price * item.quantity)
  );
  
  Future<void> addItem(Product product) async {
    // Business logic
    await repository.addItem(product);
    _items.add(CartItem.fromProduct(product));
    notifyListeners();
  }
  
  Future<void> removeItem(String itemId) async {
    await repository.removeItem(itemId);
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }
}
```

---

## 🧭 Navigation Architecture

### Named Routes System

The app uses named routes defined in `lib/utils/app_router.dart`.

#### Route Configuration

```dart
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        final args = settings.arguments as Map<String, dynamic>?;
        final initialIndex = args?['initialIndex'] as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => EmailVerificationGuard(
            child: MainNavigationPage(initialIndex: initialIndex),
          ),
        );
      
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginPage());
      
      case '/product':
        final productId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ProductDetailPage(productId: productId),
        );
      
      case '/checkout':
        return MaterialPageRoute(builder: (_) => CheckoutPage());
      
      case '/orders':
        return MaterialPageRoute(builder: (_) => OrdersPage());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
    }
  }
}
```

#### Navigation Patterns

**1. Simple Navigation**
```dart
Navigator.pushNamed(context, '/login');
```

**2. Navigation with Arguments**
```dart
Navigator.pushNamed(
  context, 
  '/product',
  arguments: productId,
);
```

**3. Replace Navigation (no back)**
```dart
Navigator.pushReplacementNamed(context, '/home');
```

**4. Reset Navigation Stack**
```dart
Navigator.pushNamedAndRemoveUntil(
  context,
  '/',
  (route) => false,
  arguments: {'initialIndex': 0},
);
```

**5. Root Navigator (for modals)**
```dart
Navigator.of(context, rootNavigator: true).pushNamed('/checkout');
```

### Bottom Navigation Structure

```
MainNavigationPage (PageView)
├─ Index 0: Home Page
├─ Index 1: Products/Categories
├─ Index 2: Cart Page
├─ Index 3: Rewards Page
└─ Index 4: Profile Page
```

### Route Guards

**Email Verification Guard**
```dart
class EmailVerificationGuard extends StatelessWidget {
  final Widget child;
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData && !snapshot.data!.emailVerified) {
          return EmailVerificationPage();
        }
        return child;
      },
    );
  }
}
```

---

## 🌐 Backend Integration

### API Architecture

**Base URL**: `https://almaryarostary.onrender.com`

#### API Client Configuration

```dart
// core/network/api_client.dart
class ApiClient {
  static const String baseUrl = 'https://almaryarostary.onrender.com';
  final Dio _dio;
  
  ApiClient() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  )) {
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LoggingInterceptor());
  }
  
  Future<Response> get(String path) => _dio.get(path);
  Future<Response> post(String path, dynamic data) => _dio.post(path, data: data);
}
```

### API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/products` | GET | Fetch all products |
| `/api/products/:id` | GET | Fetch product details |
| `/api/products/category/:category` | GET | Fetch products by category |
| `/api/cart` | GET | Fetch user cart |
| `/api/cart/add` | POST | Add item to cart |
| `/api/cart/remove` | DELETE | Remove cart item |
| `/api/orders` | GET | Fetch user orders |
| `/api/orders/create` | POST | Create new order |
| `/api/rewards` | GET | Fetch user rewards |
| `/api/rewards/redeem` | POST | Redeem reward points |
| `/api/auth/register` | POST | Register new user |
| `/api/auth/login` | POST | User login |

### Database Architecture

#### MongoDB Collections (Backend)
- `users` - User accounts
- `products` - Product catalog
- `orders` - Order records
- `categories` - Product categories
- `brewing_methods` - Coffee brewing guides

#### Firestore Collections (Real-time)
- `carts` - Active shopping carts
- `rewards` - Loyalty program data
- `notifications` - Push notifications
- `user_preferences` - User settings

### Image Storage (Cloudinary)

**Cloud Name**: `dzzonkdpm`

```dart
// services/cloudinary_service.dart
class CloudinaryService {
  static const String cloudName = 'dzzonkdpm';
  static const String baseUrl = 'https://res.cloudinary.com/$cloudName';
  
  String getImageUrl(String publicId, {int? width, int? height}) {
    String transformation = '';
    if (width != null || height != null) {
      transformation = '/w_${width ?? 'auto'},h_${height ?? 'auto'},c_fill';
    }
    return '$baseUrl/image/upload$transformation/$publicId';
  }
}
```

---

## ⚠️ Legacy Structure

### Files to Migrate (Phase 2)

#### lib/models/ → lib/data/models/
```
models/
├── user.dart              → features/auth/data/models/
├── product.dart           → features/coffee/data/models/
├── order.dart             → features/orders/data/models/
├── category.dart          → features/coffee/data/models/
└── brewing_method.dart    → features/brewing_methods/data/models/
```

#### lib/providers/ → feature providers/
```
providers/
├── auth_provider.dart     → features/auth/presentation/providers/
├── cart_provider.dart     → features/cart/presentation/providers/
└── theme_provider.dart    → core/theme/
```

#### lib/pages/ → feature pages/
```
pages/
├── profile_page.dart      → features/profile/presentation/pages/
├── settings_page.dart     → features/account/presentation/pages/
├── about_page.dart        → features/common/presentation/pages/
├── help_page.dart         → features/common/presentation/pages/
└── privacy_page.dart      → features/common/presentation/pages/
```

#### lib/widgets/ → feature widgets/
Reorganize shared widgets by domain:
- Authentication widgets → `features/auth/presentation/widgets/`
- Product widgets → `features/coffee/presentation/widgets/`
- Truly shared widgets → keep in `lib/widgets/common/`

### Recently Cleaned (Phase 1 Complete) ✅

#### Deleted Files
- ❌ `lib/screens/` (6 files) - Replaced by features/*/presentation/pages/
- ❌ `lib/demo_main.dart` - Demo app removed
- ❌ `lib/widgets/firestore_test_widget.dart` - Test widget removed
- ❌ `lib/pages/orders_page.dart.backup` - Backup file removed

#### Reorganized Documentation
- ✅ Created `docs/` folder
- ✅ Moved 6 guide files from root to docs/
- ✅ Created CLEANUP_ANALYSIS.md
- ✅ Created PHASE_2_CLEANUP_PLAN.md

#### Backend Cleanup
- ❌ Deleted 13 obsolete email setup scripts
- ✅ Enhanced .gitignore
- ✅ Removed ~20,000 node_modules files from git tracking

---

## 📖 Development Guidelines

### Adding a New Feature

1. **Create Feature Folder**
   ```
   lib/features/<feature_name>/
   ├── data/
   ├── domain/
   └── presentation/
   ```

2. **Define Domain Entities**
   ```dart
   // domain/entities/example_entity.dart
   class ExampleEntity {
     final String id;
     final String name;
     
     ExampleEntity({required this.id, required this.name});
   }
   ```

3. **Create Data Models**
   ```dart
   // data/models/example_model.dart
   class ExampleModel extends ExampleEntity {
     ExampleModel({required super.id, required super.name});
     
     factory ExampleModel.fromJson(Map<String, dynamic> json) {
       return ExampleModel(
         id: json['id'],
         name: json['name'],
       );
     }
   }
   ```

4. **Implement Repository**
   ```dart
   // domain/repositories/example_repository.dart
   abstract class ExampleRepository {
     Future<List<ExampleEntity>> getAll();
   }
   
   // data/repositories/example_repository_impl.dart
   class ExampleRepositoryImpl implements ExampleRepository {
     final ApiClient apiClient;
     
     @override
     Future<List<ExampleEntity>> getAll() async {
       final response = await apiClient.get('/api/examples');
       return (response.data as List)
         .map((json) => ExampleModel.fromJson(json))
         .toList();
     }
   }
   ```

5. **Create Provider**
   ```dart
   // presentation/providers/example_provider.dart
   class ExampleProvider extends ChangeNotifier {
     final ExampleRepository repository;
     List<ExampleEntity> _items = [];
     
     List<ExampleEntity> get items => _items;
     
     Future<void> loadItems() async {
       _items = await repository.getAll();
       notifyListeners();
     }
   }
   ```

6. **Build UI**
   ```dart
   // presentation/pages/example_page.dart
   class ExamplePage extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return Consumer<ExampleProvider>(
         builder: (context, provider, child) {
           return ListView.builder(
             itemCount: provider.items.length,
             itemBuilder: (context, index) {
               return ListTile(
                 title: Text(provider.items[index].name),
               );
             },
           );
         },
       );
     }
   }
   ```

### Best Practices

✅ **DO**:
- Follow clean architecture layers
- Use providers for state management
- Implement repository pattern for data access
- Use named routes for navigation
- Keep widgets small and focused
- Write unit tests for business logic
- Use const constructors when possible
- Format code with `dart format`
- Run `flutter analyze` before committing

❌ **DON'T**:
- Put business logic in widgets
- Make direct API calls from widgets
- Use context across async gaps
- Ignore lint warnings
- Create god classes
- Skip error handling
- Commit commented-out code

### Code Style

```dart
// Good: Clear naming, single responsibility
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  
  const ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Image.network(product.imageUrl),
            Text(product.name),
            Text('\$${product.price}'),
          ],
        ),
      ),
    );
  }
}
```

### Testing

```dart
// test/features/cart/cart_provider_test.dart
void main() {
  group('CartProvider', () {
    late CartProvider cartProvider;
    late MockCartRepository mockRepository;
    
    setUp(() {
      mockRepository = MockCartRepository();
      cartProvider = CartProvider(mockRepository);
    });
    
    test('should add item to cart', () async {
      final product = Product(id: '1', name: 'Coffee', price: 10.0);
      
      await cartProvider.addItem(product);
      
      expect(cartProvider.items.length, 1);
      expect(cartProvider.total, 10.0);
    });
  });
}
```

---

## 📊 Project Metrics

### Code Statistics
- **Total Dart Files**: 237
- **Feature Modules**: 20
- **Lines of Code**: ~50,000 (estimated)
- **Test Coverage**: Growing

### Cleanup Impact (Phase 1)
- **Files Deleted**: 27
- **Lines Removed**: 3,025
- **Space Saved**: ~250 MB
- **Git Files Reduced**: ~20,000

### Performance
- **App Size**: TBD
- **Build Time**: ~37s (iOS)
- **Hot Reload**: <1s
- **Startup Time**: <2s

---

## 🚀 Next Steps

### Immediate (Before Production - Monday, Nov 4)
- [ ] Review this architecture document
- [ ] Test all critical user flows
- [ ] Verify backend API endpoints
- [ ] Check Firebase configuration
- [ ] Test on physical devices
- [ ] Prepare app store assets

### Short Term (Phase 2 - Post Launch)
- [ ] Migrate lib/models/ to data/models/
- [ ] Migrate lib/providers/ to feature providers
- [ ] Migrate lib/pages/ to feature pages
- [ ] Reorganize lib/widgets/ by feature
- [ ] Review subscription/subscriptions duplication
- [ ] Evaluate functions/ and dataconnect/ folders

### Long Term (Future Enhancements)
- [ ] Increase test coverage
- [ ] Implement CI/CD pipeline
- [ ] Add performance monitoring
- [ ] Optimize image loading
- [ ] Implement offline mode
- [ ] Add A/B testing capability

---

## 📚 Additional Documentation

See the `docs/` folder for detailed guides:
- **CLOUDINARY_ACTION_PLAN.md** - Image hosting setup
- **DEPLOY_NOW.md** - Deployment instructions
- **FIREBASE_AUTH_FIX.md** - Authentication troubleshooting
- **IMAGE_HOSTING_GUIDE.md** - Image management best practices
- **PRODUCTION_CHECKLIST.md** - Pre-launch checklist
- **SECURITY_CREDENTIALS_BEST_PRACTICES.md** - Security guidelines

See root folder for cleanup documentation:
- **CLEANUP_ANALYSIS.md** - Detailed cleanup audit
- **PHASE_2_CLEANUP_PLAN.md** - Migration roadmap

---

**Last Updated**: November 2, 2025
**Version**: 1.0.0
**Status**: ✅ Production Ready
