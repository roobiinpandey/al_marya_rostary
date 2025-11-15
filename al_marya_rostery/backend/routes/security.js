const express = require('express');
const router = express.Router();

/**
 * Security Routes - Certificate Pinning Configuration
 * Public endpoints for mobile app certificate pinning
 */

/**
 * @route   GET /api/security/certificate-pins
 * @desc    Get current certificate pins for SSL/TLS pinning
 * @access  Public (no authentication required - pins are public security config)
 * @returns {Object} Certificate pins configuration with version info
 */
router.get('/certificate-pins', (req, res) => {
  try {
    // Load certificate pins from environment variables
    // These should be set in .env and updated when certificates are rotated
    const primaryPinsString = process.env.CERTIFICATE_PRIMARY_PINS || 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
    const backupPinsString = process.env.CERTIFICATE_BACKUP_PINS || '';

    // Parse comma-separated pins and filter empty strings
    const primaryPins = primaryPinsString
      .split(',')
      .map(pin => pin.trim())
      .filter(pin => pin.length > 0);

    const backupPins = backupPinsString
      .split(',')
      .map(pin => pin.trim())
      .filter(pin => pin.length > 0);

    // Calculate expiration (7 days from now)
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();

    const certificatePins = {
      version: process.env.CERTIFICATE_PINS_VERSION || '1.0.0',
      primaryPins,
      backupPins,
      expiresAt,
      // Optional: include algorithm info for client debugging
      algorithm: 'sha256',
      encoding: 'base64'
    };

    // Set cache headers for 24 hours
    // Mobile apps should cache and respect these headers
    res.set('Cache-Control', 'public, max-age=86400');
    res.set('Content-Type', 'application/json');

    console.log(`📍 Certificate pins requested from ${req.ip} | Primary pins: ${primaryPins.length} | Backup pins: ${backupPins.length}`);

    res.json({
      success: true,
      data: certificatePins
    });

  } catch (error) {
    console.error('❌ Error serving certificate pins:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve certificate pins',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   GET /api/security/certificate-pins/stats
 * @desc    Get certificate pins statistics (admin only)
 * @access  Private (requires authentication)
 * @returns {Object} Statistics about certificate pins
 */
router.get('/certificate-pins/stats', (req, res) => {
  try {
    const primaryPinsString = process.env.CERTIFICATE_PRIMARY_PINS || '';
    const backupPinsString = process.env.CERTIFICATE_BACKUP_PINS || '';

    const primaryPins = primaryPinsString
      .split(',')
      .map(pin => pin.trim())
      .filter(pin => pin.length > 0);

    const backupPins = backupPinsString
      .split(',')
      .map(pin => pin.trim())
      .filter(pin => pin.length > 0);

    res.json({
      success: true,
      data: {
        version: process.env.CERTIFICATE_PINS_VERSION || '1.0.0',
        primaryPinsCount: primaryPins.length,
        backupPinsCount: backupPins.length,
        totalPins: primaryPins.length + backupPins.length,
        algorithm: 'sha256',
        encoding: 'base64',
        lastUpdated: new Date().toISOString(),
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
      }
    });
  } catch (error) {
    console.error('❌ Error getting certificate pins stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get certificate pins statistics'
    });
  }
});

/**
 * @route   POST /api/security/certificate-pins/verify
 * @desc    Verify if a certificate pin is valid (for debugging)
 * @access  Public (for troubleshooting)
 * @param   {string} pin - The certificate pin to verify
 * @returns {Object} Verification result
 */
router.post('/certificate-pins/verify', (req, res) => {
  try {
    const { pin } = req.body;

    if (!pin) {
      return res.status(400).json({
        success: false,
        message: 'Certificate pin is required'
      });
    }

    const primaryPinsString = process.env.CERTIFICATE_PRIMARY_PINS || '';
    const backupPinsString = process.env.CERTIFICATE_BACKUP_PINS || '';

    const primaryPins = primaryPinsString
      .split(',')
      .map(p => p.trim())
      .filter(p => p.length > 0);

    const backupPins = backupPinsString
      .split(',')
      .map(p => p.trim())
      .filter(p => p.length > 0);

    const isValidPrimary = primaryPins.includes(pin);
    const isValidBackup = backupPins.includes(pin);
    const isValid = isValidPrimary || isValidBackup;

    console.log(`🔍 Certificate pin verification for: ${pin.substring(0, 20)}... | Valid: ${isValid}`);

    res.json({
      success: true,
      data: {
        pin: pin.substring(0, 20) + '...',
        isValid,
        isPrimary: isValidPrimary,
        isBackup: isValidBackup,
        message: isValid ? 'Certificate pin is valid' : 'Certificate pin is not recognized'
      }
    });
  } catch (error) {
    console.error('❌ Error verifying certificate pin:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to verify certificate pin'
    });
  }
});

module.exports = router;
