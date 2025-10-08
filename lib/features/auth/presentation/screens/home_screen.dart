import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qahwat_al_emarat/core/config/app_config.dart';
import 'package:qahwat_al_emarat/features/auth/providers/auth_provider.dart';
import 'package:qahwat_al_emarat/features/auth/presentation/widgets/auth_menu_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qahwat'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  await AuthMenuWidget.handlePopupMenuAction(
                    value,
                    context,
                    authProvider,
                  );
                },
                itemBuilder: (context) =>
                    AuthMenuWidget.getPopupMenuItems(authProvider),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Message
                Text(
                  'Welcome back, ${user?.name ?? 'Guest'}!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppConfig.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Enjoy your premium coffee experience',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppConfig.textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),

                // User Info Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppConfig.primaryColor,
                              backgroundImage: user?.avatar != null
                                  ? NetworkImage(user!.avatar!)
                                  : null,
                              child: user?.avatar == null
                                  ? Text(
                                      (user?.name?.isNotEmpty == true
                                          ? user!.name!
                                                .substring(0, 1)
                                                .toUpperCase()
                                          : 'G'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'Guest User',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.email ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppConfig.textColor
                                              .withOpacity(0.7),
                                        ),
                                  ),
                                  if (user?.phone != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      user!.phone!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppConfig.textColor
                                                .withOpacity(0.7),
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // User Status
                        Row(
                          children: [
                            Icon(
                              user?.isEmailVerified ?? false
                                  ? Icons.verified
                                  : Icons.warning,
                              color: user?.isEmailVerified ?? false
                                  ? Colors.green
                                  : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              user?.isEmailVerified ?? false
                                  ? 'Email Verified'
                                  : 'Email Not Verified',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: user?.isEmailVerified ?? false
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                            ),
                          ],
                        ),

                        if (user?.roles != null && user!.roles.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: user.roles
                                .map(
                                  (role) => Chip(
                                    label: Text(role),
                                    backgroundColor: AppConfig.secondaryColor
                                        .withOpacity(0.1),
                                    labelStyle: TextStyle(
                                      color: AppConfig.secondaryColor,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildActionCard(context, 'Order Coffee', Icons.coffee, () {
                      Navigator.of(context).pushNamed('/coffee');
                    }),
                    _buildActionCard(context, 'My Orders', Icons.receipt, () {
                      Navigator.of(context).pushNamed('/orders');
                    }),
                    _buildActionCard(context, 'Favorites', Icons.favorite, () {
                      Navigator.of(context).pushNamed('/favorites');
                    }),
                    _buildActionCard(context, 'Settings', Icons.settings, () {
                      Navigator.of(context).pushNamed('/settings');
                    }),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppConfig.primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
