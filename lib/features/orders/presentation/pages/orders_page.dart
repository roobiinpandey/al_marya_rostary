import 'package:flutter/material.dart';

/// OrdersPage displays the user's order history
class OrdersPage extends StatelessWidget {
  final List<Order> orders;

  const OrdersPage({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: orders.isEmpty
          ? const Center(child: Text('No orders found.'))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.brown),
                    title: Text('Order #${order.id}'),
                    subtitle: Text('Total: \u20AC${order.total.toStringAsFixed(2)}'),
                    trailing: Text(order.status),
                    onTap: () {
                      // TODO: Show order details
                    },
                  ),
                );
              },
            ),
    );
  }
}

/// Simple order entity for demonstration
class Order {
  final String id;
  final double total;
  final String status;

  Order({required this.id, required this.total, required this.status});
}
