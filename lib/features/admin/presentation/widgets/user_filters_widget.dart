import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_user_provider.dart';

class UserFiltersWidget extends StatefulWidget {
  const UserFiltersWidget({Key? key}) : super(key: key);

  @override
  State<UserFiltersWidget> createState() => _UserFiltersWidgetState();
}

class _UserFiltersWidgetState extends State<UserFiltersWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AdminUserProvider>(context, listen: false);
    _searchController.text = provider.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminUserProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search and Filters Row
              Row(
                children: [
                  // Search Field
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search users by name or email...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.searchUsers('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (value) {
                        provider.searchUsers(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Role Filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: provider.selectedRole.isEmpty
                          ? null
                          : provider.selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('All Roles')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(
                          value: 'customer',
                          child: Text('Customer'),
                        ),
                      ],
                      onChanged: (value) {
                        provider.filterByRole(value ?? '');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Status Filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: provider.selectedStatus.isEmpty
                          ? null
                          : provider.selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('All Status')),
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'inactive',
                          child: Text('Inactive'),
                        ),
                      ],
                      onChanged: (value) {
                        provider.filterByStatus(value ?? '');
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action Buttons Row
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      provider.searchUsers(_searchController.text);
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),

                  OutlinedButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      provider.clearFilters();
                      provider.fetchUsers();
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Filters'),
                  ),
                  const SizedBox(width: 8),

                  OutlinedButton.icon(
                    onPressed: () {
                      provider.fetchUsers();
                      provider.fetchUserStatistics();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),

                  const Spacer(),

                  // Bulk Actions (can be enabled when implementing selection)
                  ElevatedButton.icon(
                    onPressed: null, // Will be implemented later
                    icon: const Icon(Icons.edit),
                    label: const Text('Bulk Actions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                    ),
                  ),
                ],
              ),

              // Active Filters Display
              if (provider.searchQuery.isNotEmpty ||
                  provider.selectedRole.isNotEmpty ||
                  provider.selectedStatus.isNotEmpty)
                _buildActiveFilters(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveFilters(AdminUserProvider provider) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          const Text(
            'Active filters:',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
          ),

          if (provider.searchQuery.isNotEmpty)
            Chip(
              label: Text('Search: "${provider.searchQuery}"'),
              onDeleted: () {
                _searchController.clear();
                provider.searchUsers('');
              },
              deleteIcon: const Icon(Icons.close, size: 16),
            ),

          if (provider.selectedRole.isNotEmpty)
            Chip(
              label: Text('Role: ${provider.selectedRole}'),
              onDeleted: () => provider.filterByRole(''),
              deleteIcon: const Icon(Icons.close, size: 16),
            ),

          if (provider.selectedStatus.isNotEmpty)
            Chip(
              label: Text('Status: ${provider.selectedStatus}'),
              onDeleted: () => provider.filterByStatus(''),
              deleteIcon: const Icon(Icons.close, size: 16),
            ),
        ],
      ),
    );
  }
}
