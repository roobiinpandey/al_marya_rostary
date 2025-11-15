const mongoose = require('mongoose');

/**
 * Wishlist Schema - User's favorite products
 * Supports multiple product types: Coffee, Accessories, Gift Sets
 */
const wishlistSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    items: [
      {
        productId: {
          type: mongoose.Schema.Types.ObjectId,
          required: true,
        },
        productType: {
          type: String,
          enum: ['Coffee', 'Accessory', 'GiftSet'],
          required: true,
        },
        addedAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],
  },
  {
    timestamps: true,
  }
);

// Compound index for efficient lookups
wishlistSchema.index({ userId: 1, 'items.productId': 1 });

/**
 * Get wishlist for a user (create if doesn't exist)
 */
wishlistSchema.statics.getOrCreate = async function (userId) {
  let wishlist = await this.findOne({ userId });
  if (!wishlist) {
    wishlist = await this.create({ userId, items: [] });
  }
  return wishlist;
};

/**
 * Add item to wishlist
 */
wishlistSchema.methods.addItem = async function (productId, productType) {
  // Check if already exists
  const exists = this.items.some(
    (item) => item.productId.toString() === productId.toString()
  );

  if (!exists) {
    this.items.push({
      productId,
      productType,
      addedAt: new Date(),
    });
    await this.save();
  }

  return this;
};

/**
 * Remove item from wishlist
 */
wishlistSchema.methods.removeItem = async function (productId) {
  this.items = this.items.filter(
    (item) => item.productId.toString() !== productId.toString()
  );
  await this.save();
  return this;
};

/**
 * Check if item is in wishlist
 */
wishlistSchema.methods.hasItem = function (productId) {
  return this.items.some(
    (item) => item.productId.toString() === productId.toString()
  );
};

/**
 * Clear all items
 */
wishlistSchema.methods.clearAll = async function () {
  this.items = [];
  await this.save();
  return this;
};

/**
 * Get item count
 */
wishlistSchema.methods.getCount = function () {
  return this.items.length;
};

const Wishlist = mongoose.model('Wishlist', wishlistSchema);

module.exports = Wishlist;
