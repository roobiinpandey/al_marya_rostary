/**
 * Pino HTTP Middleware
 * 
 * Automatically logs all HTTP requests with:
 * - Request correlation IDs
 * - Response time tracking
 * - Status codes
 * - User information (if authenticated)
 * - Request/response sizes
 * 
 * Usage in server.js:
 * const pinoHttpMiddleware = require('./middleware/pinoHttp');
 * app.use(pinoHttpMiddleware);
 */

const pinoHttp = require('pino-http');
const logger = require('../utils/pinoLogger');
const { v4: uuidv4 } = require('crypto').webcrypto;

// Create HTTP logger middleware
const pinoHttpMiddleware = pinoHttp({
  logger: logger,
  
  // Generate unique request ID
  genReqId: (req, res) => {
    // Use existing request ID or generate new one
    return req.id || req.headers['x-request-id'] || uuidv4();
  },
  
  // Custom request serializer
  serializers: {
    req: (req) => ({
      id: req.id,
      method: req.method,
      url: req.url,
      path: req.path,
      params: req.params,
      query: req.query,
      // Include user info if authenticated
      user: req.user ? {
        id: req.user._id || req.user.userId,
        email: req.user.email,
        roles: req.user.roles
      } : undefined,
      headers: {
        host: req.headers.host,
        'user-agent': req.headers['user-agent'],
        'content-type': req.headers['content-type'],
        'content-length': req.headers['content-length']
      },
      remoteAddress: req.ip || req.connection?.remoteAddress
    }),
    res: (res) => ({
      statusCode: res.statusCode,
      headers: {
        'content-type': res.getHeader('content-type'),
        'content-length': res.getHeader('content-length')
      }
    })
  },
  
  // Custom log level based on status code
  customLogLevel: (req, res, err) => {
    if (res.statusCode >= 500 || err) return 'error';
    if (res.statusCode >= 400) return 'warn';
    if (res.statusCode >= 300) return 'info';
    return 'info';
  },
  
  // Custom success message
  customSuccessMessage: (req, res) => {
    return `${req.method} ${req.url} ${res.statusCode}`;
  },
  
  // Custom error message
  customErrorMessage: (req, res, err) => {
    return `${req.method} ${req.url} ${res.statusCode} - ${err.message}`;
  },
  
  // Custom attributes to add to every log
  customAttributeKeys: {
    req: 'request',
    res: 'response',
    err: 'error',
    responseTime: 'duration'
  },
  
  // Don't log health check endpoints (reduce noise)
  autoLogging: {
    ignore: (req) => {
      // Ignore health check and metrics endpoints
      return req.url === '/health' || req.url === '/metrics';
    }
  }
});

module.exports = pinoHttpMiddleware;
