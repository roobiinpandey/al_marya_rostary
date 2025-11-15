import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/auth/pin_auth_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final PinAuthService _authService = PinAuthService();
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  String? _errorMessage;

  // Olive gold color
  static const Color oliveGold = Color(0xFFA89A6A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Badge'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: oliveGold),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(controller: cameraController, onDetect: _onQRDetected),

          // Scanner overlay
          CustomPaint(painter: ScannerOverlayPainter(), child: Container()),

          // Instructions at top
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.qr_code_scanner, color: oliveGold, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Position QR badge within the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Error message
          if (_errorMessage != null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Loading indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(oliveGold),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Authenticating...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Manual entry option at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.keyboard, color: Colors.white),
                label: const Text(
                  'Enter PIN Instead',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: oliveGold,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrToken = barcodes.first.rawValue;
    if (qrToken == null || qrToken.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // Stop scanning
    await cameraController.stop();

    try {
      final result = await _authService.loginWithQR(qrToken: qrToken);

      if (result['success'] == true) {
        // Navigate to home
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else {
        // Show error and restart scanning
        setState(() {
          _errorMessage = result['error'] ?? 'Invalid QR badge';
          _isProcessing = false;
        });

        // Clear error after 3 seconds and restart
        await Future.delayed(const Duration(seconds: 3));
        setState(() {
          _errorMessage = null;
        });

        await cameraController.start();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isProcessing = false;
      });

      await Future.delayed(const Duration(seconds: 3));
      setState(() {
        _errorMessage = null;
      });

      await cameraController.start();
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

/// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double scanAreaSize = 250.0;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;

    // Draw dark overlay
    final Paint darkPaint = Paint()..color = Colors.black.withOpacity(0.5);

    // Top
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), darkPaint);

    // Bottom
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        top + scanAreaSize,
        size.width,
        size.height - (top + scanAreaSize),
      ),
      darkPaint,
    );

    // Left
    canvas.drawRect(Rect.fromLTWH(0, top, left, scanAreaSize), darkPaint);

    // Right
    canvas.drawRect(
      Rect.fromLTWH(
        left + scanAreaSize,
        top,
        size.width - (left + scanAreaSize),
        scanAreaSize,
      ),
      darkPaint,
    );

    // Draw scan area border
    final Paint borderPaint = Paint()
      ..color =
          const Color(0xFFA89A6A) // Olive gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final double cornerLength = 30;
    final double cornerRadius = 10;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top + cornerRadius)
        ..quadraticBezierTo(left, top, left + cornerRadius, top)
        ..lineTo(left + cornerLength, top),
      borderPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(left + scanAreaSize - cornerLength, top)
        ..lineTo(left + scanAreaSize - cornerRadius, top)
        ..quadraticBezierTo(
          left + scanAreaSize,
          top,
          left + scanAreaSize,
          top + cornerRadius,
        )
        ..lineTo(left + scanAreaSize, top + cornerLength),
      borderPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + scanAreaSize - cornerLength)
        ..lineTo(left, top + scanAreaSize - cornerRadius)
        ..quadraticBezierTo(
          left,
          top + scanAreaSize,
          left + cornerRadius,
          top + scanAreaSize,
        )
        ..lineTo(left + cornerLength, top + scanAreaSize),
      borderPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(left + scanAreaSize - cornerLength, top + scanAreaSize)
        ..lineTo(left + scanAreaSize - cornerRadius, top + scanAreaSize)
        ..quadraticBezierTo(
          left + scanAreaSize,
          top + scanAreaSize,
          left + scanAreaSize,
          top + scanAreaSize - cornerRadius,
        )
        ..lineTo(left + scanAreaSize, top + scanAreaSize - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
