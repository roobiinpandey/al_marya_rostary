/// Entity representing a coffee product in the domain layer
class CoffeeProduct {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String origin;
  final String roastLevel;
  final int stock;

  const CoffeeProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.origin,
    required this.roastLevel,
    required this.stock,
  });
}
