const PDFDocument = require('pdfkit');
const qrBadgeService = require('./qrBadgeService');

/**
 * Badge PDF Generation Service
 * Creates printable staff badges with QR codes
 */

class BadgePdfService {
  
  /**
   * Generate a printable PDF badge for a staff member
   * @param {Object} staff - Staff document from database
   * @returns {PDFDocument} PDF document stream
   */
  async generateBadgePDF(staff) {
    console.log('📄 Starting badge PDF generation for:', staff.employeeId);
    
    // Validate staff has QR token
    if (!staff.qrBadgeToken) {
      throw new Error('Staff member does not have a QR badge token');
    }

    // Create PDF document (standard business card size: 3.5" x 2")
    const doc = new PDFDocument({
      size: [252, 144], // 3.5" x 2" in points (72 points per inch)
      margins: { top: 10, bottom: 10, left: 10, right: 10 }
    });

    // Olive gold color (#A89A6A)
    const oliveGold = '#A89A6A';
    const darkGray = '#333333';
    const lightGray = '#F5F5F5';

    // Generate QR code as buffer with timeout
    console.log('📄 Generating QR code buffer...');
    let qrCodeBuffer;
    try {
      qrCodeBuffer = await Promise.race([
        qrBadgeService.generateQRCodeBuffer(staff.qrBadgeToken),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error('QR code generation timeout')), 5000)
        )
      ]);
      console.log('✅ QR code buffer generated successfully');
    } catch (error) {
      console.error('❌ QR code generation failed:', error.message);
      throw error;
    }

    // Background
    doc.rect(0, 0, 252, 144).fill(lightGray);

    // Header bar with olive gold
    doc.rect(0, 0, 252, 30).fill(oliveGold);

    // Company name
    doc.fontSize(12)
       .fillColor('#FFFFFF')
       .font('Helvetica-Bold')
       .text('AL MARYA ROSTERY', 10, 10, { width: 232, align: 'center' });

    // Staff photo (if available)
    if (staff.photo) {
      try {
        // In production, you'd fetch and embed the photo
        // For now, we'll just reserve space
        doc.rect(15, 40, 60, 80).stroke(oliveGold);
        doc.fontSize(8)
           .fillColor(darkGray)
           .text('Photo', 20, 75, { width: 50, align: 'center' });
      } catch (error) {
        console.error('Error loading staff photo:', error);
      }
    } else {
      // Placeholder for photo
      doc.rect(15, 40, 60, 80).fill('#E0E0E0').stroke(oliveGold);
      doc.fontSize(8)
         .fillColor(darkGray)
         .text('No Photo', 20, 75, { width: 50, align: 'center' });
    }

    // Staff details (right of photo)
    const detailsX = 85;
    let detailsY = 45;

    // Name
    doc.fontSize(11)
       .fillColor(darkGray)
       .font('Helvetica-Bold')
       .text(staff.name.toUpperCase(), detailsX, detailsY, { width: 80 });
    detailsY += 18;

    // Role
    doc.fontSize(9)
       .fillColor(oliveGold)
       .font('Helvetica')
       .text(staff.role.charAt(0).toUpperCase() + staff.role.slice(1), detailsX, detailsY);
    detailsY += 15;

    // Employee ID
    doc.fontSize(10)
       .fillColor(darkGray)
       .font('Helvetica-Bold')
       .text('ID:', detailsX, detailsY);
    
    doc.fontSize(10)
       .fillColor(oliveGold)
       .font('Helvetica-Bold')
       .text(staff.employeeId, detailsX + 20, detailsY);
    detailsY += 15;

    // Shift hours
    const shiftText = `${staff.shiftStartTime} - ${staff.shiftEndTime}`;
    doc.fontSize(8)
       .fillColor(darkGray)
       .font('Helvetica')
       .text(shiftText, detailsX, detailsY);

    // QR Code (bottom right)
    doc.image(qrCodeBuffer, 175, 50, {
      width: 65,
      height: 65
    });

    // QR Code label
    doc.fontSize(7)
       .fillColor(darkGray)
       .text('Scan to Login', 175, 118, { width: 65, align: 'center' });

    // Footer with expiry date
    const expiryDate = new Date(staff.qrBadgeExpiresAt).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });

    doc.fontSize(7)
       .fillColor(darkGray)
       .text(`Valid until: ${expiryDate}`, 10, 130, { width: 232, align: 'center' });

    // Border
    doc.rect(1, 1, 250, 142).stroke(oliveGold);

    console.log('✅ Badge PDF document created successfully');
    return doc;
  }

  /**
   * Generate a full-page PDF with multiple badges (for printing multiple staff)
   * @param {Array} staffList - Array of staff documents
   * @returns {PDFDocument} PDF document stream
   */
  async generateBadgeSheetPDF(staffList) {
    // Create PDF document (Letter size: 8.5" x 11")
    const doc = new PDFDocument({
      size: 'LETTER',
      margins: { top: 36, bottom: 36, left: 36, right: 36 }
    });

    const badgeWidth = 252; // 3.5"
    const badgeHeight = 144; // 2"
    const spacing = 18; // Space between badges
    const perRow = 2;
    const perColumn = 4;
    const startX = 54; // Center badges on page
    const startY = 54;

    let currentX = startX;
    let currentY = startY;
    let count = 0;

    for (const staff of staffList) {
      if (count > 0 && count % (perRow * perColumn) === 0) {
        doc.addPage();
        currentX = startX;
        currentY = startY;
      }

      // Generate individual badge
      const badgePdf = await this.generateBadgePDF(staff);
      
      // In a real implementation, you'd embed the badge PDF here
      // For simplicity, we'll draw a placeholder
      doc.save();
      doc.translate(currentX, currentY);
      
      // Draw badge outline
      doc.rect(0, 0, badgeWidth, badgeHeight).stroke('#A89A6A');
      doc.fontSize(10).text(`${staff.name} (${staff.employeeId})`, 10, 60, {
        width: badgeWidth - 20,
        align: 'center'
      });

      doc.restore();

      // Move to next position
      currentX += badgeWidth + spacing;
      count++;

      if (count % perRow === 0) {
        currentX = startX;
        currentY += badgeHeight + spacing;
      }
    }

    return doc;
  }

  /**
   * Generate badge PDF and return as buffer
   * @param {Object} staff - Staff document
   * @returns {Promise<Buffer>} PDF buffer
   */
  async generateBadgePDFBuffer(staff) {
    return new Promise(async (resolve, reject) => {
      try {
        const doc = await this.generateBadgePDF(staff);
        const buffers = [];

        doc.on('data', buffers.push.bind(buffers));
        doc.on('end', () => {
          const pdfBuffer = Buffer.concat(buffers);
          resolve(pdfBuffer);
        });
        doc.on('error', reject);

        doc.end();
      } catch (error) {
        reject(error);
      }
    });
  }

  /**
   * Generate badge sheet PDF and return as buffer
   * @param {Array} staffList - Array of staff documents
   * @returns {Promise<Buffer>} PDF buffer
   */
  async generateBadgeSheetPDFBuffer(staffList) {
    return new Promise(async (resolve, reject) => {
      try {
        const doc = await this.generateBadgeSheetPDF(staffList);
        const buffers = [];

        doc.on('data', buffers.push.bind(buffers));
        doc.on('end', () => {
          const pdfBuffer = Buffer.concat(buffers);
          resolve(pdfBuffer);
        });
        doc.on('error', reject);

        doc.end();
      } catch (error) {
        reject(error);
      }
    });
  }
}

module.exports = new BadgePdfService();
