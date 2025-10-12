#!/bin/bash

# Create a temporary test image
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > /tmp/test-coffee.png

# Test the API with multipart form data
curl -X POST http://localhost:5001/api/coffees \
  -F "nameEn=API Test Coffee v2" \
  -F "nameAr=قهوة تجربة API النسخة الثانية" \
  -F "descriptionEn=Testing API with variants functionality - complete multilingual support with size variants" \
  -F "descriptionAr=اختبار API مع وظيفة المتغيرات - دعم متعدد اللغات كامل مع متغيرات الحجم" \
  -F "origin=Ethiopia" \
  -F "roastLevel=Medium" \
  -F "categories=[\"Test\", \"Premium\"]" \
  -F "variants=[{\"size\":\"250gm\",\"weight\":250,\"price\":22.99,\"stock\":40,\"displayName\":{\"en\":\"Small (250gm)\",\"ar\":\"صغير (250 جرام)\"},\"description\":{\"en\":\"Perfect for trying new flavors\",\"ar\":\"مثالي لتجربة نكهات جديدة\"},\"isAvailable\":true},{\"size\":\"500gm\",\"weight\":500,\"price\":39.99,\"stock\":30,\"displayName\":{\"en\":\"Medium (500gm)\",\"ar\":\"متوسط (500 جرام)\"},\"description\":{\"en\":\"Perfect for regular consumption\",\"ar\":\"مثالي للاستهلاك المنتظم\"},\"isAvailable\":true},{\"size\":\"1kg\",\"weight\":1000,\"price\":74.99,\"stock\":20,\"displayName\":{\"en\":\"Large (1kg)\",\"ar\":\"كبير (1 كيلوجرام)\"},\"description\":{\"en\":\"Best value for families\",\"ar\":\"أفضل قيمة للعائلات\"},\"isAvailable\":true}]" \
  -F "image=@/tmp/test-coffee.png" | jq .

# Clean up
rm /tmp/test-coffee.png
