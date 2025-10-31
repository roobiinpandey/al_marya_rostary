import 'package:flutter/material.dart';
import 'screens/checkout_page.dart';
import 'features/cart/presentation/providers/cart_provider.dart';
import 'data/models/coffee_product_model.dart';
import 'core/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const RewardSystemDemoApp());
}

class RewardSystemDemoApp extends StatelessWidget {
  const RewardSystemDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartProvider())],
      child: MaterialApp(
        title: 'Reward System Demo',
        theme: ThemeData(
          primarySwatch: Colors.brown,
          colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryBrown),
        ),
        home: const RewardDemoHomePage(),
      ),
    );
  }
}

class RewardDemoHomePage extends StatelessWidget {
  const RewardDemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reward System Demo'),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Demo Cart',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (cartProvider.items.isEmpty) ...[
                          const Text('Cart is empty. Add some demo items!'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _addDemoItems(cartProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBrown,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Add Demo Items'),
                          ),
                        ] else ...[
                          ...cartProvider.items
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.name} x${item.quantity}',
                                        ),
                                      ),
                                      Text(
                                        'AED ${item.totalPrice.toStringAsFixed(2)}',
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'AED ${cartProvider.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    cartProvider.clearCart();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Clear Cart'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CheckoutPage(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBrown,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Checkout with Rewards'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reward System Features',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text('✅ Earn 1 point per AED 1 spent'),
                        Text('✅ Redeem points: 1 point = AED 0.05'),
                        Text('✅ Smart slider to select redemption amount'),
                        Text('✅ Real-time discount calculation'),
                        Text('✅ Firebase Firestore integration'),
                        Text('✅ Transaction history tracking'),
                        Text('✅ Prevents over-redemption'),
                        SizedBox(height: 12),
                        Text(
                          'Note: Make sure Firebase is configured to test the full functionality.',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addDemoItems(CartProvider cartProvider) {
    // Create demo coffee products
    const demoProducts = [
      CoffeeProductModel(
        id: 'demo1',
        name: 'Arabica Premium',
        description: 'Rich and smooth arabica blend',
        price: 45.50,
        imageUrl: 'https://via.placeholder.com/200',
        origin: 'Ethiopia',
        roastLevel: 'Medium',
        stock: 100,
        variants: [],
        categories: ['Premium'],
        isActive: true,
        isFeatured: true,
        rating: 4.8,
        reviewCount: 125,
      ),
      CoffeeProductModel(
        id: 'demo2',
        name: 'Espresso Forte',
        description: 'Strong espresso for coffee lovers',
        price: 38.75,
        imageUrl: 'https://via.placeholder.com/200',
        origin: 'Brazil',
        roastLevel: 'Dark',
        stock: 85,
        variants: [],
        categories: ['Espresso'],
        isActive: true,
        isFeatured: false,
        rating: 4.6,
        reviewCount: 89,
      ),
    ];

    // Add items to cart
    for (var product in demoProducts) {
      cartProvider.addItemWithSize(
        CartItem.coffee(product: product, quantity: 2, selectedSize: 'Medium'),
      );
    }
  }
}
