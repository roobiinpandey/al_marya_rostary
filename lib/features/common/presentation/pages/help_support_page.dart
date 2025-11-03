import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Help & Support Page
/// Note: Implement comprehensive help system and support features
class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBrown,
              unselectedLabelColor: AppTheme.textMedium,
              indicatorColor: AppTheme.primaryBrown,
              tabs: const [
                Tab(text: 'FAQ'),
                Tab(text: 'Contact Us'),
                Tab(text: 'Guides'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildFAQTab(), _buildContactTab(), _buildGuidesTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildFAQSection('General Questions', [
            _buildFAQItem(
              'What are your business hours?',
              'We are open daily from 6:00 AM to 10:00 PM. You can place orders through the app 24/7, and we\'ll prepare them during business hours.',
            ),
            _buildFAQItem(
              'Do you deliver to my area?',
              'We deliver within a 25km radius of Dubai. Enter your address during checkout to confirm delivery availability.',
            ),
            _buildFAQItem(
              'What payment methods do you accept?',
              'We accept cash on delivery, credit/debit cards, and digital wallets including Apple Pay and Google Pay.',
            ),
          ]),

          _buildFAQSection('Orders & Delivery', [
            _buildFAQItem(
              'How long does delivery take?',
              'Standard delivery takes 30-45 minutes. During peak hours, it might take up to 60 minutes.',
            ),
            _buildFAQItem(
              'Can I modify my order after placing it?',
              'You can modify your order within 5 minutes of placing it. After that, please contact our support team.',
            ),
            _buildFAQItem(
              'What if my order is delayed?',
              'We\'ll notify you immediately if there are any delays. You can also track your order in real-time through the app.',
            ),
          ]),

          _buildFAQSection('Coffee & Products', [
            _buildFAQItem(
              'Where do you source your coffee beans?',
              'We source premium Arabica beans from the finest coffee regions in Yemen, Ethiopia, and Brazil.',
            ),
            _buildFAQItem(
              'Do you offer decaffeinated options?',
              'Yes, we have decaffeinated versions of our most popular blends available.',
            ),
            _buildFAQItem(
              'Can I customize my coffee order?',
              'Absolutely! You can customize grind size, brewing method, and add special instructions.',
            ),
          ]),

          _buildFAQSection('Account & Technical', [
            _buildFAQItem(
              'How do I reset my password?',
              'Go to the login screen and tap "Forgot Password". We\'ll send you a reset link via email.',
            ),
            _buildFAQItem(
              'Can I use the app without creating an account?',
              'Yes, you can browse and place orders as a guest, but creating an account helps with order tracking and faster checkout.',
            ),
            _buildFAQItem(
              'Why can\'t I see my order history?',
              'Make sure you\'re logged into your account. Guest orders are not saved to order history.',
            ),
          ]),

          const SizedBox(height: 24),
          _buildComingSoonNote('More FAQ topics and search functionality'),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get in Touch',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'re here to help! Contact us through any of the methods below.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMedium),
          ),
          const SizedBox(height: 24),

          // Contact Methods
          _buildContactMethod(
            Icons.phone,
            'Phone Support',
            '+971 XX XXX XXXX',
            'Available 6:00 AM - 10:00 PM',
            () => _showComingSoon('Phone call functionality'),
          ),

          _buildContactMethod(
            Icons.email,
            'Email Support',
            'support@almaryarostery.com',
            'Response within 24 hours',
            () => _showComingSoon('Email functionality'),
          ),

          _buildContactMethod(
            Icons.chat,
            'Live Chat',
            'Chat with our support team',
            'Available during business hours',
            () => _showComingSoon('Live chat functionality'),
          ),

          _buildContactMethod(
            Icons.location_on,
            'Visit Us',
            'Dubai, United Arab Emirates',
            'See our location on the map',
            () => _showComingSoon('Map integration'),
          ),

          const SizedBox(height: 32),

          // Contact Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send us a Message',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Your Email',
                    hintText: 'Enter your email address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    hintText: 'What is this about?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    hintText: 'Tell us how we can help you...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                  ),
                  maxLines: 4,
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Send Message'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildComingSoonNote('Contact form integration with backend'),
        ],
      ),
    );
  }

  Widget _buildGuidesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Guides',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildGuideCard(
            'Getting Started',
            'Learn how to create an account and place your first order',
            Icons.rocket_launch,
            () => _showComingSoon('Getting started guide'),
          ),

          _buildGuideCard(
            'Placing Orders',
            'Step-by-step guide to ordering your favorite coffee',
            Icons.shopping_cart,
            () => _showComingSoon('Order placement guide'),
          ),

          _buildGuideCard(
            'Payment Methods',
            'Learn about available payment options and how to use them',
            Icons.payment,
            () => _showComingSoon('Payment methods guide'),
          ),

          _buildGuideCard(
            'Order Tracking',
            'How to track your order and estimated delivery times',
            Icons.track_changes,
            () => _showComingSoon('Order tracking guide'),
          ),

          _buildGuideCard(
            'Coffee Brewing Tips',
            'Expert tips for brewing the perfect cup at home',
            Icons.coffee,
            () => _showComingSoon('Brewing tips guide'),
          ),

          _buildGuideCard(
            'Troubleshooting',
            'Solutions to common issues and technical problems',
            Icons.build,
            () => _showComingSoon('Troubleshooting guide'),
          ),

          const SizedBox(height: 24),
          _buildComingSoonNote('Comprehensive user guides and video tutorials'),
        ],
      ),
    );
  }

  Widget _buildFAQSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(answer, style: TextStyle(color: AppTheme.textMedium)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethod(
    IconData icon,
    String title,
    String subtitle,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBrown.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBrown),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            Text(
              description,
              style: TextStyle(color: AppTheme.textLight, fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildGuideCard(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBrown.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBrown),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildComingSoonNote(String feature) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLightBrown.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryLightBrown),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryBrown, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'TODO: $feature',
              style: TextStyle(
                color: AppTheme.textMedium,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    // Note: Implement message sending functionality
    if (_emailController.text.isEmpty ||
        _subjectController.text.isEmpty ||
        _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Message sent successfully! We\'ll get back to you soon.',
        ),
        backgroundColor: Colors.green,
      ),
    );

    // Clear form
    _emailController.clear();
    _subjectController.clear();
    _messageController.clear();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature - Coming Soon')));
  }
}
