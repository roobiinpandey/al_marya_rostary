import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../coffee/presentation/widgets/coffee_list_widget.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../widgets/hero_banner_carousel.dart';
import '../widgets/quick_categories_widget.dart';
import '../widgets/product_grid_widget.dart';
import '../../../../widgets/common/app_drawer.dart'; // Import the proper AppDrawer
import '../../../../providers/location_provider.dart';
import '../widgets/location_picker_dialog.dart';
import '../widgets/search_dialog.dart';

/// HomePage displays featured coffee products and navigation
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    // Show refresh indicator
    await Future.wait([
      // Reload location
      if (mounted)
        Provider.of<LocationProvider>(context, listen: false).refreshLocation(),
      // Add a small delay to ensure smooth animation
      Future.delayed(const Duration(milliseconds: 500)),
    ]);

    // Force rebuild of child widgets by calling setState
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LocationProvider>(
          builder: (context, locationProvider, child) {
            return GestureDetector(
              onTap: () {
                if (locationProvider.hasError) {
                  // Show permission dialog
                  _showLocationPermissionDialog(context, locationProvider);
                } else {
                  // Show location picker dialog
                  _showLocationPickerDialog(context);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    color: locationProvider.hasError
                        ? Colors.orange
                        : context.colors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  if (locationProvider.isLoading)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Deliver to',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70, fontSize: 12),
                          ),
                          Row(
                            children: [
                              if (locationProvider.useManualLocation) ...[
                                Icon(
                                  locationProvider.getLocationTitle() == 'Home'
                                      ? Icons.home
                                      : locationProvider.getLocationTitle() ==
                                            'Work'
                                      ? Icons.business
                                      : Icons.location_on,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  locationProvider.getDisplayLocation(),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: locationProvider.hasError
                                            ? Colors.orange
                                            : Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 4),
                  if (!locationProvider.isLoading)
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: locationProvider.hasError
                          ? Colors.orange
                          : Colors.white70,
                    ),
                ],
              ),
            );
          },
        ),
        actions: [
          // Search button
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () => _showSearchDialog(context),
          ),
          // Favorites button
          IconButton(
            icon: Icon(Icons.favorite_outline, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushNamed('/favorites');
            },
          ),
        ],
        elevation: 0,
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        color: context.colors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Enables pull-to-refresh even when content is small
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 100,
            ), // Account for FAB with extra space
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner Carousel
                const HeroBannerCarousel(),
              // Quick Categories
              const QuickCategoriesWidget(),
              // Featured Products Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Icon(Icons.star, color: context.colors.secondary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Featured Products',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to all products page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('View all products coming soon!'),
                          ),
                        );
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Product Grid (2x2)
              const ProductGridWidget(),
              // All Products Section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.grid_view,
                      color: context.colors.secondary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Products',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              // Coffee List (original full list)
              const CoffeeListWidget(),
              ],
            ),
          ),
        ),
      ),
      drawer:
          const AppDrawer(), // Use the proper AppDrawer with Profile section
    );
  }

  /// Show location permission dialog when location error occurs
  void _showLocationPermissionDialog(
    BuildContext context,
    LocationProvider locationProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Location Access Needed'),
          ],
        ),
        content: Text(
          locationProvider.errorMessage ??
              'To show your delivery location, please enable location access in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Try to open location settings
              await locationProvider.openSettings();
              // Refresh location after user returns
              await Future.delayed(const Duration(seconds: 1));
              locationProvider.refreshLocation();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Show location picker dialog
  void _showLocationPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LocationPickerDialog(),
    );
  }

  /// Show search dialog
  void _showSearchDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const SearchDialog());
  }
}
