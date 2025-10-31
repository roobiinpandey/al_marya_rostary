/**
 * JSON Serialization Middleware
 * Ensures ObjectIds and other MongoDB types are properly serialized to strings
 */

const mongoose = require('mongoose');

/**
 * Recursively convert MongoDB ObjectIds to strings in an object or array
 * @param {*} obj - Object, array, or primitive to process
 * @param {WeakSet} visited - Set of already visited objects to prevent circular references
 * @returns {*} Processed data with ObjectIds as strings
 */
function serializeMongoTypes(obj, visited = new WeakSet()) {
  if (obj === null || obj === undefined) {
    return obj;
  }

  // Handle ObjectId
  if (obj instanceof mongoose.Types.ObjectId || obj._bsontype === 'ObjectID') {
    return obj.toString();
  }

  // Handle Date
  if (obj instanceof Date) {
    return obj.toISOString();
  }

  // Handle Buffer (sometimes _id gets returned as buffer)
  if (Buffer.isBuffer(obj) || obj?.buffer) {
    if (obj.buffer && typeof obj.buffer === 'object') {
      // Convert buffer object to hex string
      const bytes = Object.values(obj.buffer);
      return Buffer.from(bytes).toString('hex');
    }
    return obj.toString('hex');
  }

  // Handle Arrays
  if (Array.isArray(obj)) {
    // Check for circular reference
    if (visited.has(obj)) {
      return '[Circular Reference]';
    }
    visited.add(obj);
    
    const result = obj.map(item => serializeMongoTypes(item, visited));
    visited.delete(obj);
    return result;
  }

  // Handle Objects
  if (typeof obj === 'object') {
    // Check for circular reference
    if (visited.has(obj)) {
      return '[Circular Reference]';
    }
    visited.add(obj);
    
    const serialized = {};
    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        serialized[key] = serializeMongoTypes(obj[key], visited);
      }
    }
    visited.delete(obj);
    return serialized;
  }

  // Return primitives as-is
  return obj;
}

/**
 * Express middleware to serialize MongoDB types in response JSON
 * Use this after .lean() queries to ensure proper JSON serialization
 */
const serializeResponse = (req, res, next) => {
  const originalJson = res.json.bind(res);

  res.json = function(data) {
    const serialized = serializeMongoTypes(data);
    return originalJson(serialized);
  };

  next();
};

/**
 * Helper function to serialize data directly (for use in controllers)
 * @param {*} data - Data to serialize
 * @returns {*} Serialized data
 */
function serialize(data) {
  return serializeMongoTypes(data);
}

module.exports = {
  serializeResponse,
  serialize,
  serializeMongoTypes
};
