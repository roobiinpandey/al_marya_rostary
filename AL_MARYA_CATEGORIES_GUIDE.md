# 🏷️ Al Marya Rostery Categories Documentation

## Overview
Al Marya Rostery categories have been organized to reflect the authentic coffee bean origins and roasting expertise that define our brand. Our categories are designed around the three major coffee-growing regions of the world plus our premium selections.

## 📍 Origin-Based Categories

### 🌏 Asia
**Color**: Saddle Brown (`#8B4513`)  
**Icon**: `public`  
**Description**: Premium coffee beans from Asian coffee-growing regions including Indonesia, Vietnam, India, and Papua New Guinea  
**Arabic**: آسيا

**Featured Products:**
- Java Estate Arabica (Indonesia) - Medium-Dark Roast
- Malabar Monsoon Premium (India) - Medium Roast

### 🌍 Africa
**Color**: Peru (`#CD853F`)  
**Icon**: `terrain`  
**Description**: Exceptional coffee beans from the birthplace of coffee - Ethiopia, Kenya, Tanzania, and other African highlands  
**Arabic**: أفريقيا

**Featured Products:**
- Ethiopian Yirgacheffe - Medium Roast
- Kenyan AA Premium - Medium-Dark Roast

### 🌎 Latin America
**Color**: Sienna (`#A0522D`)  
**Icon**: `language`  
**Description**: Rich and diverse coffee beans from Central and South America including Colombia, Brazil, Guatemala, and Costa Rica  
**Arabic**: أمريكا اللاتينية

**Featured Products:**
- Colombian Supremo - Medium Roast
- Guatemala Antigua Premium - Dark Roast

## ⭐ Premium Category

### 💎 Premium
**Color**: Goldenrod (`#DAA520`)  
**Icon**: `diamond`  
**Description**: Our finest selection of rare, limited-edition, and expertly curated coffee beans from around the world  
**Arabic**: بريميوم

**Featured Products:**
- Al Marya Reserve Blend (Multi-Origin) - Medium-Dark Roast
- Heritage Organic Blend (Multi-Origin) - Dark Roast

## 🔥 Roast Level Categories

### 🌙 Dark Roast
**Color**: Very Dark Brown (`#2F1B14`)  
**Icon**: `nights_stay`  
**Description**: Bold, intense coffee with rich, smoky flavors and low acidity  
**Arabic**: التحميص الداكن

### 🌆 Medium Dark Roast
**Color**: Brown 700 (`#5D4037`)  
**Icon**: `wb_twilight`  
**Description**: Balanced coffee with slightly bittersweet aftertaste, fuller body, and reduced acidity  
**Arabic**: التحميص المتوسط الداكن

### ☀️ Medium Roast
**Color**: Brown 400 (`#8D6E63`)  
**Icon**: `wb_sunny`  
**Description**: Well-balanced coffee with moderate acidity and body, preserving original flavors  
**Arabic**: التحميص المتوسط

## 🏆 Specialty Categories

### 📍 Single Origin
**Color**: Brown 500 (`#795548`)  
**Icon**: `place`  
**Description**: Coffee beans from a single farm, region, or country, showcasing unique terroir  
**Arabic**: منشأ واحد

### 🌾 Blends
**Color**: Brown 600 (`#6D4C41`)  
**Icon**: `grain`  
**Description**: Expertly crafted coffee blends combining beans from different origins  
**Arabic**: الخلطات

### 🌱 Organic
**Color**: Light Green 700 (`#689F38`)  
**Icon**: `eco`  
**Description**: Certified organic coffee beans grown without synthetic pesticides or fertilizers  
**Arabic**: عضوي

## 💰 Pricing Structure

### Size Variants Available:
- **250gm**: Entry-level size, perfect for trying new varieties
- **500gm**: Most popular size for regular consumption
- **1kg**: Bulk size for coffee enthusiasts and businesses

### Price Ranges:
- **Standard Origin**: $42.99 - $48.99 (250gm)
- **Premium Selection**: $49.99 - $55.99 (250gm)
- **Signature Blends**: $51.99 - $55.99 (250gm)

## 🎯 Usage Guidelines

### For Customers:
- Browse by **origin** to explore different coffee regions
- Filter by **roast level** to match your taste preference
- Check **Premium** for special occasions and gifts
- Look for **Organic** for sustainably grown options

### For Admin Management:
- Categories support bilingual content (English/Arabic)
- Each category has custom colors for visual branding
- Display order can be customized (1-10 currently)
- SEO-friendly slugs are auto-generated

### For Marketing:
- **Asia**: Focus on unique processing methods and exotic flavors
- **Africa**: Emphasize the birthplace of coffee and bright, complex flavors
- **Latin America**: Highlight classic, well-balanced profiles
- **Premium**: Position as luxury gifts and special occasions

## 🔄 Integration Points

### Frontend App:
- Category filtering in browse page
- Quick access through home page quick categories
- Product detail pages show all applicable categories
- Search functionality includes category matching

### Backend Admin:
- Full CRUD operations for categories
- Product assignment to multiple categories
- Analytics by category performance
- Inventory management by category

### API Endpoints:
- `GET /api/categories` - List all categories
- `GET /api/coffees?category=Asia` - Filter products by category
- `GET /api/categories/:id/products` - Get all products in a category
- `GET /api/categories/stats` - Category performance analytics

---

*Last Updated: October 27, 2025*  
*Al Marya Rostery - Premium Coffee Experience*
