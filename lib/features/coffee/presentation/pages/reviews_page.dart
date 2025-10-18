import 'package:flutter/material.dart';

class ReviewsPage extends StatefulWidget {
  final String productId;
  final String productName;

  const ReviewsPage({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final List<Map<String, dynamic>> _reviews = [
    {
      'id': '1',
      'userName': 'Ahmed Al-Mansoori',
      'userAvatar': '',
      'rating': 5.0,
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'comment':
          'Excellent coffee! The aroma is amazing and the taste is rich and smooth. Highly recommend!',
      'helpful': 12,
    },
    {
      'id': '2',
      'userName': 'Fatima Hassan',
      'userAvatar': '',
      'rating': 4.0,
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'comment': 'Great quality coffee. Perfect for my morning routine.',
      'helpful': 8,
    },
    {
      'id': '3',
      'userName': 'Mohammed Al-Rashid',
      'userAvatar': '',
      'rating': 5.0,
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'comment': 'Best coffee I\'ve ever purchased! Fresh and flavorful.',
      'helpful': 15,
    },
  ];

  String _sortBy = 'recent';

  @override
  Widget build(BuildContext context) {
    final sortedReviews = _getSortedReviews();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'recent', child: Text('Most Recent')),
              const PopupMenuItem(
                value: 'helpful',
                child: Text('Most Helpful'),
              ),
              const PopupMenuItem(
                value: 'highest',
                child: Text('Highest Rating'),
              ),
              const PopupMenuItem(
                value: 'lowest',
                child: Text('Lowest Rating'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Product Info & Write Review Button
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            child: Column(
              children: [
                Text(
                  widget.productName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRatingOverview(),
                    const SizedBox(width: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/write-review',
                          arguments: {
                            'productId': widget.productId,
                            'productName': widget.productName,
                          },
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Write Review'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Reviews List
          Expanded(
            child: sortedReviews.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedReviews.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 24),
                    itemBuilder: (context, index) {
                      return _buildReviewCard(sortedReviews[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingOverview() {
    final avgRating =
        _reviews.fold<double>(
          0,
          (sum, review) => sum + (review['rating'] as double),
        ) /
        _reviews.length;

    return Column(
      children: [
        Text(
          avgRating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < avgRating.round() ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 20,
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          '${_reviews.length} reviews',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info & rating
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    review['userName'][0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['userName'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < (review['rating'] as double).round()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(review['date'] as DateTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Comment
            Text(review['comment'], style: const TextStyle(height: 1.5)),
            const SizedBox(height: 12),

            // Helpful button
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Mark as helpful
                  },
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: Text('Helpful (${review['helpful']})'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to review this product!',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/write-review',
                arguments: {
                  'productId': widget.productId,
                  'productName': widget.productName,
                },
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Write a Review'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getSortedReviews() {
    final reviews = List<Map<String, dynamic>>.from(_reviews);

    switch (_sortBy) {
      case 'helpful':
        reviews.sort(
          (a, b) => (b['helpful'] as int).compareTo(a['helpful'] as int),
        );
        break;
      case 'highest':
        reviews.sort(
          (a, b) => (b['rating'] as double).compareTo(a['rating'] as double),
        );
        break;
      case 'lowest':
        reviews.sort(
          (a, b) => (a['rating'] as double).compareTo(b['rating'] as double),
        );
        break;
      case 'recent':
      default:
        reviews.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
        );
        break;
    }

    return reviews;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}
