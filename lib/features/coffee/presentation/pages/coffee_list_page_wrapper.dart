import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coffee_provider.dart';
import 'coffee_list_page.dart';
import 'package:qahwat_al_emarat/core/theme/theme_extensions.dart';

/// Wrapper for CoffeeListPage that fetches data from CoffeeProvider
/// This allows the page to be used with named routes without arguments
class CoffeeListPageWrapper extends StatelessWidget {
  const CoffeeListPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CoffeeProvider>(
      builder: (context, coffeeProvider, child) {
        final colors = context.colors;

        // Show loading state
        if (coffeeProvider.isLoading && coffeeProvider.coffees.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Coffee Menu'),
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Show error state
        if (coffeeProvider.hasError && coffeeProvider.coffees.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Coffee Menu'),
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load coffee products',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    coffeeProvider.error ?? 'Unknown error',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => coffeeProvider.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show coffee list with data from provider
        return CoffeeListPage(coffeeProducts: coffeeProvider.coffees);
      },
    );
  }
}
