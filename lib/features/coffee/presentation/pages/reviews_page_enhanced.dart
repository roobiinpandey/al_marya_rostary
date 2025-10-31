import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reviews_provider.dart';

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
  @override
  void initState() {
    super.initState();
    // Load reviews when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewsProvider>().loadProductReviews(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              context.read<ReviewsProvider>().sortReviews(value);
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ReviewsProvider>().refresh(widget.productId);
            },
          ),
        ],
      ),
      body: Consumer<ReviewsProvider>(
        builder: (context, reviewsProvider, child) {
          if (reviewsProvider.isLoading && !reviewsProvider.hasReviews) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reviewsProvider.hasError && !reviewsProvider.hasReviews) {
            return _buildErrorState(reviewsProvider.error!, reviewsProvider);
          }

          return Column(
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
                        _buildRatingOverview(reviewsProvider),
                        const SizedBox(width: 24),
                        ElevatedButton.icon(
                          onPressed: reviewsProvider.isSubmitting
                              ? null
                              : () {
                                  Navigator.pushNamed(
                                    context,
                                    '/write-review',
                                    arguments: {
                                      'productId': widget.productId,
                                      'productName': widget.productName,
                                    },
                                  ).then((_) {
                                    // Refresh reviews when returning from write review
                                    reviewsProvider.refresh(widget.productId);
                                  });
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
                child: reviewsProvider.hasReviews
                    ? RefreshIndicator(
                        onRefresh: () =>
                            reviewsProvider.refresh(widget.productId),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: reviewsProvider.reviews.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 24),
                          itemBuilder: (context, index) {
                            return _buildReviewCard(
                              reviewsProvider.reviews[index],
                              reviewsProvider,
                            );
                          },
                        ),
                      )
                    : _buildEmptyState(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error, ReviewsProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.refresh(widget.productId),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingOverview(ReviewsProvider provider) {
    final avgRating = double.tryParse(provider.formattedAverageRating) ?? 0.0;

    return Column(
      children: [
        Text(
          provider.formattedAverageRating,
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
          '${provider.totalReviews} reviews',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Review review, ReviewsProvider provider) {
    final userName = review.userName;
    final rating = review.rating;
    final comment = review.comment;
    final helpfulCount = review.helpfulCount;
    final createdAt = review.createdAt;

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
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
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
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(createdAt),
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
            Text(comment, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 12),

            // Helpful button
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    provider.markReviewHelpful(review.id);
                  },
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: Text('Helpful ($helpfulCount)'),
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
              ).then((_) {
                // Refresh reviews when returning from write review
                context.read<ReviewsProvider>().refresh(widget.productId);
              });
            },
            icon: const Icon(Icons.edit),
            label: const Text('Write a Review'),
          ),
        ],
      ),
    );
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
