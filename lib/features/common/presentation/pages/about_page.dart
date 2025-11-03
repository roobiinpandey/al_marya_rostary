import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// About Page - App information and company details
/// Note: Update with real company information and legal documents
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo and Name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBrown,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.coffee,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Al Marya Rostery',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Premium Arabic Coffee Experience',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMedium),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // About Section
            _buildSection(
              'About Al Marya Rostery',
              'Al Marya Rostery brings you the finest selection of premium Arabic coffee, carefully sourced from the best coffee regions in the Middle East and beyond. Our passion for coffee excellence drives us to deliver an authentic and memorable coffee experience right to your doorstep.\n\nFounded in Dubai, we combine traditional Arabic coffee culture with modern convenience, offering a curated selection of freshly roasted beans, traditional brewing methods, and expert craftsmanship in every cup.',
              Icons.info_outline,
            ),

            // Mission Section
            _buildSection(
              'Our Mission',
              'To preserve and share the rich heritage of Arabic coffee culture while providing exceptional quality and convenience to coffee lovers across the UAE. We are committed to supporting sustainable coffee farming practices and building lasting relationships with our customers and coffee communities.',
              Icons.flag,
            ),

            // Features Section
            _buildSection(
              'App Features',
              '• Browse our extensive collection of premium coffee\n• Customize your coffee preferences and brewing methods\n• Real-time order tracking and delivery updates\n• Secure payment options including cash on delivery\n• Guest checkout for quick and easy ordering\n• Order history and favorites for logged-in users\n• Multilingual support for Arabic and English\n• Expert brewing tips and coffee education',
              Icons.star,
            ),

            // Quality Section
            _buildSection(
              'Quality Commitment',
              'Every coffee bean is carefully selected and roasted to perfection by our master roasters. We source directly from farmers who share our commitment to quality and sustainability. Our rigorous quality control ensures that every cup meets our high standards and delivers the authentic taste of premium Arabic coffee.',
              Icons.verified,
            ),

            // Contact Information
            _buildContactCard(),

            // Legal and Credits
            _buildLegalSection(),

            const SizedBox(height: 24),
            _buildComingSoonNote(
              'Complete company information and legal documents',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primaryBrown, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: AppTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.contact_mail,
                  color: AppTheme.primaryBrown,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildContactRow(Icons.email, 'Email', 'info@almaryarostery.com'),
          _buildContactRow(Icons.phone, 'Phone', '+971 XX XXX XXXX'),
          _buildContactRow(
            Icons.support_agent,
            'Support',
            'support@almaryarostery.com',
          ),
          _buildContactRow(
            Icons.location_on,
            'Location',
            'Dubai, United Arab Emirates',
          ),
          _buildContactRow(
            Icons.schedule,
            'Business Hours',
            '6:00 AM - 10:00 PM (Daily)',
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBrown, size: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textMedium,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.gavel,
                  color: AppTheme.primaryBrown,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Legal & Credits',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildLegalLink('Terms of Service', () {}),
          _buildLegalLink('Privacy Policy', () {}),
          _buildLegalLink('Cookie Policy', () {}),
          _buildLegalLink('Refund Policy', () {}),
          _buildLegalLink('Licenses', () {}),

          const SizedBox(height: 16),

          Text(
            'Technologies Used',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.textMedium,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Flutter & Dart for mobile development\n• Node.js & Express for backend services\n• MongoDB for data storage\n• Firebase for authentication and analytics\n• Various open-source packages and libraries',
            style: TextStyle(color: AppTheme.textMedium, height: 1.5),
          ),

          const SizedBox(height: 16),

          Text(
            '© 2024 Al Marya Rostery. All rights reserved.',
            style: TextStyle(color: AppTheme.textLight, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.primaryBrown,
                decoration: TextDecoration.underline,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: AppTheme.primaryBrown,
            ),
          ],
        ),
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
}
