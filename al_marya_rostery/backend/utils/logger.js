/**
 * Centralized Logging Utility
 * Provides structured logging with different levels and optional file output
 * 
 * Usage:
 * const logger = require('./utils/logger');
 * logger.info('User logged in', { userId, email });
 * logger.error('Database error', { error: error.message, stack: error.stack });
 * logger.warn('High memory usage', { memoryUsage: process.memoryUsage() });
 */

const fs = require('fs');
const path = require('path');

// Log levels
const LOG_LEVELS = {
  ERROR: 0,
  WARN: 1,
  INFO: 2,
  DEBUG: 3
};

// Colors for console output
const COLORS = {
  ERROR: '\x1b[31m', // Red
  WARN: '\x1b[33m',  // Yellow
  INFO: '\x1b[36m',  // Cyan
  DEBUG: '\x1b[90m', // Gray
  RESET: '\x1b[0m'
};

// Emojis for different log levels
const EMOJIS = {
  ERROR: '❌',
  WARN: '⚠️',
  INFO: 'ℹ️',
  DEBUG: '🔍'
};

class Logger {
  constructor(options = {}) {
    this.level = options.level || process.env.LOG_LEVEL || 'INFO';
    this.enableFileLogging = options.enableFileLogging !== false && process.env.NODE_ENV === 'production';
    this.logDir = options.logDir || path.join(__dirname, '../logs');
    this.maxFileSize = options.maxFileSize || 10 * 1024 * 1024; // 10MB
    
    // Create logs directory if it doesn't exist
    if (this.enableFileLogging && !fs.existsSync(this.logDir)) {
      fs.mkdirSync(this.logDir, { recursive: true });
    }
  }

  /**
   * Get current log level number
   */
  getCurrentLevel() {
    return LOG_LEVELS[this.level.toUpperCase()] || LOG_LEVELS.INFO;
  }

  /**
   * Check if a log level should be logged
   */
  shouldLog(level) {
    return LOG_LEVELS[level] <= this.getCurrentLevel();
  }

  /**
   * Format log message
   */
  formatMessage(level, message, metadata = {}) {
    const timestamp = new Date().toISOString();
    const logEntry = {
      timestamp,
      level,
      message,
      ...(Object.keys(metadata).length > 0 && { metadata }),
      env: process.env.NODE_ENV || 'development'
    };

    return logEntry;
  }

  /**
   * Format console output with colors
   */
  formatConsoleOutput(level, message, metadata = {}) {
    const color = COLORS[level];
    const emoji = EMOJIS[level];
    const timestamp = new Date().toISOString().split('T')[1].split('.')[0]; // HH:MM:SS
    
    let output = `${color}${emoji} [${level}] ${timestamp}${COLORS.RESET} ${message}`;
    
    if (Object.keys(metadata).length > 0) {
      output += `\n${color}${JSON.stringify(metadata, null, 2)}${COLORS.RESET}`;
    }
    
    return output;
  }

  /**
   * Write log to file
   */
  writeToFile(level, logEntry) {
    if (!this.enableFileLogging) return;

    try {
      const filename = level === 'ERROR' ? 'error.log' : 'combined.log';
      const filepath = path.join(this.logDir, filename);
      
      // Check file size and rotate if necessary
      if (fs.existsSync(filepath)) {
        const stats = fs.statSync(filepath);
        if (stats.size > this.maxFileSize) {
          const backupPath = path.join(
            this.logDir,
            `${filename}.${Date.now()}.bak`
          );
          fs.renameSync(filepath, backupPath);
        }
      }
      
      // Append log entry
      const logLine = JSON.stringify(logEntry) + '\n';
      fs.appendFileSync(filepath, logLine, 'utf8');
    } catch (error) {
      // Don't throw - just log to console if file writing fails
      console.error('Failed to write log to file:', error.message);
    }
  }

  /**
   * Log a message
   */
  log(level, message, metadata = {}) {
    if (!this.shouldLog(level)) return;

    const logEntry = this.formatMessage(level, message, metadata);
    
    // Console output
    if (process.env.NODE_ENV !== 'production' || process.env.CONSOLE_LOGS === 'true') {
      console.log(this.formatConsoleOutput(level, message, metadata));
    }
    
    // File output
    this.writeToFile(level, logEntry);
    
    return logEntry;
  }

  /**
   * Error level logging
   */
  error(message, metadata = {}) {
    // Ensure error stack is included
    if (metadata.error && metadata.error.stack) {
      metadata.stack = metadata.error.stack;
      metadata.errorMessage = metadata.error.message;
    }
    
    return this.log('ERROR', message, metadata);
  }

  /**
   * Warning level logging
   */
  warn(message, metadata = {}) {
    return this.log('WARN', message, metadata);
  }

  /**
   * Info level logging
   */
  info(message, metadata = {}) {
    return this.log('INFO', message, metadata);
  }

  /**
   * Debug level logging
   */
  debug(message, metadata = {}) {
    return this.log('DEBUG', message, metadata);
  }

  /**
   * Log HTTP request
   */
  request(req, res, duration) {
    const metadata = {
      method: req.method,
      url: req.originalUrl,
      status: res.statusCode,
      duration: `${duration}ms`,
      ip: req.ip,
      userAgent: req.get('User-Agent')
    };

    if (req.user) {
      metadata.userId = req.user.userId;
    }

    const level = res.statusCode >= 500 ? 'ERROR' : res.statusCode >= 400 ? 'WARN' : 'INFO';
    return this.log(level, `${req.method} ${req.originalUrl} ${res.statusCode}`, metadata);
  }

  /**
   * Log security event
   */
  security(event, metadata = {}) {
    return this.log('WARN', `Security Event: ${event}`, metadata);
  }

  /**
   * Log database operation
   */
  database(operation, metadata = {}) {
    return this.log('DEBUG', `Database: ${operation}`, metadata);
  }

  /**
   * Log authentication event
   */
  auth(event, metadata = {}) {
    return this.log('INFO', `Auth: ${event}`, metadata);
  }
}

// Create singleton instance
const logger = new Logger({
  level: process.env.LOG_LEVEL || 'INFO',
  enableFileLogging: process.env.NODE_ENV === 'production'
});

module.exports = logger;
