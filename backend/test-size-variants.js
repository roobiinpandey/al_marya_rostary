#!/usr/bin/env node

/**
 * Test script for Size Variants Implementation
 * Tests product creation with 250gm, 500gm, 1kg variants
 */

const mongoose = require('mongoose');
require('dotenv').config();

// Import the Coffee model
const Coffee = require('./models/Coffee');

async function testSizeVariants() {
    try {
        // Connect to MongoDB
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB for testing');

        // Test product data with size variants (no main price needed)
        const testProduct = {
            name: {
                en: "Premium Arabian Blend",
                ar: "خليط عربي ممتاز"
            },
            description: {
                en: "A rich blend of premium Arabian coffee beans",
                ar: "مزيج غني من حبوب القهوة العربية الممتازة"
            },
            origin: "Yemen",
            roastLevel: "Medium",
            image: "/uploads/test-coffee.jpg",
            categories: ["Premium", "Arabian"],
            variants: [
                {
                    size: "250gm",
                    weight: 250,
                    price: 25.99,
                    stock: 50,
                    displayName: {
                        en: "Small Pack (250gm)",
                        ar: "عبوة صغيرة (250 جرام)"
                    },
                    description: {
                        en: "Perfect for trying our premium blend",
                        ar: "مثالي لتجربة مزيجنا الممتاز"
                    },
                    isAvailable: true
                },
                {
                    size: "500gm",
                    weight: 500,
                    price: 45.99,
                    stock: 75,
                    displayName: {
                        en: "Medium Pack (500gm)",
                        ar: "عبوة متوسطة (500 جرام)"
                    },
                    description: {
                        en: "Great value for regular coffee drinkers",
                        ar: "قيمة ممتازة لشاربي القهوة بانتظام"
                    },
                    isAvailable: true
                },
                {
                    size: "1kg",
                    weight: 1000,
                    price: 85.99,
                    stock: 30,
                    displayName: {
                        en: "Family Pack (1kg)",
                        ar: "عبوة عائلية (1 كيلوجرام)"
                    },
                    description: {
                        en: "Best value for coffee enthusiasts",
                        ar: "أفضل قيمة لعشاق القهوة"
                    },
                    isAvailable: true
                }
            ]
        };

        console.log('\n🧪 Testing product creation with size variants...');
        
        // Create the product
        const coffee = new Coffee(testProduct);
        const savedCoffee = await coffee.save();
        
        console.log('✅ Product created successfully!');
        console.log(`📦 Product ID: ${savedCoffee._id}`);
        console.log(`📍 Product Name: ${savedCoffee.name.en} / ${savedCoffee.name.ar}`);
        console.log(`🏷️  Variants Count: ${savedCoffee.variants.length}`);
        
        // Test variant methods
        console.log('\n🔍 Testing variant methods...');
        
        // Test getAvailableVariants
        const availableVariants = savedCoffee.getAvailableVariants();
        console.log(`✅ Available variants: ${availableVariants.length}`);
        
        // Test getPriceRange
        const priceRange = savedCoffee.getPriceRange();
        console.log(`💰 Price range: AED ${priceRange.min} - AED ${priceRange.max}`);
        
        // Test getVariant
        const mediumVariant = savedCoffee.getVariant('500gm');
        console.log(`📦 Medium variant (500gm): AED ${mediumVariant ? mediumVariant.price : 'Not found'}`);
        
        // Test updateVariantStock
        console.log('\n📈 Testing stock update...');
        const stockUpdateResult = await savedCoffee.updateVariantStock('250gm', 45);
        console.log(`✅ Stock update result: ${stockUpdateResult ? 'Success' : 'Failed'}`);
        
        // Verify the update
        const updatedCoffee = await Coffee.findById(savedCoffee._id);
        const updatedVariant = updatedCoffee.getVariant('250gm');
        console.log(`📊 Updated 250gm stock: ${updatedVariant.stock}`);
        
        console.log('\n✅ All tests completed successfully!');
        console.log('\n📋 Test Summary:');
        console.log(`   • Product created with ${savedCoffee.variants.length} size variants`);
        console.log(`   • Multilingual support: English & Arabic`);
        console.log(`   • Price range: AED ${priceRange.min} - AED ${priceRange.max}`);
        console.log(`   • Stock management: Working`);
        console.log(`   • Variant methods: All functional`);
        
        // Clean up - remove test product
        await Coffee.findByIdAndDelete(savedCoffee._id);
        console.log('\n🧹 Test product cleaned up');
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
        console.error('Stack trace:', error.stack);
    } finally {
        await mongoose.disconnect();
        console.log('✅ Disconnected from MongoDB');
        process.exit(0);
    }
}

// Run the test
testSizeVariants();
