import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

/// Debug widget to test backend connection
class BackendConnectionTest extends StatefulWidget {
  const BackendConnectionTest({super.key});

  @override
  State<BackendConnectionTest> createState() => _BackendConnectionTestState();
}

class _BackendConnectionTestState extends State<BackendConnectionTest> {
  String _connectionStatus = 'Testing...';
  Color _statusColor = Colors.orange;
  List<Map<String, dynamic>> _testResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _runConnectionTests();
  }

  Future<void> _runConnectionTests() async {
    setState(() {
      _isLoading = true;
      _testResults.clear();
    });

    final dio = Dio();
    final baseUrl = AppConstants.baseUrl;

    // Test endpoints
    final endpoints = [
      {'name': 'Health Check', 'url': '$baseUrl/health'},
      {'name': 'Sliders API', 'url': '$baseUrl/api/sliders'},
      {'name': 'Products API', 'url': '$baseUrl/api/coffees'},
      {'name': 'Categories API', 'url': '$baseUrl/api/categories'},
    ];

    for (final endpoint in endpoints) {
      try {
        final stopwatch = Stopwatch()..start();
        final response = await dio.get(
          endpoint['url']!,
          options: Options(
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
        stopwatch.stop();

        _testResults.add({
          'name': endpoint['name'],
          'url': endpoint['url'],
          'status': 'SUCCESS',
          'statusCode': response.statusCode,
          'responseTime': '${stopwatch.elapsedMilliseconds}ms',
          'dataReceived': response.data != null,
          'color': Colors.green,
        });
      } catch (e) {
        _testResults.add({
          'name': endpoint['name'],
          'url': endpoint['url'],
          'status': 'FAILED',
          'error': e.toString(),
          'color': Colors.red,
        });
      }
    }

    // Overall status
    final successCount = _testResults
        .where((r) => r['status'] == 'SUCCESS')
        .length;
    final totalTests = _testResults.length;

    setState(() {
      _isLoading = false;
      if (successCount == totalTests) {
        _connectionStatus = '✅ All connections successful!';
        _statusColor = Colors.green;
      } else if (successCount > 0) {
        _connectionStatus =
            '⚠️ Partial connectivity ($successCount/$totalTests working)';
        _statusColor = Colors.orange;
      } else {
        _connectionStatus = '❌ Backend not accessible';
        _statusColor = Colors.red;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Connection Test'),
        actions: [
          IconButton(
            onPressed: _runConnectionTests,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Status
            Card(
              color: _statusColor.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _connectionStatus,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Backend URL: ${AppConstants.baseUrl}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Environment: ${AppConstants.environment}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Results
            Text('Test Results', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _testResults.length,
                  itemBuilder: (context, index) {
                    final result = _testResults[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          result['status'] == 'SUCCESS'
                              ? Icons.check_circle
                              : Icons.error,
                          color: result['color'],
                        ),
                        title: Text(result['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(result['url']),
                            if (result['status'] == 'SUCCESS') ...[
                              Text(
                                'Status: ${result['statusCode']} • ${result['responseTime']}',
                              ),
                              Text('Data received: ${result['dataReceived']}'),
                            ] else ...[
                              Text(
                                'Error: ${result['error']}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),

            // Instructions
            Card(
              color: Colors.blue.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Troubleshooting',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Make sure backend server is running'),
                    const Text('2. Check if port 5001 is accessible'),
                    const Text('3. Verify network connectivity'),
                    const Text('4. Check app constants configuration'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
