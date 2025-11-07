/**
 * 🌍 UNIVERSAL ORDER NUMBER GENERATOR
 * 
 * Generates unique, human-readable order numbers in the format:
 * ALM-YYYYMMDD-XXXXXX
 * 
 * Example: ALM-20251106-000123
 * 
 * Components:
 * - ALM: Brand prefix (Al Marya)
 * - YYYYMMDD: Date (e.g., 20251106 for November 6, 2025)
 * - XXXXXX: 6-digit incremental sequence (resets daily)
 * 
 * This ensures order numbers are:
 * ✅ Unique across all orders
 * ✅ Human-readable and professional
 * ✅ Easy to search and sort chronologically
 * ✅ Consistent across Customer App, Staff App, Driver App, and Admin Panel
 */

const mongoose = require('mongoose');

// Counter collection for tracking daily sequences
const counterSchema = new mongoose.Schema({
  _id: String, // Format: "order-YYYYMMDD"
  sequence: { type: Number, default: 0 },
  date: { type: Date, default: Date.now }
}, { timestamps: true });

const Counter = mongoose.model('Counter', counterSchema);

/**
 * Generate a unique order number
 * @returns {Promise<string>} Order number in format ALM-YYYYMMDD-XXXXXX
 */
async function generateOrderNumber() {
  // Get current date in YYYYMMDD format
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const dateString = `${year}${month}${day}`;
  
  // Counter ID for today
  const counterId = `order-${dateString}`;
  
  try {
    // Use findOneAndUpdate with upsert for atomic increment
    // This prevents race conditions when multiple orders are created simultaneously
    const counter = await Counter.findOneAndUpdate(
      { _id: counterId },
      { 
        $inc: { sequence: 1 },
        $setOnInsert: { date: now }
      },
      { 
        new: true, // Return updated document
        upsert: true, // Create if doesn't exist
        runValidators: true
      }
    );
    
    // Format sequence with leading zeros (6 digits)
    const sequenceString = String(counter.sequence).padStart(6, '0');
    
    // Construct order number: ALM-YYYYMMDD-XXXXXX
    const orderNumber = `ALM-${dateString}-${sequenceString}`;
    
    console.log(`✅ Generated order number: ${orderNumber}`);
    
    return orderNumber;
    
  } catch (error) {
    console.error('❌ Error generating order number:', error);
    
    // Fallback: Generate using timestamp + random (should rarely happen)
    const timestamp = Date.now().toString().slice(-6);
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    const fallbackNumber = `ALM-${dateString}-${timestamp}${random}`;
    
    console.warn(`⚠️ Using fallback order number: ${fallbackNumber}`);
    
    return fallbackNumber;
  }
}

/**
 * Get the current sequence number for a specific date
 * Useful for debugging or analytics
 * @param {Date} date - Date to check (defaults to today)
 * @returns {Promise<number>} Current sequence number
 */
async function getCurrentSequence(date = new Date()) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const dateString = `${year}${month}${day}`;
  const counterId = `order-${dateString}`;
  
  const counter = await Counter.findById(counterId);
  return counter ? counter.sequence : 0;
}

/**
 * Reset sequence for a specific date (use with caution!)
 * This should only be used for testing or cleanup
 * @param {Date} date - Date to reset (defaults to today)
 * @returns {Promise<void>}
 */
async function resetSequence(date = new Date()) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const dateString = `${year}${month}${day}`;
  const counterId = `order-${dateString}`;
  
  await Counter.findByIdAndDelete(counterId);
  console.log(`✅ Reset sequence for ${dateString}`);
}

module.exports = {
  generateOrderNumber,
  getCurrentSequence,
  resetSequence,
  Counter
};
