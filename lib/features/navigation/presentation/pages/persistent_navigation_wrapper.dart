import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/cart/presentation/providers/cart_provider.dart';

/// Persistent navigation wrapper that maintains bottom navigation bar
/// across all app screens except auth pages
class PersistentNavigationWrapper extends StatefulWidget {
  final Widget child;
  final int? selectedIndex;

  const PersistentNavigationWrapper({
    super.key,
    required this.child,
    this.selectedIndex,
  });

  @override
  State<PersistentNavigationWrapper> createState() =>
      _PersistentNavigationWrapperState();
}

class _PersistentNavigationWrapperState
    extends State<PersistentNavigationWrapper> {
  int get _currentIndex {
    if (widget.selectedIndex != null) {
      return widget.selectedIndex!;
    }

    // Try to determine the current index based on the route
    final routeName = ModalRoute.of(context)?.settings.name;
    if (routeName != null) {
      if (routeName == '/rewards' || routeName.contains('reward')) {
        return 1;
      } else if (routeName == '/cart' || routeName.contains('cart')) {
        return 2;
      } else if (routeName == '/profile' ||
          routeName.contains('profile') ||
          routeName.contains('account')) {
        return 3;
      }
    }

    return 0; // Default to Home
  }

  void _onTabTapped(int index) {
    // Navigate to specific main pages when bottom nav is tapped
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main-navigation',
          (route) => false,
          arguments: {'initialIndex': 0},
        );
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main-navigation',
          (route) => false,
          arguments: {'initialIndex': 1},
        );
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main-navigation',
          (route) => false,
          arguments: {'initialIndex': 2},
        );
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main-navigation',
          (route) => false,
          arguments: {'initialIndex': 3},
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              selectedItemColor: AppTheme.primaryBrown,
              unselectedItemColor: AppTheme.textMedium,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 12,
              ),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.stars_outlined),
                  activeIcon: Icon(Icons.stars),
                  label: 'Rewards',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Icon(Icons.shopping_cart_outlined),
                      if (cartProvider.items.isNotEmpty)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBrown,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${cartProvider.items.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  activeIcon: Stack(
                    children: [
                      const Icon(Icons.shopping_cart),
                      if (cartProvider.items.isNotEmpty)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBrown,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${cartProvider.items.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Cart',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
