/**
 * Standardized Error Handling System
 * Consistent error responses and security-focused error handling
 */

/**
 * Custom error class for application errors
 */
class AppError extends Error {
  constructor(message, statusCode = 500, errorCode = null, isOperational = true) {
    super(message);
    
    this.statusCode = statusCode;
    this.errorCode = errorCode;
    this.isOperational = isOperational;
    this.timestamp = new Date().toISOString();
    
    // Capture stack trace
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Predefined error types for consistency
 */
const ErrorTypes = {
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  AUTHENTICATION_ERROR: 'AUTHENTICATION_ERROR',
  AUTHORIZATION_ERROR: 'AUTHORIZATION_ERROR',
  NOT_FOUND_ERROR: 'NOT_FOUND_ERROR',
  DUPLICATE_ERROR: 'DUPLICATE_ERROR',
  RATE_LIMIT_ERROR: 'RATE_LIMIT_ERROR',
  FILE_ERROR: 'FILE_ERROR',
  DATABASE_ERROR: 'DATABASE_ERROR',
  EXTERNAL_SERVICE_ERROR: 'EXTERNAL_SERVICE_ERROR',
  SECURITY_ERROR: 'SECURITY_ERROR'
};

/**
 * Factory functions for common errors
 */
const createError = {
  validation: (message, details = null) => 
    new AppError(message, 400, ErrorTypes.VALIDATION_ERROR),

  authentication: (message = 'Authentication failed') => 
    new AppError(message, 401, ErrorTypes.AUTHENTICATION_ERROR),

  authorization: (message = 'Access denied') => 
    new AppError(message, 403, ErrorTypes.AUTHORIZATION_ERROR),

  notFound: (resource = 'Resource') => 
    new AppError(`${resource} not found`, 404, ErrorTypes.NOT_FOUND_ERROR),

  duplicate: (field = 'Resource') => 
    new AppError(`${field} already exists`, 409, ErrorTypes.DUPLICATE_ERROR),

  rateLimit: (message = 'Too many requests') => 
    new AppError(message, 429, ErrorTypes.RATE_LIMIT_ERROR),

  file: (message) => 
    new AppError(message, 400, ErrorTypes.FILE_ERROR),

  database: (message = 'Database operation failed') => 
    new AppError(message, 500, ErrorTypes.DATABASE_ERROR),

  externalService: (service, message = 'External service error') => 
    new AppError(`${service}: ${message}`, 502, ErrorTypes.EXTERNAL_SERVICE_ERROR),

  security: (message = 'Security violation detected') => 
    new AppError(message, 400, ErrorTypes.SECURITY_ERROR)
};

/**
 * Standardized error response formatter
 */
const formatErrorResponse = (err, req) => {
  const isDevelopment = process.env.NODE_ENV === 'development';
  const isProduction = process.env.NODE_ENV === 'production';

  // Base error response
  const errorResponse = {
    success: false,
    error: {
      code: err.errorCode || 'INTERNAL_ERROR',
      message: err.message || 'Internal server error',
      statusCode: err.statusCode || 500,
      timestamp: err.timestamp || new Date().toISOString()
    }
  };

  // Add request context in development
  if (isDevelopment) {
    errorResponse.error.path = req?.path;
    errorResponse.error.method = req?.method;
    errorResponse.error.stack = err.stack;
  }

  // Add correlation ID if available
  if (req?.correlationId) {
    errorResponse.error.correlationId = req.correlationId;
  }

  // Security: Never expose internal errors in production
  if (isProduction && (!err.isOperational || err.statusCode >= 500)) {
    errorResponse.error.message = 'Internal server error';
    errorResponse.error.code = 'INTERNAL_ERROR';
    delete errorResponse.error.stack;
  }

  return errorResponse;
};

/**
 * Handle specific error types
 */
const handleSpecificErrors = (error) => {
  // MongoDB Validation Error
  if (error.name === 'ValidationError') {
    const messages = Object.values(error.errors).map(err => err.message);
    return createError.validation(`Validation failed: ${messages.join(', ')}`);
  }

  // MongoDB Duplicate Key Error
  if (error.code === 11000) {
    const field = Object.keys(error.keyPattern || {})[0] || 'field';
    return createError.duplicate(`${field.charAt(0).toUpperCase() + field.slice(1)} already exists`);
  }

  // MongoDB Cast Error
  if (error.name === 'CastError') {
    return createError.validation('Invalid data format provided');
  }

  // JWT Errors
  if (error.name === 'JsonWebTokenError') {
    return createError.authentication('Invalid token');
  }

  if (error.name === 'TokenExpiredError') {
    return createError.authentication('Token expired');
  }

  // Mongoose Connection Error
  if (error.name === 'MongooseError' || error.name === 'MongoError') {
    return createError.database('Database connection error');
  }

  // File System Errors
  if (error.code === 'ENOENT') {
    return createError.file('File not found');
  }

  if (error.code === 'EACCES') {
    return createError.file('File access denied');
  }

  // Return original error if no specific handling
  return error;
};

/**
 * Global error handler middleware
 */
const globalErrorHandler = (err, req, res, next) => {
  // Log error for monitoring
  console.error('Error occurred:', {
    message: err.message,
    stack: err.stack,
    url: req?.originalUrl,
    method: req?.method,
    ip: req?.ip,
    userAgent: req?.get('User-Agent'),
    userId: req?.user?.userId,
    timestamp: new Date().toISOString()
  });

  // Handle specific error types
  const processedError = handleSpecificErrors(err);

  // Format response
  const errorResponse = formatErrorResponse(processedError, req);

  // Send response
  res.status(processedError.statusCode || 500).json(errorResponse);
};

/**
 * Async error handler wrapper
 * Wraps async functions to catch errors automatically
 */
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

/**
 * Not found handler for undefined routes
 */
const notFoundHandler = (req, res, next) => {
  const error = createError.notFound(`Route ${req.method} ${req.originalUrl}`);
  next(error);
};

/**
 * Success response formatter for consistency
 */
const sendSuccess = (res, data = null, message = 'Success', statusCode = 200) => {
  const response = {
    success: true,
    message,
    timestamp: new Date().toISOString()
  };

  if (data !== null) {
    response.data = data;
  }

  res.status(statusCode).json(response);
};

/**
 * Paginated response formatter
 */
const sendPaginatedSuccess = (res, data, pagination, message = 'Success') => {
  res.status(200).json({
    success: true,
    message,
    data,
    pagination: {
      currentPage: pagination.page,
      totalPages: Math.ceil(pagination.total / pagination.limit),
      totalItems: pagination.total,
      itemsPerPage: pagination.limit,
      hasNextPage: pagination.page < Math.ceil(pagination.total / pagination.limit),
      hasPrevPage: pagination.page > 1
    },
    timestamp: new Date().toISOString()
  });
};

module.exports = {
  AppError,
  ErrorTypes,
  createError,
  formatErrorResponse,
  handleSpecificErrors,
  globalErrorHandler,
  asyncHandler,
  notFoundHandler,
  sendSuccess,
  sendPaginatedSuccess
};
