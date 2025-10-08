import 'package:flutter/material.dart';
import '../../../../data/models/coffee_product_model.dart';

/// CoffeeListPage displays all available coffee products
class CoffeeListPage extends StatelessWidget {
  final List<CoffeeProductModel> coffeeProducts;

  const CoffeeListPage({super.key, required this.coffeeProducts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Beans'),
      ),
      body: ListView.builder(
        itemCount: coffeeProducts.length,
        itemBuilder: (context, index) {
          final coffee = coffeeProducts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Image.network(
                coffee.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.coffee),
              ),
              title: Text(coffee.name),
              subtitle: Text(coffee.origin),
              trailing: Text('€${coffee.price.toStringAsFixed(2)}'),
              onTap: () {
                // TODO: Navigate to coffee details page
              },
            ),
          );
        },
      ),
    );
  }
}
