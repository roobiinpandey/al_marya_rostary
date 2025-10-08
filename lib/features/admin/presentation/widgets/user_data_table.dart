import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_user_provider.dart';
import '../../data/models/admin_user_model.dart';
import '../dialogs/user_edit_dialog.dart';
import '../dialogs/user_delete_dialog.dart';

class UserDataTable extends StatelessWidget {
  const UserDataTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminUserProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: MediaQuery.of(context).size.width,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
              dataRowHeight: 64,
              headingRowHeight: 56,
              columnSpacing: 24,
              horizontalMargin: 16,
              columns: const [
                DataColumn(
                  label: Text(
                    'User',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Role',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Last Login',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Created',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: provider.users
                  .map((user) => _buildDataRow(context, user, provider))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(
    BuildContext context,
    AdminUser user,
    AdminUserProvider provider,
  ) {
    return DataRow(
      cells: [
        // User Info Cell
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.brown[100],
                backgroundImage: user.avatar != null
                    ? NetworkImage(user.avatar!)
                    : null,
                child: user.avatar == null
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Colors.brown[600],
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.phone != null)
                      Text(
                        user.phone!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Email Cell
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.email,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
              if (!user.isEmailVerified)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Unverified',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Role Cell
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: user.isAdmin ? Colors.purple[100] : Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.roleDisplay,
              style: TextStyle(
                color: user.isAdmin ? Colors.purple[700] : Colors.blue[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Status Cell
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: user.isActive ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: user.isActive ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  user.statusDisplay,
                  style: TextStyle(
                    color: user.isActive ? Colors.green[700] : Colors.red[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Last Login Cell
        DataCell(
          Text(
            user.lastLogin != null ? _formatDate(user.lastLogin!) : 'Never',
            style: TextStyle(
              fontSize: 12,
              color: user.lastLogin != null ? Colors.black87 : Colors.grey[500],
            ),
          ),
        ),

        // Created Cell
        DataCell(
          Text(
            _formatDate(user.createdAt),
            style: const TextStyle(fontSize: 12),
          ),
        ),

        // Actions Cell
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit Button
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _showEditDialog(context, user, provider),
                tooltip: 'Edit User',
                color: Colors.blue[600],
              ),

              // Toggle Status Button
              IconButton(
                icon: Icon(
                  user.isActive ? Icons.toggle_on : Icons.toggle_off,
                  size: 20,
                ),
                onPressed: () => _toggleUserStatus(context, user, provider),
                tooltip: user.isActive ? 'Deactivate' : 'Activate',
                color: user.isActive ? Colors.green[600] : Colors.grey[600],
              ),

              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                onPressed: () => _showDeleteDialog(context, user, provider),
                tooltip: 'Delete User',
                color: Colors.red[600],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditDialog(
    BuildContext context,
    AdminUser user,
    AdminUserProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => UserEditDialog(user: user),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    AdminUser user,
    AdminUserProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => UserDeleteDialog(user: user),
    );
  }

  void _toggleUserStatus(
    BuildContext context,
    AdminUser user,
    AdminUserProvider provider,
  ) async {
    final success = await provider.toggleUserStatus(user.id, !user.isActive);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'User ${user.isActive ? 'deactivated' : 'activated'} successfully'
                : 'Failed to update user status',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
