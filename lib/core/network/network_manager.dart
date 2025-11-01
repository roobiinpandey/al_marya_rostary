import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Network connectivity manager for the Al Marya Rostery app
/// Handles network state monitoring and offline scenarios
class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  factory NetworkManager() => _instance;
  NetworkManager._internal();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  bool _isConnected = true;
  bool _isInitialized = false;
  Timer? _networkCheckTimer;

  /// Stream of network connectivity status
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Current network connectivity status
  bool get isConnected => _isConnected;

  /// Initialize network monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Check initial connectivity
    await _checkConnectivity();

    // Start periodic connectivity checks
    _networkCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );

    _isInitialized = true;
    debugPrint('✅ Network manager initialized');
  }

  /// Check network connectivity
  Future<void> _checkConnectivity() async {
    bool hasConnection = false;

    try {
      // Test actual internet connectivity by pinging reliable servers
      hasConnection = await _hasInternetAccess();
    } catch (e) {
      debugPrint('❌ Error checking connectivity: $e');
      hasConnection = false;
    }

    _updateConnectionStatus(hasConnection);
  }

  /// Test actual internet connectivity by pinging a reliable server
  Future<bool> _hasInternetAccess() async {
    try {
      // Try to connect to multiple reliable servers
      final results = await Future.wait([
        _pingServer('8.8.8.8', 53), // Google DNS
        _pingServer('1.1.1.1', 53), // Cloudflare DNS
      ], eagerError: false);

      // If any server responds, we have internet
      return results.any((result) => result);
    } catch (e) {
      debugPrint('❌ Internet access check failed: $e');
      return false;
    }
  }

  /// Ping a specific server to test connectivity
  Future<bool> _pingServer(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update connection status and notify listeners
  void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionController.add(isConnected);

      debugPrint(
        isConnected ? '✅ Network connected' : '❌ Network disconnected',
      );
    }
  }

  /// Execute operation with network check
  Future<T?> executeWithNetwork<T>(
    Future<T> Function() operation, {
    String? offlineMessage,
    bool showOfflineMessage = true,
  }) async {
    if (!_isConnected) {
      if (showOfflineMessage) {
        debugPrint('⚠️ Operation skipped: No network connection');
      }
      return null;
    }

    try {
      return await operation();
    } catch (e) {
      debugPrint('❌ Network operation failed: $e');
      rethrow;
    }
  }

  /// Check if device has network connectivity
  Future<bool> hasConnectivity() async {
    return await _hasInternetAccess();
  }

  /// Force refresh network status
  Future<void> refreshNetworkStatus() async {
    await _checkConnectivity();
  }

  /// Dispose resources
  void dispose() {
    _networkCheckTimer?.cancel();
    _connectionController.close();
  }
}

/// Network-aware widget that shows offline indicator
class NetworkAwareWidget extends StatefulWidget {
  final Widget child;
  final Widget? offlineWidget;
  final bool showOfflineIndicator;

  const NetworkAwareWidget({
    super.key,
    required this.child,
    this.offlineWidget,
    this.showOfflineIndicator = true,
  });

  @override
  State<NetworkAwareWidget> createState() => _NetworkAwareWidgetState();
}

class _NetworkAwareWidgetState extends State<NetworkAwareWidget> {
  late StreamSubscription<bool> _subscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _isConnected = NetworkManager().isConnected;
    _subscription = NetworkManager().connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      if (widget.offlineWidget != null) {
        return widget.offlineWidget!;
      }

      if (widget.showOfflineIndicator) {
        return Stack(
          children: [
            widget.child,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red[600],
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'No internet connection',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    }

    return widget.child;
  }
}

/// Mixin for widgets that need network awareness
mixin NetworkAwareMixin<T extends StatefulWidget> on State<T> {
  late StreamSubscription<bool> _networkSubscription;
  bool _isNetworkConnected = true;

  bool get isNetworkConnected => _isNetworkConnected;

  @override
  void initState() {
    super.initState();
    _isNetworkConnected = NetworkManager().isConnected;
    _networkSubscription = NetworkManager().connectionStream.listen((
      isConnected,
    ) {
      if (mounted) {
        setState(() {
          _isNetworkConnected = isConnected;
        });
        onNetworkChanged(isConnected);
      }
    });
  }

  @override
  void dispose() {
    _networkSubscription.cancel();
    super.dispose();
  }

  /// Called when network status changes
  void onNetworkChanged(bool isConnected) {
    // Override in implementing widgets
  }

  /// Execute operation only if network is available
  Future<T?> executeIfConnected<T>(Future<T> Function() operation) async {
    if (!_isNetworkConnected) {
      onNetworkUnavailable();
      return null;
    }
    return await operation();
  }

  /// Called when trying to perform network operation while offline
  void onNetworkUnavailable() {
    // Override in implementing widgets for custom offline behavior
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Please check your network.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
