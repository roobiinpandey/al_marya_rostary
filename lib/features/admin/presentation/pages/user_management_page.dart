import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_user_provider.dart';
import '../../data/models/admin_user_model.dart';
import '../widgets/user_data_table.dart';
import '../widgets/user_filters_widget.dart';
import '../widgets/user_stats_cards.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AdminUserProvider>(context, listen: false);
      provider.fetchUsers();
      provider.fetchUserStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AdminUserProvider>(
        builder: (context, userProvider, child) {
          return Column(
            children: [
              // Statistics Cards
              if (userProvider.userStats != null)
                UserStatsCards(stats: userProvider.userStats!),

              // Filters
              const UserFiltersWidget(),

              // Users Data Table
              Expanded(
                child: userProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : userProvider.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${userProvider.error}',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                userProvider.fetchUsers();
                                userProvider.fetchUserStatistics();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : userProvider.users.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const UserDataTable(),
              ),

              // Pagination
              if (userProvider.totalPages > 1) _buildPagination(userProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPagination(AdminUserProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${provider.currentPage} of ${provider.totalPages} (${provider.totalUsers} users)',
            style: const TextStyle(color: Colors.grey),
          ),
          Row(
            children: [
              IconButton(
                onPressed: provider.currentPage > 1
                    ? provider.previousPage
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              ...List.generate(
                (provider.totalPages > 5) ? 5 : provider.totalPages,
                (index) {
                  int pageNumber;
                  if (provider.totalPages <= 5) {
                    pageNumber = index + 1;
                  } else {
                    int start = (provider.currentPage - 2).clamp(
                      1,
                      provider.totalPages - 4,
                    );
                    pageNumber = start + index;
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: TextButton(
                      onPressed: () => provider.goToPage(pageNumber),
                      style: TextButton.styleFrom(
                        backgroundColor: pageNumber == provider.currentPage
                            ? Colors.brown[600]
                            : Colors.transparent,
                        foregroundColor: pageNumber == provider.currentPage
                            ? Colors.white
                            : Colors.brown[600],
                        minimumSize: const Size(40, 40),
                      ),
                      child: Text(pageNumber.toString()),
                    ),
                  );
                },
              ),
              IconButton(
                onPressed: provider.currentPage < provider.totalPages
                    ? provider.nextPage
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
