/**
 * Enhanced Structured Logging with Pino
 * 
 * Week 1 Implementation: Structured Logging
 * - 5x faster than console.log
 * - Structured JSON logs for production
 * - Pretty-printed logs for development
 * - Request correlation IDs
 * - Searchable log fields
 * - Backward compatible with existing logger
 * 
 * Usage:
 * const logger = require('./utils/pinoLogger');
 * logger.info({ userId: '123', action: 'login' }, 'User authenticated');
 * logger.error({ err: error, userId: '123' }, 'Login failed');
 */

const pino = require('pino');

// Determine environment
const isDevelopment = process.env.NODE_ENV !== 'production';

// Create logger configuration
const loggerConfig = {
  level: process.env.LOG_LEVEL || (isDevelopment ? 'debug' : 'info'),
  
  // Format configuration
  formatters: {
    level: (label) => {
      return { level: label };
    },
    bindings: (bindings) => {
      return {
        pid: bindings.pid,
        hostname: bindings.hostname,
        node_version: process.version
      };
    }
  },
  
  // Timestamp format (ISO 8601)
  timestamp: pino.stdTimeFunctions.isoTime,
  
  // Base logging context
  base: {
    app: 'al-marya-rostery',
    environment: process.env.NODE_ENV || 'development'
  },
  
  // Serializers for common objects
  serializers: {
    req: (req) => ({
      id: req.id,
      method: req.method,
      url: req.url,
      path: req.path,
      params: req.params,
      query: req.query,
      headers: {
        host: req.headers.host,
        'user-agent': req.headers['user-agent'],
        'content-type': req.headers['content-type']
      },
      remoteAddress: req.ip || req.connection?.remoteAddress
    }),
    res: (res) => ({
      statusCode: res.statusCode,
      headers: res.getHeaders ? res.getHeaders() : {}
    }),
    err: pino.stdSerializers.err
  }
};

// Use pretty-print in development
if (isDevelopment) {
  loggerConfig.transport = {
    target: 'pino-pretty',
    options: {
      colorize: true,
      translateTime: 'SYS:HH:MM:ss',
      ignore: 'pid,hostname',
      singleLine: false,
      messageFormat: '{emoji} {msg}',
      customPrettifiers: {
        emoji: (logLevel) => {
          const emojis = {
            10: '🔍', // trace
            20: '🐛', // debug
            30: '✅', // info
            40: '⚠️', // warn
            50: '❌', // error
            60: '💀' // fatal
          };
          return emojis[logLevel] || '📝';
        }
      }
    }
  };
}

// Create the logger instance
const logger = pino(loggerConfig);

/**
 * Create a child logger with additional context
 * @param {Object} bindings - Additional context to include in all logs
 * @returns {Object} Child logger instance
 */
logger.createChild = (bindings) => {
  return logger.child(bindings);
};

/**
 * Log authentication events
 * @param {Object} context - User context
 * @param {string} message - Log message
 * @param {string} level - Log level (default: info)
 */
logger.auth = (context, message, level = 'info') => {
  logger[level]({
    ...context,
    category: 'auth',
    timestamp: new Date().toISOString()
  }, message);
};

/**
 * Log order events
 * @param {Object} context - Order context
 * @param {string} message - Log message
 * @param {string} level - Log level (default: info)
 */
logger.order = (context, message, level = 'info') => {
  logger[level]({
    ...context,
    category: 'order',
    timestamp: new Date().toISOString()
  }, message);
};

/**
 * Log payment events
 * @param {Object} context - Payment context
 * @param {string} message - Log message
 * @param {string} level - Log level (default: info)
 */
logger.payment = (context, message, level = 'info') => {
  logger[level]({
    ...context,
    category: 'payment',
    timestamp: new Date().toISOString()
  }, message);
};

/**
 * Log cache events
 * @param {Object} context - Cache context
 * @param {string} message - Log message
 */
logger.cache = (context, message) => {
  logger.debug({
    ...context,
    category: 'cache',
    timestamp: new Date().toISOString()
  }, message);
};

/**
 * Log database events
 * @param {Object} context - Database context
 * @param {string} message - Log message
 * @param {string} level - Log level (default: debug)
 */
logger.database = (context, message, level = 'debug') => {
  logger[level]({
    ...context,
    category: 'database',
    timestamp: new Date().toISOString()
  }, message);
};

/**
 * Log API events
 * @param {Object} context - API context
 * @param {string} message - Log message
 */
logger.api = (context, message, level = 'info') => {
  logger[level]({
    ...context,
    category: 'api',
    timestamp: new Date().toISOString()
  }, message);
};

/**
 * Log security events (always at warn or higher)
 * @param {Object} context - Security context
 * @param {string} message - Log message
 * @param {string} level - Log level (default: warn)
 */
logger.security = (context, message, level = 'warn') => {
  logger[level]({
    ...context,
    category: 'security',
    timestamp: new Date().toISOString()
  }, message);
};

/**
 * Log performance metrics
 * @param {Object} metrics - Performance metrics
 * @param {string} message - Log message
 */
logger.performance = (metrics, message) => {
  logger.info({
    ...metrics,
    category: 'performance',
    timestamp: new Date().toISOString()
  }, message);
};

/**
 * Log HTTP request (Express middleware compatible)
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {number} duration - Request duration in ms
 */
logger.request = (req, res, duration) => {
  const statusCode = res.statusCode;
  const level = statusCode >= 500 ? 'error' : statusCode >= 400 ? 'warn' : 'info';
  
  logger[level]({
    category: 'http',
    method: req.method,
    url: req.originalUrl,
    statusCode,
    duration: `${duration}ms`,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    userId: req.user?.userId || req.user?._id
  }, `${req.method} ${req.originalUrl} ${statusCode} - ${duration}ms`);
};

module.exports = logger;
