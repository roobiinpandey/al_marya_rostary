/**
 * Secure File Upload Middleware
 * Comprehensive file upload security with type validation, size limits, and malware detection
 */

const multer = require('multer');
const path = require('path');
const crypto = require('crypto');
const fs = require('fs').promises;

// Allowed MIME types for images
const ALLOWED_IMAGE_MIME_TYPES = [
  'image/jpeg',
  'image/jpg', 
  'image/png',
  'image/gif',
  'image/webp',
  'image/svg+xml'
];

// Allowed file extensions
const ALLOWED_IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'];

// File size limits (in bytes)
const FILE_SIZE_LIMITS = {
  image: 5 * 1024 * 1024, // 5MB for images
  avatar: 2 * 1024 * 1024, // 2MB for avatar images
  slider: 10 * 1024 * 1024 // 10MB for slider images
};

// Dangerous file signatures (magic numbers) to block
const DANGEROUS_SIGNATURES = [
  { signature: Buffer.from([0x4D, 0x5A]), type: 'PE executable' }, // PE/EXE
  { signature: Buffer.from([0x50, 0x4B]), type: 'ZIP archive' }, // ZIP
  { signature: Buffer.from([0x7F, 0x45, 0x4C, 0x46]), type: 'ELF executable' }, // ELF
  { signature: Buffer.from([0xFF, 0xFE]), type: 'UTF-16 LE BOM' }, // Potentially malicious scripts
  { signature: Buffer.from([0xFE, 0xFF]), type: 'UTF-16 BE BOM' }, // Potentially malicious scripts
  { signature: Buffer.from([0x3C, 0x73, 0x63, 0x72, 0x69, 0x70, 0x74]), type: 'HTML script' }, // <script
  { signature: Buffer.from([0x3C, 0x68, 0x74, 0x6D, 0x6C]), type: 'HTML document' }, // <html
  { signature: Buffer.from([0x3C, 0x3F, 0x70, 0x68, 0x70]), type: 'PHP script' } // <?php
];

/**
 * Validate file signature against known image formats
 */
const validateImageSignature = (buffer) => {
  // JPEG
  if (buffer[0] === 0xFF && buffer[1] === 0xD8 && buffer[2] === 0xFF) {
    return { valid: true, format: 'JPEG' };
  }
  
  // PNG
  if (buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4E && buffer[3] === 0x47) {
    return { valid: true, format: 'PNG' };
  }
  
  // GIF
  if ((buffer[0] === 0x47 && buffer[1] === 0x49 && buffer[2] === 0x46) ||
      (buffer.slice(0, 6).toString() === 'GIF87a' || buffer.slice(0, 6).toString() === 'GIF89a')) {
    return { valid: true, format: 'GIF' };
  }
  
  // WebP
  if (buffer.slice(0, 4).toString() === 'RIFF' && buffer.slice(8, 12).toString() === 'WEBP') {
    return { valid: true, format: 'WebP' };
  }

  // SVG (check for XML declaration and svg tag)
  const bufferString = buffer.slice(0, 100).toString().toLowerCase();
  if (bufferString.includes('<svg') && (bufferString.includes('<?xml') || bufferString.includes('<svg'))) {
    return { valid: true, format: 'SVG' };
  }

  return { valid: false, format: null };
};

/**
 * Check for dangerous file signatures
 */
const checkForDangerousContent = (buffer) => {
  for (const danger of DANGEROUS_SIGNATURES) {
    if (buffer.slice(0, danger.signature.length).equals(danger.signature)) {
      return { dangerous: true, type: danger.type };
    }
  }

  // Check for embedded scripts in SVG
  const content = buffer.toString().toLowerCase();
  if (content.includes('<script') || content.includes('javascript:') || content.includes('onload=')) {
    return { dangerous: true, type: 'Embedded script' };
  }

  return { dangerous: false };
};

/**
 * Generate secure filename
 */
const generateSecureFilename = (originalname, userId = null) => {
  const ext = path.extname(originalname).toLowerCase();
  const basename = path.basename(originalname, ext);
  
  // Generate random filename to prevent conflicts and directory traversal
  const randomBytes = crypto.randomBytes(16).toString('hex');
  const timestamp = Date.now();
  const userPrefix = userId ? `u${userId}_` : '';
  
  return `${userPrefix}${timestamp}_${randomBytes}${ext}`;
};

/**
 * Configure multer storage with security
 */
const createSecureStorage = (uploadPath, options = {}) => {
  const {
    maxFileSize = FILE_SIZE_LIMITS.image,
    allowedMimeTypes = ALLOWED_IMAGE_MIME_TYPES,
    allowedExtensions = ALLOWED_IMAGE_EXTENSIONS
  } = options;

  const storage = multer.diskStorage({
    destination: async (req, file, cb) => {
      try {
        // Ensure upload directory exists
        await fs.mkdir(uploadPath, { recursive: true });
        cb(null, uploadPath);
      } catch (error) {
        console.error('Failed to create upload directory:', error);
        cb(new Error('Upload directory creation failed'), null);
      }
    },
    
    filename: (req, file, cb) => {
      try {
        const secureFilename = generateSecureFilename(file.originalname, req.user?.userId);
        cb(null, secureFilename);
      } catch (error) {
        console.error('Failed to generate secure filename:', error);
        cb(new Error('Filename generation failed'), null);
      }
    }
  });

  const fileFilter = (req, file, cb) => {
    try {
      // Check MIME type
      if (!allowedMimeTypes.includes(file.mimetype)) {
        return cb(new Error(`Invalid file type. Allowed types: ${allowedMimeTypes.join(', ')}`), false);
      }

      // Check file extension
      const ext = path.extname(file.originalname).toLowerCase();
      if (!allowedExtensions.includes(ext)) {
        return cb(new Error(`Invalid file extension. Allowed extensions: ${allowedExtensions.join(', ')}`), false);
      }

      // Check for dangerous filenames
      const filename = path.basename(file.originalname);
      if (filename.includes('..') || filename.includes('/') || filename.includes('\\')) {
        return cb(new Error('Invalid filename detected'), false);
      }

      cb(null, true);
    } catch (error) {
      cb(new Error('File validation failed'), false);
    }
  };

  return multer({
    storage: storage,
    limits: {
      fileSize: maxFileSize,
      files: 1, // Only allow single file uploads
      fields: 10, // Limit number of fields
      fieldNameSize: 100, // Limit field name size
      fieldSize: 1024 * 1024 // Limit field value size to 1MB
    },
    fileFilter: fileFilter
  });
};

/**
 * Post-upload file validation middleware
 */
const validateUploadedFile = async (req, res, next) => {
  try {
    if (!req.file) {
      return next();
    }

    const filePath = req.file.path;
    
    // Read first 100 bytes for signature validation
    const fileHandle = await fs.open(filePath, 'r');
    const buffer = Buffer.alloc(100);
    await fileHandle.read(buffer, 0, 100, 0);
    await fileHandle.close();

    // Validate image signature
    const signatureValidation = validateImageSignature(buffer);
    if (!signatureValidation.valid) {
      // Delete invalid file
      await fs.unlink(filePath);
      return res.status(400).json({
        success: false,
        message: 'Invalid image format detected'
      });
    }

    // Check for dangerous content
    const dangerCheck = checkForDangerousContent(buffer);
    if (dangerCheck.dangerous) {
      // Delete dangerous file
      await fs.unlink(filePath);
      console.warn(`Dangerous file upload attempt blocked: ${dangerCheck.type}`, {
        originalName: req.file.originalname,
        mimetype: req.file.mimetype,
        ip: req.ip,
        userId: req.user?.userId,
        timestamp: new Date().toISOString()
      });
      
      return res.status(400).json({
        success: false,
        message: 'File contains prohibited content'
      });
    }

    // Add validation results to request
    req.file.validation = {
      signatureValid: true,
      format: signatureValidation.format,
      safe: true
    };

    next();
  } catch (error) {
    console.error('File validation error:', error);
    
    // Clean up file if it exists
    if (req.file?.path) {
      try {
        await fs.unlink(req.file.path);
      } catch (unlinkError) {
        console.error('Failed to delete invalid file:', unlinkError);
      }
    }

    return res.status(500).json({
      success: false,
      message: 'File validation failed'
    });
  }
};

/**
 * Create secure upload middleware for different file types
 */
const secureFileUpload = {
  // For general images
  image: (uploadPath) => [
    createSecureStorage(uploadPath, {
      maxFileSize: FILE_SIZE_LIMITS.image,
      allowedMimeTypes: ALLOWED_IMAGE_MIME_TYPES,
      allowedExtensions: ALLOWED_IMAGE_EXTENSIONS
    }).single('image'),
    validateUploadedFile
  ],

  // For slider images (larger size limit)
  slider: (uploadPath) => [
    createSecureStorage(uploadPath, {
      maxFileSize: FILE_SIZE_LIMITS.slider,
      allowedMimeTypes: ALLOWED_IMAGE_MIME_TYPES,
      allowedExtensions: ALLOWED_IMAGE_EXTENSIONS
    }).single('image'),
    validateUploadedFile
  ],

  // For avatar images (smaller size limit)
  avatar: (uploadPath) => [
    createSecureStorage(uploadPath, {
      maxFileSize: FILE_SIZE_LIMITS.avatar,
      allowedMimeTypes: ALLOWED_IMAGE_MIME_TYPES.filter(type => type !== 'image/svg+xml'), // No SVG for avatars
      allowedExtensions: ALLOWED_IMAGE_EXTENSIONS.filter(ext => ext !== '.svg')
    }).single('avatar'),
    validateUploadedFile
  ]
};

module.exports = {
  secureFileUpload,
  validateImageSignature,
  checkForDangerousContent,
  generateSecureFilename,
  validateUploadedFile,
  FILE_SIZE_LIMITS,
  ALLOWED_IMAGE_MIME_TYPES,
  ALLOWED_IMAGE_EXTENSIONS
};
