class Coffee {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final List<String> sizes;
  final bool isPopular;

  const Coffee({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.rating = 4.5,
    this.sizes = const ['Small', 'Medium', 'Large'],
    this.isPopular = false,
  });
}
