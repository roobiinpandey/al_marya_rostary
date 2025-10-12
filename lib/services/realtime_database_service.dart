import 'package:firebase_database/firebase_database.dart';
import '../models/coffee.dart';

/// Service for managing real-time database operations
class RealtimeDatabaseService {
  static final RealtimeDatabaseService _instance =
      RealtimeDatabaseService._internal();
  factory RealtimeDatabaseService() => _instance;
  RealtimeDatabaseService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Reference to the coffee products in the database
  DatabaseReference get coffeeRef => _database.ref('coffee_products');

  /// Adds a coffee product to the database and returns the generated ID
  Future<String> addCoffee(Coffee coffee) async {
    try {
      final ref = await coffeeRef.push();
      await ref.set(coffee.toJson());
      return ref.key!;
    } catch (e) {
      throw Exception('Failed to add coffee: $e');
    }
  }

  /// Gets all coffee products from the database
  Future<List<Coffee>> getAllCoffees() async {
    try {
      final snapshot = await coffeeRef.get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        return data.entries
            .map(
              (entry) => Coffee.fromJson(
                Map<String, dynamic>.from(entry.value),
                entry.key,
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get coffees: $e');
    }
  }

  /// Gets a single coffee product by ID
  Future<Coffee?> getCoffee(String id) async {
    try {
      final snapshot = await coffeeRef.child(id).get();
      if (snapshot.exists) {
        return Coffee.fromJson(
          Map<String, dynamic>.from(snapshot.value as Map),
          id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get coffee: $e');
    }
  }

  /// Alias for getAllCoffees() for backward compatibility
  Future<List<Coffee>> getCoffees() => getAllCoffees();

  /// Listens to coffee products changes in real-time
  Stream<List<Coffee>> getCoffeesStream() {
    return coffeeRef.onValue.map((event) {
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        return data.entries
            .map(
              (entry) => Coffee.fromJson(
                Map<String, dynamic>.from(entry.value),
                entry.key,
              ),
            )
            .toList();
      }
      return <Coffee>[];
    });
  }

  /// Updates a coffee product in the database
  Future<void> updateCoffee(String id, Coffee coffee) async {
    try {
      await coffeeRef.child(id).update(coffee.toJson());
    } catch (e) {
      throw Exception('Failed to update coffee: $e');
    }
  }

  /// Deletes a coffee product from the database
  Future<void> deleteCoffee(String id) async {
    try {
      await coffeeRef.child(id).remove();
    } catch (e) {
      throw Exception('Failed to delete coffee: $e');
    }
  }
}
