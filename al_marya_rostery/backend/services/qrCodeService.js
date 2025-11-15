const QRCode = require('qrcode');
const crypto = require('crypto');

class QRCodeService {
  /**
   * Generate a PERMANENT QR code for a user (called ONCE on signup)
   * This QR code never changes and is unique per user
   * @param {string} userId - MongoDB User _id
   * @param {string} firebaseUid - Firebase Authentication UID
   * @returns {Promise<{qrCode: string, qrHash: string}>}
   */
  static async generateUserQRCode(userId, firebaseUid) {
    try {
      // Create unique QR data with timestamp and hash
      const qrData = {
        userId: userId.toString(),
        firebaseUid: firebaseUid,
        timestamp: Date.now(),
        type: 'loyalty_reward'
      };
      
      // Generate secure hash (this is stored in database)
      const qrHash = crypto
        .createHash('sha256')
        .update(`${userId}-${firebaseUid}-${process.env.QR_SECRET || 'default-secret-change-me'}`)
        .digest('hex');
      
      // Add hash to QR data for verification
      qrData.hash = qrHash;
      
      // Generate QR code image as base64 data URL
      const qrCodeImage = await QRCode.toDataURL(JSON.stringify(qrData), {
        errorCorrectionLevel: 'H', // High error correction
        type: 'image/png',
        quality: 0.95,
        margin: 2,
        width: 300,
        color: {
          dark: '#000000',
          light: '#FFFFFF'
        }
      });
      
      return {
        qrCode: qrCodeImage,      // Full base64 image (to send to user)
        qrHash: qrHash,            // Hash to store in database
        qrData: qrData             // Original data (for reference)
      };
    } catch (error) {
      console.error('Error generating QR code:', error);
      throw new Error('Failed to generate QR code');
    }
  }
  
  /**
   * Verify that a QR code hash belongs to a specific user
   * @param {string} qrHash - The hash from QR code scan
   * @param {string} userId - MongoDB User _id
   * @param {string} firebaseUid - Firebase Authentication UID
   * @returns {boolean}
   */
  static verifyQRCode(qrHash, userId, firebaseUid) {
    try {
      const expectedHash = crypto
        .createHash('sha256')
        .update(`${userId}-${firebaseUid}-${process.env.QR_SECRET || 'default-secret-change-me'}`)
        .digest('hex');
      
      return qrHash === expectedHash;
    } catch (error) {
      console.error('Error verifying QR code:', error);
      return false;
    }
  }
  
  /**
   * Parse QR code data from scanned string
   * @param {string} qrDataString - JSON string from QR scan
   * @returns {object|null}
   */
  static parseQRData(qrDataString) {
    try {
      const data = JSON.parse(qrDataString);
      
      // Validate required fields
      if (!data.userId || !data.firebaseUid || !data.hash || !data.type) {
        return null;
      }
      
      // Validate QR type
      if (data.type !== 'loyalty_reward') {
        return null;
      }
      
      return data;
    } catch (error) {
      console.error('Error parsing QR data:', error);
      return null;
    }
  }
  
  /**
   * Generate QR code for reward redemption
   * @param {string} rewardId - Reward ID
   * @param {string} userId - User ID
   * @param {string} redemptionCode - Unique redemption code
   * @returns {Promise<string>}
   */
  static async generateRewardQRCode(rewardId, userId, redemptionCode) {
    try {
      const qrData = {
        type: 'reward_redemption',
        rewardId,
        userId,
        redemptionCode,
        timestamp: Date.now(),
        expiresAt: Date.now() + (30 * 24 * 60 * 60 * 1000) // 30 days
      };
      
      const qrCodeImage = await QRCode.toDataURL(JSON.stringify(qrData), {
        errorCorrectionLevel: 'H',
        type: 'image/png',
        quality: 0.95,
        margin: 2,
        width: 300
      });
      
      return qrCodeImage;
    } catch (error) {
      console.error('Error generating reward QR code:', error);
      throw new Error('Failed to generate reward QR code');
    }
  }
  
  /**
   * Validate if QR code has expired
   * @param {object} qrData - Parsed QR data
   * @returns {boolean}
   */
  static isQRExpired(qrData) {
    if (!qrData.expiresAt) {
      return false; // Permanent QR codes don't expire
    }
    
    return Date.now() > qrData.expiresAt;
  }
}

module.exports = QRCodeService;
