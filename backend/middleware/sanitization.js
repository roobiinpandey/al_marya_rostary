/**
 * Input Sanitization Middleware
 * Comprehensive protection against XSS, injection attacks, and malicious input
 */

const createDOMPurify = require('isomorphic-dompurify');
const validator = require('validator');

/**
 * XSS Protection Middleware
 * Sanitizes HTML content and prevents XSS attacks
 */
const xssProtection = () => {
  return (req, res, next) => {
    try {
      // Sanitize request body
      if (req.body && typeof req.body === 'object') {
        req.body = sanitizeObject(req.body);
      }

      // Sanitize query parameters
      if (req.query && typeof req.query === 'object') {
        req.query = sanitizeObject(req.query);
      }

      // Sanitize URL parameters
      if (req.params && typeof req.params === 'object') {
        req.params = sanitizeObject(req.params);
      }

      next();
    } catch (error) {
      console.error('XSS Protection Error:', error);
      return res.status(400).json({
        success: false,
        message: 'Invalid input detected'
      });
    }
  };
};

/**
 * Recursively sanitize object properties
 */
const sanitizeObject = (obj) => {
  if (obj === null || obj === undefined) return obj;
  
  if (typeof obj === 'string') {
    return sanitizeString(obj);
  }

  if (Array.isArray(obj)) {
    return obj.map(item => sanitizeObject(item));
  }

  if (typeof obj === 'object') {
    const sanitized = {};
    Object.keys(obj).forEach(key => {
      const sanitizedKey = sanitizeString(key);
      sanitized[sanitizedKey] = sanitizeObject(obj[key]);
    });
    return sanitized;
  }

  return obj;
};

/**
 * Sanitize individual string values
 */
const sanitizeString = (str) => {
  if (typeof str !== 'string') return str;

  // Remove null bytes
  str = str.replace(/\0/g, '');
  
  // Escape HTML to prevent XSS
  str = validator.escape(str);
  
  // Additional XSS protection using DOMPurify
  str = createDOMPurify.sanitize(str, {
    ALLOWED_TAGS: [], // No HTML tags allowed
    ALLOWED_ATTR: []  // No attributes allowed
  });

  return str;
};

/**
 * Request Size Limiting Middleware
 * Prevents large payload attacks
 */
const requestSizeLimit = (options = {}) => {
  const {
    maxBodySize = '10mb',
    maxParamLength = 1000,
    maxQueryParams = 100,
    maxHeaderSize = 8192
  } = options;

  return (req, res, next) => {
    try {
      // Check URL parameter length
      if (req.url && req.url.length > maxParamLength) {
        return res.status(414).json({
          success: false,
          message: 'URL too long'
        });
      }

      // Check query parameters count
      const queryCount = Object.keys(req.query || {}).length;
      if (queryCount > maxQueryParams) {
        return res.status(400).json({
          success: false,
          message: 'Too many query parameters'
        });
      }

      // Check header size (rough calculation)
      const headerSize = JSON.stringify(req.headers).length;
      if (headerSize > maxHeaderSize) {
        return res.status(400).json({
          success: false,
          message: 'Request headers too large'
        });
      }

      next();
    } catch (error) {
      console.error('Request size validation error:', error);
      return res.status(400).json({
        success: false,
        message: 'Invalid request format'
      });
    }
  };
};

/**
 * SQL Injection Protection Middleware
 * Detects potential SQL injection attempts
 */
const sqlInjectionProtection = () => {
  const sqlPatterns = [
    /(\%27)|(\')|(\-\-)|(\%23)|(#)/i, // SQL comments and quotes
    /((\%3D)|(=))[^\n]*((\%27)|(\')|(\-\-)|(\%3B)|(;))/i, // SQL equality checks
    /\w*((\%27)|(\'))((\%6F)|o|(\%4F))((\%72)|r|(\%52))/i, // "OR" variations
    /((\%27)|(\'))union/i, // UNION attempts
    /exec(\s|\+)+(s|x)p\w+/i, // SQL Server stored procedures
    /((\%27)|(\'))\s*(\||(\%7C))\s*(\w)/i, // Pipe characters
    /((\%27)|(\'))\s*(\&|(\%26))\s*(\w)/i, // Ampersand characters
    /select\s+.*\s+from\s+/i, // SELECT statements
    /insert\s+into\s+/i, // INSERT statements
    /delete\s+from\s+/i, // DELETE statements
    /update\s+.*\s+set\s+/i, // UPDATE statements
    /drop\s+(table|database)\s+/i, // DROP statements
    /create\s+(table|database)\s+/i, // CREATE statements
    /alter\s+table\s+/i, // ALTER statements
    /truncate\s+table\s+/i // TRUNCATE statements
  ];

  return (req, res, next) => {
    try {
      const checkForSqlInjection = (value) => {
        if (typeof value === 'string') {
          const decodedValue = decodeURIComponent(value.toLowerCase());
          return sqlPatterns.some(pattern => pattern.test(decodedValue));
        }
        return false;
      };

      const checkObject = (obj) => {
        if (typeof obj === 'string') {
          return checkForSqlInjection(obj);
        }
        
        if (Array.isArray(obj)) {
          return obj.some(item => checkObject(item));
        }
        
        if (obj && typeof obj === 'object') {
          return Object.values(obj).some(value => checkObject(value));
        }
        
        return false;
      };

      // Check body, query, and params for SQL injection patterns
      const hasSqlInjection = [req.body, req.query, req.params]
        .some(obj => obj && checkObject(obj));

      if (hasSqlInjection) {
        console.warn('SQL Injection attempt detected:', {
          ip: req.ip,
          userAgent: req.get('User-Agent'),
          url: req.url,
          method: req.method,
          timestamp: new Date().toISOString()
        });

        return res.status(400).json({
          success: false,
          message: 'Invalid input detected'
        });
      }

      next();
    } catch (error) {
      console.error('SQL Injection protection error:', error);
      return res.status(400).json({
        success: false,
        message: 'Request validation failed'
      });
    }
  };
};

/**
 * Path Traversal Protection Middleware
 * Prevents directory traversal attacks
 */
const pathTraversalProtection = () => {
  const pathTraversalPatterns = [
    /\.\./,              // Basic directory traversal
    /\.\.\\/,            // Windows path traversal
    /\.\.\//,            // Unix path traversal
    /\%2e\%2e/i,         // URL encoded ..
    /\%2f/i,             // URL encoded /
    /\%5c/i,             // URL encoded \
    /\%00/i,             // Null byte
    /\/etc\/passwd/i,    // Common Unix target
    /\/proc\//i,         // Linux proc filesystem
    /c:\\/i,             // Windows path
    /\\windows\\/i,      // Windows system directory
    /\\system32\\/i      // Windows system32
  ];

  return (req, res, next) => {
    try {
      const checkForPathTraversal = (value) => {
        if (typeof value === 'string') {
          const decodedValue = decodeURIComponent(value.toLowerCase());
          return pathTraversalPatterns.some(pattern => pattern.test(decodedValue));
        }
        return false;
      };

      const checkObject = (obj) => {
        if (typeof obj === 'string') {
          return checkForPathTraversal(obj);
        }
        
        if (Array.isArray(obj)) {
          return obj.some(item => checkObject(item));
        }
        
        if (obj && typeof obj === 'object') {
          return Object.values(obj).some(value => checkObject(value));
        }
        
        return false;
      };

      // Check URL path
      if (checkForPathTraversal(req.path)) {
        console.warn('Path traversal attempt detected in URL:', {
          ip: req.ip,
          path: req.path,
          timestamp: new Date().toISOString()
        });

        return res.status(400).json({
          success: false,
          message: 'Invalid path detected'
        });
      }

      // Check body, query, and params
      const hasPathTraversal = [req.body, req.query, req.params]
        .some(obj => obj && checkObject(obj));

      if (hasPathTraversal) {
        console.warn('Path traversal attempt detected in request data:', {
          ip: req.ip,
          userAgent: req.get('User-Agent'),
          url: req.url,
          timestamp: new Date().toISOString()
        });

        return res.status(400).json({
          success: false,
          message: 'Invalid input detected'
        });
      }

      next();
    } catch (error) {
      console.error('Path traversal protection error:', error);
      return res.status(400).json({
        success: false,
        message: 'Request validation failed'
      });
    }
  };
};

/**
 * Combined input sanitization middleware
 */
const inputSanitization = (options = {}) => {
  return [
    requestSizeLimit(options.sizeLimit),
    sqlInjectionProtection(),
    pathTraversalProtection(),
    xssProtection()
  ];
};

module.exports = {
  inputSanitization,
  xssProtection,
  requestSizeLimit,
  sqlInjectionProtection,
  pathTraversalProtection,
  sanitizeString,
  sanitizeObject
};
