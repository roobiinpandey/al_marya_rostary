/**
 * Environment Variables Validation
 * Validates all required environment variables on server startup
 * Prevents server from starting with missing critical configuration
 */

// Use basic console colors instead of chalk for compatibility
const colors = {
  blue: (text) => `\x1b[34m${text}\x1b[0m`,
  green: (text) => `\x1b[32m${text}\x1b[0m`,
  yellow: (text) => `\x1b[33m${text}\x1b[0m`,
  red: (text) => `\x1b[31m${text}\x1b[0m`
};

// Required environment variables with their validation rules
const REQUIRED_ENV_VARS = {
  // Database Configuration
  MONGODB_URI: {
    required: true,
    validate: (value) => value && (value.startsWith('mongodb://') || value.startsWith('***REMOVED***')),
    errorMessage: 'MONGODB_URI must be a valid MongoDB connection string'
  },

  // Authentication
  JWT_SECRET: {
    required: true,
    validate: (value) => value && value.length >= 32,
    errorMessage: 'JWT_SECRET must be at least 32 characters long for security'
  },

  // Server Configuration
  NODE_ENV: {
    required: true,
    validate: (value) => ['development', 'production', 'test'].includes(value),
    errorMessage: 'NODE_ENV must be one of: development, production, test',
    default: 'development'
  },

  PORT: {
    required: false,
    validate: (value) => !value || (!isNaN(value) && parseInt(value) > 0 && parseInt(value) < 65536),
    errorMessage: 'PORT must be a valid port number (1-65535)',
    default: '5001'
  },

  // Email Configuration (Required for production)
  SMTP_HOST: {
    required: () => process.env.NODE_ENV === 'production',
    validate: (value) => !value || typeof value === 'string',
    errorMessage: 'SMTP_HOST is required in production environment'
  },

  SMTP_PORT: {
    required: () => process.env.NODE_ENV === 'production',
    validate: (value) => !value || (!isNaN(value) && [25, 465, 587, 2525].includes(parseInt(value))),
    errorMessage: 'SMTP_PORT must be a valid email port (25, 465, 587, 2525)'
  },

  SMTP_USER: {
    required: () => process.env.NODE_ENV === 'production',
    validate: (value) => !value || (typeof value === 'string' && value.includes('@')),
    errorMessage: 'SMTP_USER must be a valid email address'
  },

  SMTP_PASS: {
    required: () => process.env.NODE_ENV === 'production',
    validate: (value) => !value || typeof value === 'string',
    errorMessage: 'SMTP_PASS is required when SMTP is configured'
  },

  // Firebase Configuration (Optional but validated if present)
  FIREBASE_PROJECT_ID: {
    required: false,
    validate: (value) => !value || typeof value === 'string',
    errorMessage: 'FIREBASE_PROJECT_ID must be a string'
  },

  FIREBASE_SERVICE_ACCOUNT_KEY: {
    required: false,
    validate: (value) => {
      if (!value) return true;
      try {
        const parsed = JSON.parse(value);
        return parsed && parsed.type === 'service_account';
      } catch {
        return false;
      }
    },
    errorMessage: 'FIREBASE_SERVICE_ACCOUNT_KEY must be valid JSON service account'
  },

  // Frontend Configuration (Optional - used for CORS and email links)
  FRONTEND_URL: {
    required: false, // Optional: only needed if serving a separate frontend
    validate: (value) => !value || (value.startsWith('http://') || value.startsWith('https://')),
    errorMessage: 'FRONTEND_URL must be a valid URL if provided'
  },

  BASE_URL: {
    required: false, // Optional: only needed for generating email links
    validate: (value) => !value || (value.startsWith('http://') || value.startsWith('https://')),
    errorMessage: 'BASE_URL must be a valid URL if provided'
  }
};

/**
 * Validate all environment variables
 * @returns {Object} Validation result with success status and errors
 */
const validateEnvironment = () => {
  console.log(colors.blue('🔍 Validating environment variables...'));
  
  const errors = [];
  const warnings = [];
  let criticalErrors = 0;

  Object.entries(REQUIRED_ENV_VARS).forEach(([key, config]) => {
    const value = process.env[key];
    const isRequired = typeof config.required === 'function' ? config.required() : config.required;

    // Check if required variable is missing
    if (isRequired && !value) {
      errors.push({
        type: 'MISSING_REQUIRED',
        variable: key,
        message: config.errorMessage || `${key} is required`
      });
      criticalErrors++;
      return;
    }

    // Set default value if provided and variable is missing
    if (!value && config.default) {
      process.env[key] = config.default;
        console.log(colors.yellow(`⚠️  Using default value for ${key}: ${config.default}`));
    }

    // Validate value format if present
    if (value && config.validate && !config.validate(value)) {
      if (isRequired) {
        errors.push({
          type: 'INVALID_FORMAT',
          variable: key,
          message: config.errorMessage || `${key} has invalid format`
        });
        criticalErrors++;
      } else {
        warnings.push({
          type: 'INVALID_OPTIONAL',
          variable: key,
          message: config.errorMessage || `${key} has invalid format but is optional`
        });
      }
    }
  });

  // Additional security validations
  if (process.env.JWT_SECRET && process.env.JWT_SECRET.length < 64) {
    warnings.push({
      type: 'WEAK_SECRET',
      variable: 'JWT_SECRET',
      message: 'JWT_SECRET should be at least 64 characters for maximum security'
    });
  }

  // Check for common development variables in production
  if (process.env.NODE_ENV === 'production') {
    const devVariables = ['DEBUG', 'DEV_MODE', 'DEVELOPMENT'];
    devVariables.forEach(varName => {
      if (process.env[varName]) {
        warnings.push({
          type: 'DEV_VAR_IN_PROD',
          variable: varName,
          message: `Development variable ${varName} should not be set in production`
        });
      }
    });
  }

  return {
    success: criticalErrors === 0,
    errors,
    warnings,
    criticalErrors,
    summary: {
      total: Object.keys(REQUIRED_ENV_VARS).length,
      validated: Object.keys(REQUIRED_ENV_VARS).length - errors.length,
      errors: errors.length,
      warnings: warnings.length
    }
  };
};

/**
 * Print validation results
 * @param {Object} result - Validation result
 */
const printValidationResults = (result) => {
  const { success, errors, warnings, summary } = result;

  console.log('\n' + colors.blue('📋 Environment Validation Results:'));
  console.log(colors.green(`✅ Variables validated: ${summary.validated}/${summary.total}`));
  
  if (warnings.length > 0) {
    console.log(colors.yellow(`⚠️  Warnings: ${warnings.length}`));
    warnings.forEach(warning => {
      console.log(colors.yellow(`   • ${warning.variable}: ${warning.message}`));
    });
  }

  if (errors.length > 0) {
    console.log(colors.red(`❌ Errors: ${errors.length}`));
    errors.forEach(error => {
      console.log(colors.red(`   • ${error.variable}: ${error.message}`));
    });
  }

  if (success) {
    console.log(colors.green('✅ Environment validation passed!\n'));
  } else {
    console.log(colors.red('❌ Environment validation failed!\n'));
    console.log(colors.red('Please fix the above errors before starting the server.'));
    console.log(colors.blue('Refer to ENVIRONMENT_VARIABLES.md for configuration details.\n'));
  }
};

/**
 * Validate environment and exit on critical errors
 */
const validateAndExit = () => {
  const result = validateEnvironment();
  printValidationResults(result);

  if (!result.success) {
    process.exit(1);
  }

  return result;
};

/**
 * Get environment info for health checks
 */
const getEnvironmentInfo = () => {
  const info = {
    nodeVersion: process.version,
    nodeEnv: process.env.NODE_ENV || 'development',
    port: process.env.PORT || 5001,
    hasDatabase: !!process.env.MONGODB_URI,
    hasEmail: !!(process.env.SMTP_HOST && process.env.SMTP_USER),
    hasFirebase: !!(process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_SERVICE_ACCOUNT_KEY),
    timestamp: new Date().toISOString()
  };

  return info;
};

module.exports = {
  validateEnvironment,
  validateAndExit,
  printValidationResults,
  getEnvironmentInfo,
  REQUIRED_ENV_VARS
};
