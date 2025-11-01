// Debug Firebase Token Extractor
// Add this temporary code to your Flutter app's main.dart or any screen after user login

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FirebaseTokenDebugger extends StatefulWidget {
  @override
  _FirebaseTokenDebuggerState createState() => _FirebaseTokenDebuggerState();
}

class _FirebaseTokenDebuggerState extends State<FirebaseTokenDebugger> {
  String? _firebaseToken;
  String? _userEmail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email;
      });
    }
  }

  Future<void> _extractFirebaseToken() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showSnackBar('No user is currently signed in');
        return;
      }

      // Get fresh Firebase ID token
      final token = await user.getIdToken(true); // Force refresh

      if (token == null || token.isEmpty) {
        _showSnackBar('❌ Failed to get Firebase token');
        return;
      }

      setState(() {
        _firebaseToken = token;
        _userEmail = user.email;
      });

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: token));

      _showSnackBar('✅ Firebase token copied to clipboard!');

      // Print to console for debugging
      print('🔥 FIREBASE TOKEN EXTRACTED:');
      print('   User Email: ${user.email}');
      print('   User UID: ${user.uid}');
      print('   Token Length: ${token.length}');
      print('   Token: $token');
      print('');
      print('🧪 TEST WITH CURL:');
      print('curl -X POST http://localhost:3001/test-firebase-token \\');
      print('  -H "Content-Type: application/json" \\');
      print('  -H "Authorization: Bearer $token"');
      print('');
    } catch (e) {
      _showSnackBar('❌ Error extracting token: $e');
      print('❌ Error extracting Firebase token: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🔥 Firebase Token Debugger'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '👤 Current User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(_userEmail ?? 'No user signed in'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _extractFirebaseToken,
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.vpn_key),
              label: Text(
                _isLoading ? 'Extracting...' : 'Extract Firebase Token',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.all(16),
              ),
            ),

            SizedBox(height: 16),

            if (_firebaseToken != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔑 Firebase Token',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Length: ${_firebaseToken!.length} characters',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _firebaseToken!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '✅ Token copied to clipboard!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🧪 Test Instructions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('1. Token is copied to clipboard'),
                      Text('2. Open Terminal on your computer'),
                      Text('3. Run the curl command printed in console'),
                      Text('4. Check if backend accepts the token'),
                    ],
                  ),
                ),
              ),
            ],

            Spacer(),

            Text(
              '💡 This screen helps debug Firebase authentication issues',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Add this to your app's main navigation or profile screen temporarily:
// 
// FloatingActionButton(
//   onPressed: () {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => FirebaseTokenDebugger()),
//     );
//   },
//   child: Icon(Icons.bug_report),
//   tooltip: 'Debug Firebase Token',
// )
