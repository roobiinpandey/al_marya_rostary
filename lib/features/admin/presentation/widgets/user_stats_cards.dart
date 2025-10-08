import 'package:flutter/material.dart';
import '../../data/models/user_statistics_model.dart';

class UserStatsCards extends StatelessWidget {
  final UserStatistics stats;

  const UserStatsCards({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: _getCrossAxisCount(context),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.5,
        children: [
          _buildStatCard(
            title: 'Total Users',
            value: stats.totalUsers.toString(),
            icon: Icons.people,
            color: Colors.blue,
          ),
          _buildStatCard(
            title: 'Active Users',
            value: stats.activeUsers.toString(),
            icon: Icons.check_circle,
            color: Colors.green,
            subtitle: '${stats.activeUserPercentage.toStringAsFixed(1)}%',
          ),
          _buildStatCard(
            title: 'Inactive Users',
            value: stats.inactiveUsers.toString(),
            icon: Icons.person_off,
            color: Colors.orange,
            subtitle: '${stats.inactiveUserPercentage.toStringAsFixed(1)}%',
          ),
          _buildStatCard(
            title: 'New Today',
            value: stats.newUsersToday.toString(),
            icon: Icons.today,
            color: Colors.purple,
          ),
          _buildStatCard(
            title: 'New This Week',
            value: stats.newUsersThisWeek.toString(),
            icon: Icons.date_range,
            color: Colors.teal,
          ),
          _buildStatCard(
            title: 'New This Month',
            value: stats.newUsersThisMonth.toString(),
            icon: Icons.calendar_month,
            color: Colors.indigo,
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
