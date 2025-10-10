import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:qahwat_al_emarat/features/auth/presentation/providers/auth_provider.dart';

/// Debug page to help diagnose Firebase Auth issues
class AuthDebugPage extends StatefulWidget {
  const AuthDebugPage({super.key});

  @override
  State<AuthDebugPage> createState() => _AuthDebugPageState();
}

class _AuthDebugPageState extends State<AuthDebugPage> {
  firebase_auth.User? _firebaseUser;
  Map<String, dynamic> _debugInfo = {};

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    final firebaseAuth = firebase_auth.FirebaseAuth.instance;
    final currentUser = firebaseAuth.currentUser;

    setState(() {
      _firebaseUser = currentUser;
      _debugInfo = {
        'Firebase Auth State': {
          'Current User': currentUser?.uid ?? 'null',
          'Email': currentUser?.email ?? 'null',
          'Display Name': currentUser?.displayName ?? 'null',
          'Photo URL': currentUser?.photoURL ?? 'null',
          'Email Verified': currentUser?.emailVerified ?? false,
          'Is Anonymous': currentUser?.isAnonymous ?? false,
          'Created': currentUser?.metadata.creationTime?.toString() ?? 'null',
        },
      };
    });

    // Listen to auth state changes
    firebaseAuth.authStateChanges().listen((user) {
      setState(() {
        _firebaseUser = user;
        _debugInfo['Auth State Changed'] = {
          'User ID': user?.uid ?? 'null',
          'Email': user?.email ?? 'null',
          'Display Name': user?.displayName ?? 'null',
          'Timestamp': DateTime.now().toString(),
        };
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AuthProvider Status
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AuthProvider Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('State', authProvider.state.toString()),
                        _buildInfoRow(
                          'Is Authenticated',
                          authProvider.isAuthenticated.toString(),
                        ),
                        _buildInfoRow(
                          'Is Loading',
                          authProvider.isLoading.toString(),
                        ),
                        _buildInfoRow(
                          'Has Error',
                          authProvider.hasError.toString(),
                        ),
                        _buildInfoRow(
                          'Error Message',
                          authProvider.errorMessage ?? 'none',
                        ),
                        const SizedBox(height: 16),

                        if (authProvider.user != null) ...[
                          Text(
                            'User Data from AuthProvider',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('ID', authProvider.user!.id),
                          _buildInfoRow('Name', authProvider.user!.name),
                          _buildInfoRow('Email', authProvider.user!.email),
                          _buildInfoRow(
                            'Phone',
                            authProvider.user?.phone ?? 'null',
                          ),
                          _buildInfoRow(
                            'Avatar',
                            authProvider.user?.avatar ?? 'null',
                          ),
                          _buildInfoRow(
                            'Email Verified',
                            authProvider.user!.isEmailVerified.toString(),
                          ),
                          _buildInfoRow(
                            'Is Anonymous',
                            authProvider.user!.isAnonymous.toString(),
                          ),
                          _buildInfoRow(
                            'Roles',
                            authProvider.user!.roles.join(', '),
                          ),
                        ] else ...[
                          const Text('No user data in AuthProvider'),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Firebase Direct Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase Direct Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),

                    if (_firebaseUser != null) ...[
                      _buildInfoRow('Firebase User ID', _firebaseUser!.uid),
                      _buildInfoRow('Email', _firebaseUser!.email ?? 'null'),
                      _buildInfoRow(
                        'Display Name',
                        _firebaseUser!.displayName ?? 'null',
                      ),
                      _buildInfoRow(
                        'Photo URL',
                        _firebaseUser!.photoURL ?? 'null',
                      ),
                      _buildInfoRow(
                        'Email Verified',
                        _firebaseUser!.emailVerified.toString(),
                      ),
                      _buildInfoRow(
                        'Is Anonymous',
                        _firebaseUser!.isAnonymous.toString(),
                      ),
                    ] else ...[
                      const Text('No Firebase user found'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Debug Info
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debug Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _debugInfo.toString(),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Actions
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final authProvider = context.read<AuthProvider>();
                    await authProvider.signInWithGoogle();
                  },
                  child: const Text('Sign In with Google'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final authProvider = context.read<AuthProvider>();
                    await authProvider.logout();
                  },
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}
