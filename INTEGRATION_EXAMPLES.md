# Auth Provider Integration Examples

## Quick Reference: Using New Auth Features

### 1. Add Session Warning Banner to Key Screens

#### Example: Orders Page
```dart
// lib/features/orders/presentation/pages/orders_page.dart
import 'package:qahwat_al_emarat/features/auth/presentation/widgets/session_warning_banner.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('My Orders')),
    body: Column(
      children: [
        const SessionWarningBanner(), // ← Add this
        Expanded(
          child: _buildOrdersList(),
        ),
      ],
    ),
  );
}
```

#### Example: Subscriptions Page
```dart
// lib/features/subscriptions/presentation/pages/subscriptions_page_enhanced.dart
import 'package:qahwat_al_emarat/features/auth/presentation/widgets/session_warning_banner.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Subscriptions')),
    body: Column(
      children: [
        const SessionWarningBanner(), // ← Add this
        Expanded(
          child: _buildSubscriptionsList(),
        ),
      ],
    ),
  );
}
```

---

### 2. Proactive Authentication Check Before API Calls

#### Example: Order Tracking Service
```dart
// lib/core/services/order_tracking_service.dart

Future<void> _pollOrderStatus() async {
  try {
    // Ensure session is valid before polling
    final authProvider = Provider.of<AuthProvider>(
      _context, 
      listen: false
    );
    
    final isAuthenticated = await authProvider.ensureAuthenticated();
    if (!isAuthenticated) {
      debugPrint('⚠️ Session expired, stopping order tracking');
      stopTracking();
      return;
    }

    // Proceed with API call
    final order = await _orderService.getOrderDetails(_orderId!);
    _controller.add(order);
    
  } catch (e) {
    // Handle errors
  }
}
```

#### Example: Subscriptions Provider
```dart
// lib/features/subscriptions/presentation/providers/subscriptions_provider.dart

Future<void> fetchUserSubscriptions() async {
  try {
    setState(SubscriptionState.loading);
    
    // Check authentication before API call
    final authProvider = Provider.of<AuthProvider>(
      context, 
      listen: false
    );
    
    if (!await authProvider.ensureAuthenticated()) {
      setError('Session expired. Please login again.');
      return;
    }

    final subscriptions = await _apiService.getUserSubscriptions();
    _subscriptions = subscriptions;
    setState(SubscriptionState.loaded);
    
  } catch (e) {
    setError('Failed to load subscriptions: $e');
  }
}
```

---

### 3. Show Session Status in User Profile

```dart
// lib/features/account/presentation/pages/profile_page.dart

Widget _buildSessionInfo(AuthProvider authProvider) {
  final remaining = authProvider.remainingSessionMinutes;
  
  if (remaining == null) {
    return const SizedBox.shrink();
  }

  return Card(
    child: ListTile(
      leading: Icon(
        Icons.timer_outlined,
        color: remaining <= 5 ? Colors.orange : Colors.green,
      ),
      title: const Text('Session Status'),
      subtitle: Text(
        remaining > 0 
          ? 'Expires in $remaining minute${remaining != 1 ? 's' : ''}'
          : 'Session expired',
      ),
      trailing: remaining <= 5 && remaining > 0
        ? TextButton(
            onPressed: () async {
              final success = await authProvider.ensureAuthenticated();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session extended'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Extend'),
          )
        : null,
    ),
  );
}

// In your build method:
@override
Widget build(BuildContext context) {
  return Consumer<AuthProvider>(
    builder: (context, authProvider, _) {
      return ListView(
        children: [
          _buildSessionInfo(authProvider), // ← Add this
          _buildProfileDetails(),
          // ... rest of profile
        ],
      );
    },
  );
}
```

---

### 4. Handle Session Expiration During Checkout

```dart
// lib/features/cart/presentation/pages/checkout_page.dart

Future<void> _processPayment() async {
  final authProvider = context.read<AuthProvider>();
  
  // Critical operation - ensure session is valid
  if (!await authProvider.ensureAuthenticated()) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Session Expired'),
          content: const Text(
            'Your session has expired. Please login again to continue with checkout.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }
    return;
  }

  // Proceed with payment
  try {
    setState(() => _isProcessing = true);
    
    final result = await _paymentService.processPayment(
      cartItems: _cartItems,
      amount: _totalAmount,
    );
    
    if (result.success && mounted) {
      Navigator.pushReplacementNamed(
        context, 
        '/order-confirmation',
        arguments: result.orderId,
      );
    }
  } catch (e) {
    _showError('Payment failed: $e');
  } finally {
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }
}
```

---

### 5. Custom Session Extension Dialog

```dart
// lib/widgets/dialogs/session_extension_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qahwat_al_emarat/features/auth/presentation/providers/auth_provider.dart';

class SessionExtensionDialog extends StatelessWidget {
  const SessionExtensionDialog({Key? key}) : super(key: key);

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SessionExtensionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        Icons.schedule,
        color: Theme.of(context).colorScheme.primary,
        size: 48,
      ),
      title: const Text('Session Expiring Soon'),
      content: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final remaining = authProvider.remainingSessionMinutes ?? 0;
          return Text(
            'Your session will expire in $remaining minute${remaining != 1 ? 's' : ''}.\n\n'
            'Would you like to extend your session?',
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Logout'),
        ),
        FilledButton(
          onPressed: () async {
            final authProvider = context.read<AuthProvider>();
            final success = await authProvider.ensureAuthenticated();
            if (context.mounted) {
              Navigator.pop(context, success);
            }
          },
          child: const Text('Extend Session'),
        ),
      ],
    );
  }
}

// Usage in your app:
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _listenToSessionWarnings();
  }

  void _listenToSessionWarnings() {
    final authProvider = context.read<AuthProvider>();
    authProvider.addListener(() {
      if (authProvider.isSessionExpiringSoon) {
        SessionExtensionDialog.show(context).then((extended) {
          if (extended == false) {
            // User chose to logout
            authProvider.logout();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Your app widget tree
  }
}
```

---

### 6. Background Session Check (Advanced)

```dart
// lib/core/services/session_monitor_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qahwat_al_emarat/features/auth/presentation/providers/auth_provider.dart';

class SessionMonitorService {
  Timer? _monitorTimer;
  final AuthProvider _authProvider;
  final BuildContext _context;

  SessionMonitorService(this._authProvider, this._context);

  void startMonitoring() {
    // Check every 30 seconds
    _monitorTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkSession(),
    );
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  Future<void> _checkSession() async {
    if (!_authProvider.isAuthenticated) return;

    final remaining = _authProvider.remainingSessionMinutes;
    
    // Auto-refresh when 10 minutes remaining
    if (remaining != null && remaining <= 10 && remaining > 5) {
      debugPrint('🔄 Auto-refreshing session (${remaining}min remaining)');
      await _authProvider.ensureAuthenticated();
    }
    
    // Show warning when 5 minutes remaining
    else if (remaining != null && remaining <= 5 && remaining > 0) {
      debugPrint('⚠️ Session warning threshold reached');
      // Trigger your custom warning UI
      _showSessionWarning();
    }
  }

  void _showSessionWarning() {
    // Implement your custom warning logic
    // Could be a snackbar, dialog, or banner
  }

  void dispose() {
    stopMonitoring();
  }
}

// Initialize in your main app:
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  SessionMonitorService? _sessionMonitor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSessionMonitoring();
  }

  void _initSessionMonitoring() {
    final authProvider = context.read<AuthProvider>();
    _sessionMonitor = SessionMonitorService(authProvider, context);
    _sessionMonitor!.startMonitoring();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause monitoring when app in background
    if (state == AppLifecycleState.paused) {
      _sessionMonitor?.stopMonitoring();
    } else if (state == AppLifecycleState.resumed) {
      _sessionMonitor?.startMonitoring();
      // Check session immediately on resume
      final authProvider = context.read<AuthProvider>();
      authProvider.ensureAuthenticated();
    }
  }

  @override
  void dispose() {
    _sessionMonitor?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Your app
  }
}
```

---

## Best Practices

### ✅ DO
- Add `SessionWarningBanner` to screens where users spend significant time
- Call `ensureAuthenticated()` before critical operations (checkout, subscriptions, etc.)
- Use `Consumer<AuthProvider>` to react to session state changes
- Implement graceful degradation when session expires
- Show user-friendly messages explaining session timeout

### ❌ DON'T
- Don't call `ensureAuthenticated()` on every API request (use it strategically)
- Don't block UI while refreshing token (use loading indicators)
- Don't ignore session expiration errors
- Don't create multiple `AuthProvider` instances
- Don't manually call `refreshToken()` (use `ensureAuthenticated()` instead)

---

## Testing These Features

### Manual Test Plan
1. **Login** → Verify token set in logs
2. **Wait 55 minutes** → Verify warning appears
3. **Click "Extend Session"** → Verify token refreshes
4. **Wait full hour** → Verify automatic logout
5. **Enter guest mode** → Verify token cleared
6. **Perform checkout** → Verify `ensureAuthenticated()` called

### Simulating Session Expiry (for faster testing)
```dart
// Temporarily change in auth_provider.dart for testing:
final Duration _sessionTimeout = const Duration(minutes: 2); // Instead of hours: 1

// Warning will appear at < 3 minutes, so will trigger immediately
// Remember to revert before production!
```

---

## Migration Checklist

- [ ] Review `AUTH_IMPROVEMENTS.md` documentation
- [ ] Add `SessionWarningBanner` to 3-5 key screens
- [ ] Update checkout flow to use `ensureAuthenticated()`
- [ ] Update subscription pages to use `ensureAuthenticated()`
- [ ] Update order tracking to check session before polling
- [ ] Test session expiration flow end-to-end
- [ ] Test token refresh during active use
- [ ] Test guest mode token clearing
- [ ] Verify debug logs show proper token lifecycle
- [ ] Update any custom auth-dependent services

---

**Ready to Use!** All changes are backward compatible. Existing code continues working without modification.
