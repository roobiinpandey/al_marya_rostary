# 🎛️ Al Marya Rostery - Admin Panel & Backend Guide

## 📋 Table of Contents
1. [Admin Panel Access](#admin-panel-access)
2. [Core Admin Features](#core-admin-features)
3. [API Endpoints Overview](#api-endpoints-overview)
4. [Product Management](#product-management)
5. [Order Management](#order-management)
6. [User Management](#user-management)
7. [Content Management](#content-management)
8. [Analytics & Reports](#analytics--reports)
9. [Security & JWT Management](#security--jwt-management)
10. [Testing & Debugging](#testing--debugging)

---

## 🔐 Admin Panel Access

### Admin Panel URLs
- **Local Development:** http://localhost:5001
- **Production:** https://almaryarostary.onrender.com

### Admin Login
- **Endpoint:** `POST /api/auth/admin-login`
- **Required:** Admin role in database
- **Default Credentials:** ⚠️ **CHANGE BEFORE CLIENT HANDOVER**

### Key Admin Features
- Real-time dashboard
- Product & inventory management
- Order processing & tracking
- User management
- Content management (sliders, notifications)
- Analytics & reporting
- JWT token blacklist management

---

## 🎯 Core Admin Features

### 1. **Dashboard & Analytics**
```
GET /api/orders/stats          - Order statistics
GET /api/orders/analytics      - Detailed analytics
GET /api/users/stats           - User statistics
GET /api/coffees/stats         - Coffee product stats
GET /api/accessories/admin/analytics - Accessory analytics
GET /api/reviews/admin/stats   - Review statistics
GET /api/subscriptions/admin/stats - Subscription stats
GET /api/sliders/stats         - Slider performance
GET /api/notifications/stats   - Notification stats
```

### 2. **Product Management**

#### Coffee Products
```
GET    /api/coffees              - List all coffees
GET    /api/coffees/:id          - Get coffee details
POST   /api/coffees              - Create new coffee (admin only)
PUT    /api/coffees/:id          - Update coffee (admin only)
DELETE /api/coffees/:id          - Delete coffee (admin only)
GET    /api/coffees/stats        - Coffee statistics
```

**Features:**
- Image upload & management
- Pricing & inventory control
- Category & attributes
- Ratings & reviews
- Stock management

#### Accessories
```
GET    /api/accessories                    - List all accessories
GET    /api/accessories/:id                - Get accessory details
POST   /api/accessories                    - Create accessory (admin)
PUT    /api/accessories/:id                - Update accessory (admin)
DELETE /api/accessories/:id                - Delete accessory (admin)
PATCH  /api/accessories/:id/toggle-status  - Enable/disable
PATCH  /api/accessories/:id/stock          - Update stock
GET    /api/accessories/admin/analytics    - Analytics
```

**Features:**
- Multi-type support (grinders, brewers, filters, etc.)
- Stock tracking
- Featured items
- Analytics
- Image upload

---

## 📦 Order Management

### Order Operations
```
GET    /api/orders                - List all orders (with filters)
GET    /api/orders/:id            - Get order details
PUT    /api/orders/:id/status     - Update order status
PUT    /api/orders/:id/payment    - Update payment status
DELETE /api/orders/:id            - Delete order
GET    /api/orders/export         - Export orders (CSV/Excel)
```

### Order Statuses
- `pending` - Order placed, awaiting payment
- `paid` - Payment confirmed
- `processing` - Order being prepared
- `shipped` - Order dispatched
- `delivered` - Order delivered
- `cancelled` - Order cancelled

### Payment Statuses
- `pending` - Awaiting payment
- `completed` - Payment successful
- `failed` - Payment failed
- `refunded` - Payment refunded

### Order Analytics
```
GET /api/orders/stats - Summary statistics
GET /api/orders/analytics - Detailed analytics
```

**Available Filters:**
- Date range
- Status
- Payment status
- Customer
- Price range

---

## 👥 User Management

### User Operations
```
GET    /api/users              - List all users
GET    /api/users/:id          - Get user details
PUT    /api/users/:id          - Update user
DELETE /api/users/:id          - Delete user
GET    /api/users/stats        - User statistics
```

### User Roles
- `customer` - Regular customer
- `admin` - Administrator
- `staff` - Staff member
- `driver` - Delivery driver

### User Features
- Email verification status
- Order history
- Loyalty points
- Address management
- Profile updates

---

## 🎨 Content Management

### 1. **Sliders/Banners**
```
GET    /api/sliders           - List all sliders
GET    /api/sliders/:id       - Get slider details
POST   /api/sliders           - Create slider (admin)
PUT    /api/sliders/:id       - Update slider (admin)
DELETE /api/sliders/:id       - Delete slider (admin)
POST   /api/sliders/:id/click - Track clicks
POST   /api/sliders/:id/view  - Track views
GET    /api/sliders/stats     - Slider analytics
```

**Slider Types:**
- `banner` - Main homepage banner
- `promotion` - Promotional slider
- `announcement` - Announcement bar
- `category` - Category highlight

### 2. **Notifications**
```
GET    /api/notifications              - List notifications
POST   /api/notifications              - Create notification (admin)
PUT    /api/notifications/:id          - Update notification (admin)
DELETE /api/notifications/:id          - Delete notification (admin)
POST   /api/notifications/test         - Send test notification
GET    /api/notifications/ready-to-send - Get scheduled notifications
GET    /api/notifications/stats        - Notification statistics
```

**Notification Types:**
- `order` - Order updates
- `promotion` - Marketing promotions
- `announcement` - General announcements
- `reminder` - Reminders

### 3. **Reviews Management**
```
GET   /api/reviews/product/:productId  - Get product reviews
GET   /api/reviews/admin/pending       - Pending reviews (admin)
PATCH /api/reviews/admin/:id/moderate  - Moderate review (admin)
GET   /api/reviews/admin/stats         - Review statistics
GET   /api/reviews/admin/list          - All reviews (admin)
```

**Moderation Actions:**
- `approve` - Approve review
- `reject` - Reject review
- `flag` - Flag for attention

---

## 💳 Subscription Management

### Subscription Operations
```
GET    /api/subscriptions/plans          - List plans
POST   /api/subscriptions/plans          - Create plan (admin)
PUT    /api/subscriptions/plans/:id      - Update plan (admin)
DELETE /api/subscriptions/plans/:id      - Delete plan (admin)
GET    /api/subscriptions/admin/stats    - Subscription statistics
GET    /api/subscriptions/admin/list     - All subscriptions
```

### Subscription Features
- Monthly coffee delivery plans
- Pause/resume subscriptions
- Delivery schedule management
- Auto-billing
- Subscription analytics

---

## ⚙️ Settings Management

### App Settings
```
GET    /api/settings              - Get all settings
GET    /api/settings/:key         - Get specific setting
PUT    /api/settings/:key         - Update setting
POST   /api/settings/initialize   - Initialize defaults
POST   /api/settings/reset        - Reset to defaults
PUT    /api/settings/bulk         - Bulk update settings
```

**Available Settings:**
- App configuration
- Payment gateway settings
- Email settings
- Notification preferences
- Business hours
- Delivery zones
- Tax & shipping rates

---

## 🔒 Security & JWT Management

### JWT Token Blacklist (NEW!)
```
GET  /api/admin/token-blacklist/stats    - View blacklist statistics
POST /api/admin/token-blacklist/cleanup  - Clean expired tokens
POST /api/admin/token-blacklist/clear    - Clear all tokens
POST /api/admin/token-blacklist/add      - Manually blacklist token
POST /api/admin/token-blacklist/remove   - Remove from blacklist
POST /api/admin/token-blacklist/check    - Check token status
```

**Security Features:**
- ✅ Token revocation on logout
- ✅ Single-use refresh tokens (token rotation)
- ✅ Rate limiting (5 attempts/15min on refresh)
- ✅ Automatic token cleanup after expiration
- ✅ Admin monitoring dashboard

### Authentication
```
POST /api/auth/login              - User login
POST /api/auth/admin-login        - Admin login
POST /api/auth/logout             - Logout (blacklist token)
POST /api/auth/refresh            - Refresh token (rate limited)
POST /api/auth/forgot-password    - Password reset request
POST /api/auth/reset-password     - Reset password
```

---

## 📊 Analytics & Reports

### Sales Reports
```
GET /api/reports/sales     - Sales report
GET /api/reports/users     - User report
GET /api/reports/products  - Product report
```

**Report Filters:**
- Date range (daily, weekly, monthly, yearly)
- Product categories
- Customer segments
- Payment methods

### Real-time Analytics
- Order tracking
- Revenue metrics
- Top-selling products
- Customer behavior
- Conversion rates

---

## 🛠️ Testing & Debugging

### Debug Endpoints
```
GET  /api/debug/user-counts             - User count analysis
GET  /api/debug/problematic-users       - Find issues
POST /api/debug/fix-duplicate-firebase-uid - Fix duplicates
```

### Firebase Sync
```
POST /api/auto-sync/start       - Start auto-sync
POST /api/auto-sync/stop        - Stop auto-sync
GET  /api/auto-sync/status      - Check sync status
POST /api/auto-sync/force-sync  - Force manual sync
PUT  /api/auto-sync/interval    - Update sync interval
```

### Health Check
```
GET /health - Server health status
```

**Response includes:**
- Server uptime
- Database connection status
- Memory usage
- Cache statistics
- Request metrics

---

## 🚀 Quick Start for Admins

### 1. Login to Admin Panel
1. Navigate to: http://localhost:5001 (or production URL)
2. Click "Login"
3. Enter admin credentials
4. Access dashboard

### 2. Common Tasks

#### Add New Product
1. Go to Products → Add New
2. Fill in details (name, price, description)
3. Upload image
4. Set stock quantity
5. Select category & attributes
6. Save

#### Process Order
1. Go to Orders → Pending
2. Click on order
3. Verify payment
4. Update status to "Processing"
5. Prepare items
6. Update to "Shipped" with tracking
7. Mark as "Delivered" when complete

#### Manage Reviews
1. Go to Reviews → Pending
2. Read review content
3. Approve or reject
4. Flag inappropriate reviews

#### View Analytics
1. Go to Dashboard
2. Select date range
3. View:
   - Total revenue
   - Order statistics
   - Top products
   - Customer insights

---

## 🔐 Security Best Practices

### For Admins:
1. ✅ Change default admin password immediately
2. ✅ Use strong passwords (min 12 characters)
3. ✅ Enable two-factor authentication (if available)
4. ✅ Logout after each session
5. ✅ Don't share admin credentials
6. ✅ Monitor token blacklist regularly
7. ✅ Review user activity logs
8. ✅ Keep backup of important data

### For Developers:
1. ✅ MongoDB password rotated regularly
2. ✅ JWT secrets kept secure
3. ✅ HTTPS enforced in production
4. ✅ Rate limiting enabled
5. ✅ Input validation on all endpoints
6. ✅ SQL injection protection (MongoDB sanitization)
7. ✅ XSS protection (Helmet.js)
8. ✅ CORS properly configured

---

## 📞 Support & Troubleshooting

### Common Issues

#### "Token has been revoked"
- **Cause:** Token was blacklisted (logout or admin action)
- **Solution:** Login again to get new token

#### "Too many token refresh attempts"
- **Cause:** Rate limit hit (5 attempts/15min)
- **Solution:** Wait 15 minutes or login again

#### "Invalid admin credentials"
- **Cause:** Wrong email/password or user not admin
- **Solution:** Verify credentials or check user role in database

#### "Database connection failed"
- **Cause:** MongoDB connection issue
- **Solution:** Check MONGODB_URI environment variable

### Backend Logs
Check terminal/console for detailed error messages:
```bash
cd backend
npm start
```

### Production Logs
View logs on Render.com dashboard:
1. Go to https://dashboard.render.com/
2. Select backend service
3. Click "Logs" tab

---

## 📝 API Response Format

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {
    // Response data here
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "error": {
    "code": "ERROR_CODE",
    "details": "Additional information"
  }
}
```

---

## 🎓 Training Resources

### For New Admins:
1. Review this guide thoroughly
2. Practice in development environment first
3. Understand order workflow
4. Learn product management
5. Test notification system
6. Review security features

### Video Tutorials (if available):
- Admin panel overview
- Product management
- Order processing
- Analytics interpretation

---

## 📅 Maintenance Schedule

### Daily:
- Check pending orders
- Review new reviews
- Monitor system health

### Weekly:
- Generate sales reports
- Review inventory levels
- Check notification performance
- Monitor JWT blacklist

### Monthly:
- Analyze trends
- Update product offerings
- Review user feedback
- Optimize system performance

---

## ✅ Pre-Launch Checklist

- [ ] Admin password changed
- [ ] MongoDB password rotated
- [ ] All features tested
- [ ] Backup procedures verified
- [ ] Analytics configured
- [ ] Notification templates ready
- [ ] Payment gateway tested
- [ ] Email service verified
- [ ] SSL certificate active
- [ ] Domain configured
- [ ] Staff trained

---

## 📧 Contact

For technical support or questions:
- **Developer:** roobiinpandey@gmail.com
- **Backend Repo:** https://github.com/roobiinpandey/al_marya_rostary

---

**Last Updated:** November 4, 2025  
**Version:** 2.0 (with JWT Security Enhancements)
