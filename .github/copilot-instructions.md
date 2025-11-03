# Al Marya Rostery - AI Agent Instructions

This is a **production-ready coffee ordering application** with Flutter frontend, Node.js backend, and web admin panel. Follow these guidelines when working with this codebase.

## Architecture Overview

**Stack**: Flutter + Node.js/Express + MongoDB + Firebase Auth + Vanilla JS Admin Panel  
**Status**: 100% feature complete with 50+ pages, 20+ API routes, 14 admin sections

### Key Components
- **Frontend**: Flutter mobile app (`lib/`) using Provider for state management
- **Backend**: Express API (`backend/`) with MongoDB Atlas and JWT auth
- **Admin Panel**: Vanilla JavaScript SPA (`backend/public/`) for business management
- **Database**: MongoDB with Mongoose ODM, includes comprehensive models for coffee, users, orders, loyalty, etc.

## Critical Development Patterns

### Flutter Architecture
```dart
// Feature-based structure with clean architecture
lib/
├── features/           // Feature modules (auth, coffee, cart, admin, etc.)
│   └── feature_name/
│       ├── data/       // Data sources, repositories
│       ├── domain/     // Business logic, entities
│       └── presentation/ // UI, providers, pages
├── core/              // Shared utilities, themes, services
├── providers/         // Global state management
└── utils/            // App router, constants
```

**State Management**: Use Provider pattern. All feature providers are registered in `main.dart` MultiProvider.
**Navigation**: Centralized routing in `utils/app_router.dart` with route constants.
**Theme**: Brand colors defined in `core/theme/almaryah_theme.dart` (olive gold color A89A6A primary).

### Backend Patterns
```javascript
// Typical controller structure
exports.controllerMethod = async (req, res) => {
  try {
    // Use .lean() for better performance on read operations
    const data = await Model.find(filter).lean();
    
    res.json({
      success: true,
      data: serialize(data) // Use serialize() for ObjectId handling
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
```

**Critical**: Always use `serialize()` from `middleware/jsonSerializer.js` when returning MongoDB data to prevent ObjectId buffer issues.

### Image Handling
**Placeholder Pattern**: All image loading must include error fallbacks:
```javascript
<img src="${imageUrl}" onerror="this.onerror=null; this.src='/uploads/placeholder-TYPE.jpg'">
```
Available placeholders: `placeholder-gift.jpg`, `placeholder-accessory.jpg`, `placeholder.jpg`

## Development Workflows

### Backend Development
```bash
cd backend
npm install
npm run dev        # Development with nodemon
npm start         # Production mode
```

**Important**: Server runs on port 5001, not 5000. Admin panel accessible at `http://localhost:5001/`

### Flutter Development
```bash
flutter pub get
flutter run        # Development
flutter build apk  # Android release
flutter build ios  # iOS release
```

### Database Seeding
```bash
npm run seed:all           # Seed all data
npm run loyalty:sync       # Sync loyalty data
npm run firebase:sync      # Sync Firebase users
```

## Key Integration Points

### Firebase Auth Flow
- **Mobile**: Uses `FirebaseAuth` with email/password and social logins
- **Backend**: Validates Firebase tokens and maintains JWT sessions
- **Admin**: Separate authentication for business portal

### MongoDB ObjectId Serialization
**Critical Issue**: Use `serializeMongoTypes()` or `.lean()` queries require manual serialization:
```javascript
const { serialize } = require('./middleware/jsonSerializer');
const data = await Model.find().lean();
res.json({ success: true, data: serialize(data) });
```

### Admin Panel Architecture
- **Location**: `backend/public/` - vanilla JS SPA
- **Structure**: Each feature has dedicated JS file (`js/products.js`, `js/orders.js`, etc.)
- **API Integration**: Uses fetch() with proper error handling
- **Authentication**: Session-based with role checking

## Common Debugging

### Null/Undefined Property Errors
- **Admin Panel JS**: Always use optional chaining (`?.`) and provide fallbacks
- **Example**: `inquiry.inquiry?.priority || 'medium'` instead of `inquiry.inquiry.priority`
- **Filter Data**: Remove malformed records before rendering: `data.filter(item => item && item.requiredField)`

### Image Loading Issues
- Ensure placeholder images exist in `backend/uploads/`
- Use `this.onerror=null` to prevent infinite error loops
- Check file permissions on uploads directory

### MongoDB Connection
- Validate environment variables with `npm start`
- Connection string should use MongoDB Atlas format
- Indexes are auto-created on server start

### Firebase Integration
- Check `firebase_options.dart` for platform configurations
- Verify Firebase admin SDK credentials in backend `.env`
- Auto-sync service runs every 60 seconds when enabled

## Project-Specific Conventions

### Naming Patterns
- **Routes**: Kebab-case (`/api/gift-sets`)
- **Models**: PascalCase (`GiftSet.js`)
- **Controllers**: camelCase (`giftSetController.js`)
- **Flutter**: snake_case for files, PascalCase for classes

### Error Handling
- **API**: Always return `{ success: boolean, message?: string, data?: any }`
- **Flutter**: Use try-catch with user-friendly error messages
- **Admin Panel**: Use `showErrorMessage()` helper function

### Performance Considerations
- **Backend**: Enable caching for public routes (categories, products)
- **MongoDB**: Use `.lean()` for read-only operations
- **Images**: Implement lazy loading and proper placeholder fallbacks
- **Flutter**: Use const constructors and Provider.of(listen: false) for actions

## Quick Start Commands

```bash
# Start full development environment
cd backend && npm run dev &           # Backend on :5001
cd .. && flutter run                  # Flutter app
open http://localhost:5001           # Admin panel
```

Remember: This is a **production system** - test changes thoroughly and maintain backwards compatibility.
