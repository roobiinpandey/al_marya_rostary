const QRCode = require('qrcode');
const crypto = require('crypto');

/**
 * QR Badge Service
 * Handles generation and validation of QR badge tokens
 * Used for staff authentication via badge scanning
 */
class QRBadgeService {
  
  /**
   * Generate secure QR token for staff member
   * @param {String} employeeId - Staff employee ID
   * @returns {String} Encrypted QR token
   */
  generateQRToken(employeeId) {
    const payload = {
      employeeId: employeeId.toUpperCase(),
      timestamp: Date.now(),
      random: crypto.randomBytes(16).toString('hex')
    };
    
    // Encrypt payload
    const secret = process.env.QR_BADGE_SECRET || process.env.JWT_SECRET;
    const encrypted = this.encrypt(JSON.stringify(payload), secret);
    return encrypted;
  }
  
  /**
   * Decrypt and validate QR token
   * @param {String} qrToken - Encrypted QR token from scan
   * @returns {Object} Validation result with employee ID
   */
  validateQRToken(qrToken) {
    try {
      const secret = process.env.QR_BADGE_SECRET || process.env.JWT_SECRET;
      const decrypted = this.decrypt(qrToken, secret);
      const payload = JSON.parse(decrypted);
      
      // Optional: Check token age (expire after 6 months)
      const sixMonths = 6 * 30 * 24 * 60 * 60 * 1000;
      if (Date.now() - payload.timestamp > sixMonths) {
        return { 
          valid: false, 
          reason: 'expired',
          message: 'QR badge has expired. Please contact admin for new badge.' 
        };
      }
      
      return { 
        valid: true, 
        employeeId: payload.employeeId 
      };
    } catch (error) {
      return { 
        valid: false, 
        reason: 'invalid',
        message: 'Invalid QR code. Please contact admin.',
        error: error.message 
      };
    }
  }
  
  /**
   * Generate QR code image as Data URL
   * @param {String} qrToken - Token to encode in QR
   * @returns {Promise<String>} Base64 data URL of QR code
   */
  async generateQRCodeImage(qrToken) {
    try {
      const qrDataUrl = await QRCode.toDataURL(qrToken, {
        errorCorrectionLevel: 'H', // High error correction
        type: 'image/png',
        quality: 1,
        margin: 2,
        width: 400,
        color: {
          dark: '#000000',  // Black QR code
          light: '#FFFFFF'  // White background
        }
      });
      return qrDataUrl;
    } catch (error) {
      throw new Error(`Failed to generate QR code: ${error.message}`);
    }
  }
  
  /**
   * Generate QR code image as buffer
   * @param {String} qrToken - Token to encode in QR
   * @returns {Promise<Buffer>} PNG image buffer
   */
  async generateQRCodeBuffer(qrToken) {
    try {
      const buffer = await QRCode.toBuffer(qrToken, {
        errorCorrectionLevel: 'H',
        type: 'png',
        quality: 1,
        margin: 2,
        width: 400,
        color: {
          dark: '#000000',
          light: '#FFFFFF'
        }
      });
      return buffer;
    } catch (error) {
      throw new Error(`Failed to generate QR code buffer: ${error.message}`);
    }
  }
  
  /**
   * Encrypt text using AES-256-CBC
   * @param {String} text - Plain text to encrypt
   * @param {String} secret - Encryption secret
   * @returns {String} Encrypted text (iv:encrypted)
   */
  encrypt(text, secret) {
    const algorithm = 'aes-256-cbc';
    const key = crypto.scryptSync(secret, 'salt', 32);
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(algorithm, key, iv);
    
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    return iv.toString('hex') + ':' + encrypted;
  }
  
  /**
   * Decrypt text using AES-256-CBC
   * @param {String} encryptedText - Encrypted text (iv:encrypted)
   * @param {String} secret - Encryption secret
   * @returns {String} Decrypted plain text
   */
  decrypt(encryptedText, secret) {
    const algorithm = 'aes-256-cbc';
    const key = crypto.scryptSync(secret, 'salt', 32);
    const parts = encryptedText.split(':');
    
    if (parts.length !== 2) {
      throw new Error('Invalid encrypted text format');
    }
    
    const iv = Buffer.from(parts[0], 'hex');
    const encrypted = parts[1];
    const decipher = crypto.createDecipheriv(algorithm, key, iv);
    
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  }
  
  /**
   * Generate badge data for staff (for PDF/badge printing)
   * @param {Object} staff - Staff document
   * @returns {Promise<Object>} Badge data with QR code
   */
  async generateBadgeData(staff) {
    try {
      // Generate QR token if not exists
      let qrToken = staff.qrBadgeToken;
      if (!qrToken) {
        qrToken = this.generateQRToken(staff.employeeId);
      }
      
      // Generate QR code image
      const qrCodeDataUrl = await this.generateQRCodeImage(qrToken);
      
      return {
        employeeId: staff.employeeId,
        name: staff.name,
        role: staff.role,
        photo: staff.photo,
        qrToken,
        qrCodeDataUrl,
        generatedAt: new Date(),
        expiresAt: new Date(Date.now() + 6 * 30 * 24 * 60 * 60 * 1000) // 6 months
      };
    } catch (error) {
      throw new Error(`Failed to generate badge data: ${error.message}`);
    }
  }
}

module.exports = new QRBadgeService();
