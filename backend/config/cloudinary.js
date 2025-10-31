const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');

// Configure Cloudinary with environment variables
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Cloudinary storage for slider images
const sliderStorage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'al-marya/sliders',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation: [
      { width: 1920, height: 1080, crop: 'limit', quality: 'auto:good' }
    ],
    public_id: (req, file) => {
      const timestamp = Date.now();
      const random = Math.floor(Math.random() * 1000000000);
      return `slider-${timestamp}-${random}`;
    },
  },
});

// Cloudinary storage for mobile slider images
const mobileSliderStorage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'al-marya/sliders/mobile',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation: [
      { width: 1080, height: 1920, crop: 'limit', quality: 'auto:good' }
    ],
    public_id: (req, file) => {
      const timestamp = Date.now();
      const random = Math.floor(Math.random() * 1000000000);
      return `slider-mobile-${timestamp}-${random}`;
    },
  },
});

// Cloudinary storage for product images
const productStorage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'al-marya/products',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation: [
      { width: 1000, height: 1000, crop: 'limit', quality: 'auto:good' }
    ],
    public_id: (req, file) => {
      const timestamp = Date.now();
      const random = Math.floor(Math.random() * 1000000000);
      return `product-${timestamp}-${random}`;
    },
  },
});

// Cloudinary storage for category images
const categoryStorage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'al-marya/categories',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation: [
      { width: 800, height: 800, crop: 'limit', quality: 'auto:good' }
    ],
    public_id: (req, file) => {
      const timestamp = Date.now();
      const random = Math.floor(Math.random() * 1000000000);
      return `category-${timestamp}-${random}`;
    },
  },
});

// Helper function to delete image from Cloudinary
const deleteImage = async (imageUrl) => {
  try {
    // Extract public_id from Cloudinary URL
    // URL format: https://res.cloudinary.com/cloud_name/image/upload/v123456/folder/image.jpg
    const urlParts = imageUrl.split('/');
    const uploadIndex = urlParts.indexOf('upload');
    
    if (uploadIndex === -1) {
      console.log('⚠️ Not a Cloudinary URL, skipping deletion:', imageUrl);
      return;
    }

    // Get everything after 'upload/v123456/'
    const pathAfterUpload = urlParts.slice(uploadIndex + 2).join('/');
    // Remove file extension to get public_id
    const publicId = pathAfterUpload.replace(/\.[^/.]+$/, '');

    console.log('🗑️ Deleting image from Cloudinary:', publicId);
    const result = await cloudinary.uploader.destroy(publicId);
    console.log('✅ Cloudinary deletion result:', result);
    
    return result;
  } catch (error) {
    console.error('❌ Error deleting image from Cloudinary:', error);
    throw error;
  }
};

// Helper function to get optimized image URL
const getOptimizedImageUrl = (publicId, options = {}) => {
  const {
    width = 800,
    height = 800,
    crop = 'limit',
    quality = 'auto:good',
    format = 'auto'
  } = options;

  return cloudinary.url(publicId, {
    transformation: [
      { width, height, crop, quality, fetch_format: format }
    ]
  });
};

module.exports = {
  cloudinary,
  sliderStorage,
  mobileSliderStorage,
  productStorage,
  categoryStorage,
  deleteImage,
  getOptimizedImageUrl,
};
