import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coffee_provider.dart';
import 'coffee_product_card.dart';
import '../pages/product_detail_page.dart';

/// Widget to display a list of coffee products
class CoffeeListWidget extends StatefulWidget {
  const CoffeeListWidget({super.key});

  @override
  State<CoffeeListWidget> createState() => _CoffeeListWidgetState();
}

class _CoffeeListWidgetState extends State<CoffeeListWidget> {
  @override
  void initState() {
    super.initState();
    // Load products from API when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final coffeeProvider = Provider.of<CoffeeProvider>(
        context,
        listen: false,
      );
      if (coffeeProvider.coffees.isEmpty && !coffeeProvider.isLoading) {
        coffeeProvider.loadCoffees();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoffeeProvider>(
      builder: (context, coffeeProvider, child) {
        // Loading state
        if (coffeeProvider.isLoading && coffeeProvider.coffees.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error state
        if (coffeeProvider.hasError && coffeeProvider.coffees.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load coffee products',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  coffeeProvider.error ?? 'Unknown error',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    coffeeProvider.loadCoffees();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Success state with data
        final products = coffeeProvider.coffees;
        if (products.isEmpty) {
          return const Center(child: Text('No coffee products available'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return CoffeeProductCard(
              coffeeProduct: product,
              onTap: () {
                // Navigate to product detail page
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProductDetailPage(product: product),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
