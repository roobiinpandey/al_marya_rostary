import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../dialogs/user_detail_dialog.dart';
import '../../../../data/models/user_model.dart';

/// Admin Users Page
/// Manages users/customers with full CRUD operations
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({Key? key}) : super(key: key);

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<UserProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () => context.read<UserProvider>().refresh(),
        child: Column(
          children: [
            _buildStatistics(),
            _buildFilters(),
            Expanded(child: _buildUserList()),
          ],
        ),
      ),
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('User Management'),
      backgroundColor: const Color(0xFF6D4C3D),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<UserProvider>().refresh(),
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
          tooltip: 'Advanced Filters',
        ),
      ],
    );
  }

  // ==================== STATISTICS ====================

  Widget _buildStatistics() {
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        final stats = provider.statistics;

        return Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard(
                  'Total Users',
                  stats['total']?.toString() ?? '0',
                  Colors.blue,
                  Icons.people,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Active',
                  stats['active']?.toString() ?? '0',
                  Colors.green,
                  Icons.check_circle,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Verified',
                  stats['verified']?.toString() ?? '0',
                  Colors.teal,
                  Icons.verified_user,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Admins',
                  stats['admins']?.toString() ?? '0',
                  Colors.purple,
                  Icons.admin_panel_settings,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== FILTERS ====================

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildSearchBar()),
          const SizedBox(width: 12),
          _buildRoleFilter(),
          const SizedBox(width: 12),
          _buildStatusFilter(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by name, email, or phone...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  context.read<UserProvider>().setSearchQuery('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        context.read<UserProvider>().setSearchQuery(value);
      },
    );
  }

  Widget _buildRoleFilter() {
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String?>(
            value: provider.roleFilter,
            hint: const Text('Role'),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: null, child: Text('All Roles')),
              DropdownMenuItem(value: 'customer', child: Text('Customer')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (value) {
              provider.setRoleFilter(value);
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusFilter() {
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<bool?>(
            value: provider.activeFilter,
            hint: const Text('Status'),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: null, child: Text('All Status')),
              DropdownMenuItem(value: true, child: Text('Active')),
              DropdownMenuItem(value: false, child: Text('Inactive')),
            ],
            onChanged: (value) {
              provider.setActiveFilter(value);
            },
          ),
        );
      },
    );
  }

  // ==================== USER LIST ====================

  Widget _buildUserList() {
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.filteredUsers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && provider.filteredUsers.isEmpty) {
          return _buildErrorState(provider.errorMessage!);
        }

        if (provider.filteredUsers.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: provider.filteredUsers.length + (provider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.filteredUsers.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final user = provider.filteredUsers[index];
            return _buildUserCard(user);
          },
        );
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showUserDetails(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF6D4C3D),
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (user.isAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  _buildStatusBadge(user.accountStatus, user.statusColor),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // User Info Row
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.shopping_bag,
                      '${user.statistics.totalOrders} Orders',
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.attach_money,
                      user.statistics.formattedTotalSpent,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.star,
                      '${user.loyaltyProgram.points} pts',
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.military_tech,
                      user.loyaltyProgram.tier,
                      _getTierColor(user.loyaltyProgram.tier),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (user.phone != null)
                    Text(
                      user.phone!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  const Spacer(),
                  _buildActionButton(
                    Icons.visibility,
                    Colors.blue,
                    () => _showUserDetails(user),
                    'View',
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    user.isActive ? Icons.block : Icons.check_circle,
                    user.isActive ? Colors.orange : Colors.green,
                    () => _toggleActive(user),
                    user.isActive ? 'Deactivate' : 'Activate',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, String colorName) {
    Color color;
    switch (colorName) {
      case 'green':
        color = Colors.green;
        break;
      case 'orange':
        color = Colors.orange;
        break;
      case 'red':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionButton(
    IconData icon,
    Color color,
    VoidCallback onPressed,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  // ==================== EMPTY & ERROR STATES ====================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading users',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<UserProvider>().refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6D4C3D),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DIALOG ACTIONS ====================

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => UserDetailDialog(user: user),
    );
  }

  void _showFilterDialog() {
    // Note: Implement advanced filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Advanced filters coming soon')),
    );
  }

  void _toggleActive(UserModel user) async {
    final provider = context.read<UserProvider>();
    final success = await provider.toggleActiveStatus(user.id, !user.isActive);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'User ${user.isActive ? 'deactivated' : 'activated'}'
                : 'Failed to update status',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
