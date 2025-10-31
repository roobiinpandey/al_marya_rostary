import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class RewardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Constants for reward calculations
  static const double pointsPerAed = 1.0; // 1 point per AED 1 spent
  static const double aedPerPoint = 0.05; // 1 point = AED 0.05 when redeemed

  // Get current user's reward points
  static Future<int> getUserRewardPoints() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return 0;

      final data = doc.data();
      return (data?['rewardPoints'] as int?) ?? 0;
    } catch (e) {
      print('Error getting reward points: $e');
      return 0;
    }
  }

  // Calculate points earned for a purchase
  static int calculatePointsEarned(double amountSpent) {
    return (amountSpent * pointsPerAed).floor();
  }

  // Calculate discount amount from points
  static double calculateDiscountFromPoints(int points) {
    return points * aedPerPoint;
  }

  // Calculate maximum points that can be redeemed (shouldn't exceed total amount)
  static int getMaxRedeemablePoints(double totalAmount, int availablePoints) {
    final maxPointsByAmount = (totalAmount / aedPerPoint).floor();
    return availablePoints < maxPointsByAmount
        ? availablePoints
        : maxPointsByAmount;
  }

  // Earn points (after purchase)
  static Future<bool> earnPoints({
    required double amountSpent,
    required String transactionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final pointsEarned = calculatePointsEarned(amountSpent);
      if (pointsEarned <= 0) return true; // No points to earn

      await _firestore.runTransaction((transaction) async {
        // Update user's reward points
        final userRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await transaction.get(userRef);

        final currentPoints = (userDoc.data()?['rewardPoints'] as int?) ?? 0;
        final newPoints = currentPoints + pointsEarned;

        transaction.update(userRef, {'rewardPoints': newPoints});

        // Record transaction
        final transactionRef = _firestore.collection('transactions').doc();
        transaction.set(transactionRef, {
          'userId': user.uid,
          'transactionId': transactionId,
          'type': 'earn',
          'amount': amountSpent,
          'pointsEarned': pointsEarned,
          'pointsUsed': 0,
          'timestamp': FieldValue.serverTimestamp(),
          'description': 'Points earned from purchase',
        });
      });

      return true;
    } catch (e) {
      print('Error earning points: $e');
      return false;
    }
  }

  // Redeem points (during checkout)
  static Future<bool> redeemPoints({
    required int pointsToRedeem,
    required double totalAmount,
    required String transactionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      if (pointsToRedeem <= 0) return true; // No points to redeem

      // Validate redemption
      final currentPoints = await getUserRewardPoints();
      if (currentPoints < pointsToRedeem) {
        throw Exception(
          'Insufficient points. Available: $currentPoints, Required: $pointsToRedeem',
        );
      }

      final maxRedeemable = getMaxRedeemablePoints(totalAmount, currentPoints);
      if (pointsToRedeem > maxRedeemable) {
        throw Exception(
          'Cannot redeem more than AED ${totalAmount.toStringAsFixed(2)} worth of points',
        );
      }

      await _firestore.runTransaction((transaction) async {
        // Update user's reward points
        final userRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await transaction.get(userRef);

        final currentPoints = (userDoc.data()?['rewardPoints'] as int?) ?? 0;
        if (currentPoints < pointsToRedeem) {
          throw Exception('Insufficient points');
        }

        final newPoints = currentPoints - pointsToRedeem;
        transaction.update(userRef, {'rewardPoints': newPoints});

        // Record transaction
        final transactionRef = _firestore.collection('transactions').doc();
        transaction.set(transactionRef, {
          'userId': user.uid,
          'transactionId': transactionId,
          'type': 'redeem',
          'amount': totalAmount,
          'pointsEarned': 0,
          'pointsUsed': pointsToRedeem,
          'discountAmount': calculateDiscountFromPoints(pointsToRedeem),
          'timestamp': FieldValue.serverTimestamp(),
          'description': 'Points redeemed during checkout',
        });
      });

      return true;
    } catch (e) {
      print('Error redeeming points: $e');
      return false;
    }
  }

  // Process complete transaction (redeem + earn in one go)
  static Future<Map<String, dynamic>> processTransaction({
    required double originalAmount,
    required int pointsToRedeem,
    required String transactionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final discountAmount = calculateDiscountFromPoints(pointsToRedeem);
      final finalAmount = originalAmount - discountAmount;
      final pointsEarned = calculatePointsEarned(finalAmount);

      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await transaction.get(userRef);

        final currentPoints = (userDoc.data()?['rewardPoints'] as int?) ?? 0;

        // Validate redemption
        if (pointsToRedeem > 0 && currentPoints < pointsToRedeem) {
          throw Exception('Insufficient points');
        }

        // Calculate final points balance
        final finalPoints = currentPoints - pointsToRedeem + pointsEarned;
        transaction.update(userRef, {'rewardPoints': finalPoints});

        // Record transaction
        final transactionRef = _firestore.collection('transactions').doc();
        transaction.set(transactionRef, {
          'userId': user.uid,
          'transactionId': transactionId,
          'type': 'purchase',
          'amount': originalAmount,
          'finalAmount': finalAmount,
          'pointsEarned': pointsEarned,
          'pointsUsed': pointsToRedeem,
          'discountAmount': discountAmount,
          'timestamp': FieldValue.serverTimestamp(),
          'description': 'Complete purchase transaction',
        });
      });

      return {
        'success': true,
        'originalAmount': originalAmount,
        'discountAmount': discountAmount,
        'finalAmount': finalAmount,
        'pointsUsed': pointsToRedeem,
        'pointsEarned': pointsEarned,
      };
    } catch (e) {
      print('Error processing transaction: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get user's transaction history
  static Future<List<Map<String, dynamic>>> getTransactionHistory({
    int limit = 50,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final query = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting transaction history: $e');
      return [];
    }
  }

  // Initialize user rewards (call when user signs up)
  static Future<bool> initializeUserRewards(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'rewardPoints': 0,
      });
      return true;
    } catch (e) {
      print('Error initializing user rewards: $e');
      return false;
    }
  }

  // Get reward summary for display
  static Future<Map<String, dynamic>> getRewardSummary() async {
    try {
      final points = await getUserRewardPoints();
      final cashValue = calculateDiscountFromPoints(points);

      return {
        'points': points,
        'cashValue': cashValue,
        'formattedCashValue': 'AED ${cashValue.toStringAsFixed(2)}',
      };
    } catch (e) {
      print('Error getting reward summary: $e');
      return {'points': 0, 'cashValue': 0.0, 'formattedCashValue': 'AED 0.00'};
    }
  }

  // ====== QR CODE FUNCTIONALITY ======

  // Generate unique QR code data for user (PERMANENT - never changes)
  static String _generateQRCodeData(String uid) {
    // Create PERMANENT QR data structure (no timestamp or random data)
    // This ensures the QR code never changes for a customer
    final qrData = {
      'type': 'al_marya_customer',
      'uid': uid,
      'version': '1.0',
      // Using a hash of the UID for consistency but uniqueness
      'customerCode': _generateCustomerCode(uid),
    };

    // Encode as JSON string
    return jsonEncode(qrData);
  }

  // Generate consistent customer code from UID
  static String _generateCustomerCode(String uid) {
    // Create a consistent hash-based code from the UID
    // This will always be the same for the same UID
    int hash = 0;
    for (int i = 0; i < uid.length; i++) {
      hash = ((hash << 5) - hash + uid.codeUnitAt(i)) & 0xffffffff;
    }
    // Convert to positive number and create 6-digit code
    final code = (hash.abs() % 900000 + 100000).toString();
    return code;
  }

  // Ensure user has a QR code (create if doesn't exist)
  static Future<String> ensureUserHasQRCode() async {
    try {
      print('🔍 Starting QR code check...');
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        throw Exception('User not authenticated');
      }
      print('✅ User authenticated: ${user.uid}');

      print('📄 Checking existing QR code in Firestore...');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      print('📄 Document exists: ${userDoc.exists}');

      if (userDoc.exists && userDoc.data()?['qrCodeData'] != null) {
        // QR code already exists
        print('✅ QR code found in Firestore');
        return userDoc.data()!['qrCodeData'] as String;
      }

      // Generate new QR code
      print('🔧 Generating new QR code...');
      final qrCodeData = _generateQRCodeData(user.uid);
      print('✅ QR code generated: ${qrCodeData.length} characters');

      // Save to Firestore
      print('💾 Saving QR code to Firestore...');
      if (userDoc.exists) {
        // Update existing document
        await _firestore.collection('users').doc(user.uid).update({
          'qrCodeData': qrCodeData,
          'qrCodeGenerated': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new document
        await _firestore.collection('users').doc(user.uid).set({
          'qrCodeData': qrCodeData,
          'qrCodeGenerated': FieldValue.serverTimestamp(),
          'rewardPoints': 0,
        });
      }
      print('✅ QR code saved successfully');

      return qrCodeData;
    } catch (e) {
      print('❌ Error ensuring QR code: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Get user's QR code data
  static Future<String?> getUserQRCode() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      return userDoc.data()?['qrCodeData'] as String?;
    } catch (e) {
      print('Error getting user QR code: $e');
      return null;
    }
  }

  // Get existing QR code (DO NOT regenerate - QR codes are permanent)
  // NOTE: Function name is misleading but kept for backward compatibility
  // This function does NOT regenerate - it returns the existing permanent QR code
  static Future<String> regenerateQRCode() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // ⚠️  IMPORTANT: QR codes are PERMANENT and cannot be regenerated
      // This maintains customer loyalty system integrity
      print('⚠️  QR Code regeneration blocked - returning existing QR code');
      final existingQR = await getUserQRCode();

      if (existingQR != null) {
        print('✅ Returning existing permanent QR code');
        return existingQR;
      }

      // Only generate if no QR code exists (should not happen)
      print('🔧 No existing QR code found, creating new permanent one');
      return await ensureUserHasQRCode();
    } catch (e) {
      print('Error getting QR code: $e');
      rethrow;
    }
  }

  // Initialize QR code for new user (call during registration)
  static Future<String> initializeUserQRCode(String userId) async {
    try {
      final qrCodeData = _generateQRCodeData(userId);

      await _firestore.collection('users').doc(userId).update({
        'qrCodeData': qrCodeData,
        'qrCodeGenerated': FieldValue.serverTimestamp(),
        'rewardPoints': 0, // Also initialize reward points
      });

      return qrCodeData;
    } catch (e) {
      print('Error initializing QR code: $e');
      rethrow;
    }
  }

  // Validate QR code data format
  static bool isValidQRCode(String qrData) {
    try {
      final decoded = jsonDecode(qrData);
      return decoded['type'] == 'al_marya_customer' &&
          decoded['uid'] != null &&
          decoded['version'] != null;
    } catch (e) {
      return false;
    }
  }

  // Extract user ID from QR code data
  static String? extractUserIdFromQR(String qrData) {
    try {
      final decoded = jsonDecode(qrData);
      if (decoded['type'] == 'al_marya_customer') {
        return decoded['uid'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ====== MIGRATION FUNCTIONS ======

  // Generate QR codes for all existing users who don't have one
  static Future<void> migrateExistingUsersToQR() async {
    try {
      print('🔄 Starting QR code migration for existing users...');

      // Get all users from Firestore
      final usersSnapshot = await _firestore.collection('users').get();
      print('📊 Found ${usersSnapshot.docs.length} users in database');

      int usersWithoutQR = 0;
      int qrCodesCreated = 0;
      int errors = 0;

      for (final userDoc in usersSnapshot.docs) {
        try {
          final userData = userDoc.data();
          final userId = userDoc.id;

          // Check if user already has QR code
          if (userData['qrCodeData'] != null &&
              userData['qrCodeData'] is String) {
            print('✅ User $userId already has QR code');
            continue;
          }

          usersWithoutQR++;
          print('🔧 Creating QR code for user: $userId');

          // Generate QR code for this user
          final qrCodeData = _generateQRCodeData(userId);

          // Update user document with QR code
          await userDoc.reference.update({
            'qrCodeData': qrCodeData,
            'qrCodeGenerated': FieldValue.serverTimestamp(),
            'qrCodeMigrated': true, // Flag to track migration
          });

          qrCodesCreated++;
          print('✅ QR code created for user: $userId');
        } catch (e) {
          errors++;
          print('❌ Error creating QR code for user ${userDoc.id}: $e');
        }
      }

      print('🎉 QR Code Migration Complete!');
      print('📊 Summary:');
      print('  - Total users: ${usersSnapshot.docs.length}');
      print('  - Users without QR: $usersWithoutQR');
      print('  - QR codes created: $qrCodesCreated');
      print('  - Errors: $errors');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  // Generate QR code for a specific user by email/ID
  static Future<void> generateQRForUser(String userId) async {
    try {
      print('🔧 Generating QR code for specific user: $userId');

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found: $userId');
      }

      final qrCodeData = _generateQRCodeData(userId);

      await userDoc.reference.update({
        'qrCodeData': qrCodeData,
        'qrCodeGenerated': FieldValue.serverTimestamp(),
        'qrCodeManuallyGenerated': true,
      });

      print('✅ QR code generated successfully for user: $userId');
    } catch (e) {
      print('❌ Error generating QR for user $userId: $e');
      rethrow;
    }
  }
}
