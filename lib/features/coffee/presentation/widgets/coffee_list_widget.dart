import 'package:flutter/material.dart';
import 'package:qahwat_al_emarat/data/models/coffee_product_model.dart';
import 'coffee_product_card.dart';
import '../pages/product_detail_page.dart';

/// Widget to display a list of coffee products
class CoffeeListWidget extends StatefulWidget {
  const CoffeeListWidget({super.key});

  @override
  State<CoffeeListWidget> createState() => _CoffeeListWidgetState();
}

class _CoffeeListWidgetState extends State<CoffeeListWidget> {
  late Future<List<CoffeeProductModel>> _coffeeProductsFuture;

  @override
  void initState() {
    super.initState();
    _coffeeProductsFuture = _fetchCoffeeProducts();
  }

  Future<List<CoffeeProductModel>> _fetchCoffeeProducts() async {
    // TODO: Replace with actual API call
    // For now, return mock data
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    return [
      const CoffeeProductModel(
        id: '1',
        name: 'Ethiopian Yirgacheffe',
        description: 'Light roasted single origin coffee from Ethiopia',
        price: 24.99,
        imageUrl: 'https://via.placeholder.com/150',
        origin: 'Ethiopia',
        roastLevel: 'Light',
        stock: 50,
      ),
      const CoffeeProductModel(
        id: '2',
        name: 'Colombian Supremo',
        description: 'Medium roasted coffee from the mountains of Colombia',
        price: 19.99,
        imageUrl: 'https://via.placeholder.com/150',
        origin: 'Colombia',
        roastLevel: 'Medium',
        stock: 30,
      ),
      const CoffeeProductModel(
        id: '3',
        name: 'Brazilian Santos',
        description: 'Dark roasted coffee with chocolate notes',
        price: 22.99,
        imageUrl: 'https://via.placeholder.com/150',
        origin: 'Brazil',
        roastLevel: 'Dark',
        stock: 40,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CoffeeProductModel>>(
      future: _coffeeProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
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
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _coffeeProductsFuture = _fetchCoffeeProducts();
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (snapshot.hasData) {
          final products = snapshot.data!;
          if (products.isEmpty) {
            return const Center(
              child: Text('No coffee products available'),
            );
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
        } else {
          return const Center(
            child: Text('No data available'),
          );
        }
      },
    );
  }
}
