import 'package:flutter/material.dart';
import '../services/firestore_test_service.dart';
import '../core/theme/app_theme.dart';

/// Debug widget for testing Firestore connectivity
/// Add this to your app during development to verify Firebase setup
class FirestoreTestWidget extends StatefulWidget {
  const FirestoreTestWidget({super.key});

  @override
  State<FirestoreTestWidget> createState() => _FirestoreTestWidgetState();
}

class _FirestoreTestWidgetState extends State<FirestoreTestWidget> {
  bool _isLoading = false;
  Map<String, dynamic>? _testResults;
  bool? _quickTestResult;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: AppTheme.primaryBrown),
                const SizedBox(width: 8),
                const Text(
                  'Firestore Debug Panel',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_quickTestResult != null)
                  Icon(
                    _quickTestResult! ? Icons.check_circle : Icons.error,
                    color: _quickTestResult! ? Colors.green : Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _runQuickTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBrown,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Testing...'),
                        ],
                      )
                    : const Text('Quick Connectivity Test'),
              ),
            ),

            const SizedBox(height: 8),

            // Full Test Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _runFullTest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryBrown,
                  side: const BorderSide(color: AppTheme.primaryBrown),
                ),
                child: const Text('Run Full Diagnostic'),
              ),
            ),

            // Test Results
            if (_testResults != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildTestResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    if (_testResults == null) return const SizedBox.shrink();

    final overallStatus = _testResults!['overall_status'] as String;
    final summary = _testResults!['summary'] as String;
    final tests = _testResults!['tests'] as Map<String, dynamic>;
    final recommendations = _testResults!['recommendations'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Status
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusColor(overallStatus).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getStatusColor(overallStatus)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getStatusIcon(overallStatus),
                    color: _getStatusColor(overallStatus),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ${overallStatus.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(overallStatus),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(summary),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Individual Tests
        const Text(
          'Test Results:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        ...tests.entries.map((entry) {
          final testName = entry.key;
          final testData = entry.value as Map<String, dynamic>;
          final status = testData['status'] as String;
          final message = testData['message'] as String;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTestName(testName),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        message,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        // Recommendations
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Recommendations:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...recommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _runQuickTest() async {
    setState(() {
      _isLoading = true;
      _quickTestResult = null;
    });

    try {
      final result = await FirestoreTestService.quickConnectivityCheck();
      setState(() {
        _quickTestResult = result;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result
                ? 'Firestore connected successfully!'
                : 'Firestore connection failed',
          ),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _quickTestResult = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _runFullTest() async {
    setState(() {
      _isLoading = true;
      _testResults = null;
    });

    try {
      final results = await FirestoreTestService.runConnectivityTest();
      setState(() {
        _testResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResults = {
          'overall_status': 'error',
          'summary': 'Test execution failed: $e',
          'tests': {},
          'recommendations': ['Check your Firebase configuration'],
        };
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'success':
      case 'excellent':
        return Colors.green;
      case 'warning':
      case 'good':
      case 'partial':
        return Colors.orange;
      case 'error':
      case 'poor':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'success':
      case 'excellent':
        return Icons.check_circle;
      case 'warning':
      case 'good':
      case 'partial':
        return Icons.warning;
      case 'error':
      case 'poor':
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _formatTestName(String testName) {
    return testName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
