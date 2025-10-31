# API Sample Responses - Dynamic Attributes

## Quick Reference

All API endpoints return JSON with this structure:
```json
{
  "success": true/false,
  "count": number,  // Total items
  "data": []        // Array of items
}
```

---

## 1. Get All Attribute Groups

**Endpoint:** `GET /api/attributes/groups`

**What you get:** List of all 4 attribute groups

**Sample Response:**
```json
{
  "success": true,
  "count": 4,
  "data": [
    {
      "key": "origin_countries",
      "name": { "en": "Origin Countries", "ar": "بلد المنشأ" },
      "icon": "🌍",
      "color": "#4CAF50",
      "valueCount": 22,
      "type": "single-select"
    },
    {
      "key": "roast_levels",
      "name": { "en": "Roast Levels", "ar": "مستويات التحميص" },
      "icon": "☀️",
      "valueCount": 5
    }
    // ... 2 more groups
  ]
}
```

---

## 2. Get Origin Countries (Hierarchical)

**Endpoint:** `GET /api/attributes/origin_countries/values?hierarchical=true`

**What you get:** Countries grouped by regions

**Sample Response:**
```json
{
  "success": true,
  "count": 4,
  "data": [
    {
      "value": "africa",
      "name": { "en": "Africa", "ar": "أفريقيا" },
      "children": [
        {
          "value": "ethiopia",
          "name": { "en": "Ethiopia", "ar": "إثيوبيا" },
          "icon": "🇪🇹",
          "metadata": { "altitude": "1500-2200m" }
        },
        {
          "value": "kenya",
          "name": { "en": "Kenya", "ar": "كينيا" },
          "icon": "🇰🇪"
        }
      ]
    },
    {
      "value": "latin_america",
      "name": { "en": "Latin America", "ar": "أمريكا اللاتينية" },
      "children": [
        {
          "value": "colombia",
          "name": { "en": "Colombia", "ar": "كولومبيا" },
          "icon": "🇨🇴"
        }
      ]
    }
  ]
}
```

---

## 3. Get Roast Levels

**Endpoint:** `GET /api/attributes/roast_levels/values`

**What you get:** 5 roast levels with icons

**Sample Response:**
```json
{
  "success": true,
  "count": 5,
  "data": [
    {
      "value": "light",
      "name": { "en": "Light Roast", "ar": "تحميص خفيف" },
      "icon": "☀️",
      "displayOrder": 1
    },
    {
      "value": "medium",
      "name": { "en": "Medium Roast", "ar": "تحميص متوسط" },
      "icon": "☁️",
      "displayOrder": 3
    },
    {
      "value": "dark",
      "name": { "en": "Dark Roast", "ar": "تحميص داكن" },
      "icon": "🌑",
      "displayOrder": 5
    }
  ]
}
```

---

## 4. Get Flavor Profiles

**Endpoint:** `GET /api/attributes/flavor_profiles/values`

**What you get:** 12 flavors with icons and colors

**Sample Response:**
```json
{
  "success": true,
  "count": 12,
  "data": [
    {
      "value": "fruity",
      "name": { "en": "Fruity", "ar": "فواكهي" },
      "icon": "🍓",
      "color": "#FF6B6B"
    },
    {
      "value": "nutty",
      "name": { "en": "Nutty", "ar": "مكسرات" },
      "icon": "🌰",
      "color": "#8B4513"
    },
    {
      "value": "chocolate",
      "name": { "en": "Chocolate", "ar": "شوكولاتة" },
      "icon": "🍫",
      "color": "#5D4037"
    }
    // ... 9 more flavors
  ]
}
```

---

## 5. Get with Arabic Localization

**Endpoint:** `GET /api/attributes/roast_levels/values?language=ar`

**What you get:** Same data but with Arabic as primary language

**Sample Response:**
```json
{
  "success": true,
  "count": 5,
  "data": [
    {
      "value": "light",
      "localizedName": "تحميص خفيف",
      "localizedDescription": "بني فاتح، بدون زيت",
      "icon": "☀️"
    }
  ]
}
```

---

## Quick Test Commands

```bash
# Test all APIs at once
curl -s http://localhost:5001/api/attributes/groups
curl -s http://localhost:5001/api/attributes/origin_countries/values?hierarchical=true
curl -s http://localhost:5001/api/attributes/roast_levels/values
curl -s http://localhost:5001/api/attributes/processing_methods/values
curl -s http://localhost:5001/api/attributes/flavor_profiles/values
```

---

## Query Parameters

- `?hierarchical=true` - Nested structure (origins only)
- `?language=ar` - Arabic names
- `?language=en` - English names (default)
- `?active=true` - Only active items

---

*All endpoints tested and working ✅*
*Last Updated: January 27, 2025*
