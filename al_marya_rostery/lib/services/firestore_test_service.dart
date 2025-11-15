import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Test utility to verify Firestore configuration and connectivity
class FirestoreTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Comprehensive test of Firestore connectivity and permissions
  static Future<Map<String, dynamic>> runConnectivityTest() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <String, dynamic>{},
      'overall_status': 'unknown',
      'recommendations': <String>[],
    };

    try {
      // Test 1: Firestore Instance
      debugPrint('🔍 Testing Firestore instance...');
      final firestore = FirebaseFirestore.instance;
      results['tests']['firestore_instance'] = {
        'status': 'success',
        'message': 'Firestore instance created successfully',
      };
      debugPrint('✅ Firestore instance: OK');

      // Test 2: Authentication Status
      debugPrint('🔍 Testing authentication...');
      final user = _auth.currentUser;
      if (user != null) {
        results['tests']['authentication'] = {
          'status': 'success',
          'message': 'User authenticated',
          'user_id': user.uid,
          'email': user.email,
        };
        debugPrint('✅ Authentication: OK (${user.uid})');
      } else {
        results['tests']['authentication'] = {
          'status': 'warning',
          'message': 'No user currently authenticated',
        };
        results['recommendations'].add(
          'Sign in a user to test user-specific features',
        );
        debugPrint('⚠️ Authentication: No user signed in');
      }

      // Test 3: Basic Firestore Write (public test collection)
      debugPrint('🔍 Testing Firestore write permissions...');
      try {
        await firestore.collection('test_connectivity').doc('app_test').set({
          'timestamp': FieldValue.serverTimestamp(),
          'test_type': 'connectivity',
          'app_version': '1.0.0',
          'platform': defaultTargetPlatform.toString(),
        });

        results['tests']['firestore_write'] = {
          'status': 'success',
          'message': 'Firestore write successful',
        };
        debugPrint('✅ Firestore write: OK');
      } catch (e) {
        results['tests']['firestore_write'] = {
          'status': 'error',
          'message': 'Firestore write failed: $e',
        };
        results['recommendations'].add('Check Firestore security rules');
        debugPrint('❌ Firestore write: FAILED - $e');
      }

      // Test 4: Basic Firestore Read
      debugPrint('🔍 Testing Firestore read permissions...');
      try {
        final doc = await firestore
            .collection('test_connectivity')
            .doc('app_test')
            .get();
        if (doc.exists) {
          results['tests']['firestore_read'] = {
            'status': 'success',
            'message': 'Firestore read successful',
            'data_received': doc.data() != null,
          };
          debugPrint('✅ Firestore read: OK');
        } else {
          results['tests']['firestore_read'] = {
            'status': 'warning',
            'message': 'Document does not exist',
          };
          debugPrint('⚠️ Firestore read: Document not found');
        }
      } catch (e) {
        results['tests']['firestore_read'] = {
          'status': 'error',
          'message': 'Firestore read failed: $e',
        };
        results['recommendations'].add(
          'Check Firestore security rules and network connectivity',
        );
        debugPrint('❌ Firestore read: FAILED - $e');
      }

      // Test 5: User-specific Operations (if authenticated)
      if (user != null) {
        debugPrint('🔍 Testing user-specific Firestore operations...');
        try {
          // Test user document access
          final userDoc = firestore.collection('users').doc(user.uid);
          await userDoc.set({
            'test_timestamp': FieldValue.serverTimestamp(),
            'rewardPoints': 0,
          }, SetOptions(merge: true));

          final userData = await userDoc.get();
          if (userData.exists) {
            results['tests']['user_operations'] = {
              'status': 'success',
              'message': 'User-specific operations successful',
              'user_data_exists': true,
            };
            debugPrint('✅ User operations: OK');
          }
        } catch (e) {
          results['tests']['user_operations'] = {
            'status': 'error',
            'message': 'User operations failed: $e',
          };
          results['recommendations'].add(
            'Check user-specific Firestore security rules',
          );
          debugPrint('❌ User operations: FAILED - $e');
        }

        // Test 6: Reward System Compatibility
        debugPrint('🔍 Testing reward system compatibility...');
        try {
          final transactionDoc = firestore
              .collection('transactions')
              .doc('test_${user.uid}');
          await transactionDoc.set({
            'userId': user.uid,
            'type': 'test',
            'amount': 0.0,
            'pointsEarned': 0,
            'pointsUsed': 0,
            'timestamp': FieldValue.serverTimestamp(),
            'description': 'Connectivity test transaction',
          });

          results['tests']['reward_system'] = {
            'status': 'success',
            'message': 'Reward system compatibility confirmed',
          };
          debugPrint('✅ Reward system: OK');

          // Clean up test transaction
          await transactionDoc.delete();
        } catch (e) {
          results['tests']['reward_system'] = {
            'status': 'error',
            'message': 'Reward system test failed: $e',
          };
          results['recommendations'].add(
            'Check transaction collection security rules',
          );
          debugPrint('❌ Reward system: FAILED - $e');
        }
      }

      // Clean up test document
      try {
        await firestore
            .collection('test_connectivity')
            .doc('app_test')
            .delete();
        debugPrint('🧹 Cleanup: Test documents removed');
      } catch (e) {
        debugPrint('⚠️ Cleanup: Could not remove test documents - $e');
      }

      // Determine overall status
      final errorCount = results['tests'].values
          .where((test) => test['status'] == 'error')
          .length;
      final warningCount = results['tests'].values
          .where((test) => test['status'] == 'warning')
          .length;

      if (errorCount == 0 && warningCount == 0) {
        results['overall_status'] = 'excellent';
        results['summary'] =
            'All tests passed! Firestore is fully configured and ready.';
      } else if (errorCount == 0) {
        results['overall_status'] = 'good';
        results['summary'] =
            'Core functionality working. Minor issues detected.';
      } else if (errorCount <= 2) {
        results['overall_status'] = 'partial';
        results['summary'] =
            'Some functionality working. Configuration needed.';
      } else {
        results['overall_status'] = 'poor';
        results['summary'] =
            'Major issues detected. Check Firebase configuration.';
      }

      debugPrint('\n📊 FIRESTORE CONNECTIVITY TEST COMPLETE');
      debugPrint(
        'Status: ${results['overall_status'].toString().toUpperCase()}',
      );
      debugPrint('Summary: ${results['summary']}');

      if (results['recommendations'].isNotEmpty) {
        debugPrint('\n💡 Recommendations:');
        for (String rec in results['recommendations']) {
          debugPrint('   • $rec');
        }
      }
    } catch (e) {
      results['tests']['general_error'] = {
        'status': 'error',
        'message': 'General test failure: $e',
      };
      results['overall_status'] = 'failed';
      results['summary'] = 'Test execution failed due to system error.';
      debugPrint('💥 CRITICAL ERROR: $e');
    }

    return results;
  }

  /// Quick test for immediate feedback
  static Future<bool> quickConnectivityCheck() async {
    try {
      debugPrint('🚀 Quick Firestore connectivity check...');

      // Simple ping test
      await _firestore.collection('ping').doc('test').set({
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('ping').doc('test').delete();

      debugPrint('✅ Firestore: Connected and working');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore: Connection failed - $e');
      return false;
    }
  }

  /// Test reward service compatibility specifically
  static Future<bool> testRewardServiceCompatibility() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ Cannot test reward service: No authenticated user');
        return false;
      }

      debugPrint('🎯 Testing reward service compatibility...');

      // Test user rewards initialization
      await _firestore.collection('users').doc(user.uid).set({
        'rewardPoints': 0,
        'testMode': true,
        'lastTested': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Test transaction creation
      await _firestore
          .collection('transactions')
          .doc('test_${DateTime.now().millisecondsSinceEpoch}')
          .set({
            'userId': user.uid,
            'type': 'test',
            'amount': 1.0,
            'pointsEarned': 1,
            'pointsUsed': 0,
            'timestamp': FieldValue.serverTimestamp(),
            'description': 'Reward system compatibility test',
          });

      debugPrint('✅ Reward service: Compatible and ready');
      return true;
    } catch (e) {
      debugPrint('❌ Reward service: Compatibility test failed - $e');
      return false;
    }
  }
}
