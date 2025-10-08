import '../models/coffee.dart';

class CoffeeData {
  static List<Coffee> getCoffees() {
    return [
      const Coffee(
        id: '1',
        name: 'Arabic Coffee',
        description:
            'Traditional Arabic coffee with cardamom and saffron. A cultural experience in every sip.',
        price: 15.0,
        imageUrl:
            'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=300&h=200&fit=crop',
        category: 'Traditional',
        rating: 4.8,
        isPopular: true,
      ),
      const Coffee(
        id: '2',
        name: 'Turkish Coffee',
        description:
            'Rich and strong Turkish coffee served with Turkish delight. Finely ground and expertly brewed.',
        price: 18.0,
        imageUrl:
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=300&h=200&fit=crop',
        category: 'Traditional',
        rating: 4.7,
        isPopular: true,
      ),
      const Coffee(
        id: '3',
        name: 'Espresso',
        description:
            'Perfect shot of espresso made from premium Arabic beans. Bold and intense flavor.',
        price: 12.0,
        imageUrl:
            'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=300&h=200&fit=crop',
        category: 'Modern',
        rating: 4.6,
      ),
      const Coffee(
        id: '4',
        name: 'Cappuccino',
        description:
            'Classic cappuccino with perfectly steamed milk and a touch of cinnamon.',
        price: 20.0,
        imageUrl:
            'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=300&h=200&fit=crop',
        category: 'Modern',
        rating: 4.5,
      ),
      const Coffee(
        id: '5',
        name: 'Caramel Macchiato',
        description:
            'Smooth espresso with vanilla syrup, steamed milk, and caramel drizzle.',
        price: 25.0,
        imageUrl:
            'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=300&h=200&fit=crop',
        category: 'Specialty',
        rating: 4.4,
      ),
      const Coffee(
        id: '6',
        name: 'Mocha',
        description:
            'Rich chocolate and espresso blend topped with whipped cream.',
        price: 22.0,
        imageUrl:
            'https://images.unsplash.com/photo-1578328819058-b69f3a3b0f6b?w=300&h=200&fit=crop',
        category: 'Specialty',
        rating: 4.3,
      ),
    ];
  }
}
