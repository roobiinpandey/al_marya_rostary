# Hero Banner/Slider Creation API Examples

## 🎯 **API Endpoint**
```
POST https://***REMOVED***.onrender.com/api/sliders
```

## 📝 **Required Fields**
- **image**: Image file (required)
- **title**: Slider title (required, 2-100 characters)

## 🔧 **Optional Fields**
- **description**: Description text (max 300 characters)
- **buttonText**: Call-to-action button text (max 50 characters)
- **buttonLink**: URL for the button link
- **backgroundColor**: Hex color code (e.g., #FF5733)
- **textColor**: Hex color code (e.g., #FFFFFF)
- **position**: Text position (left, center, right)
- **displayOrder**: Order number for display (integer)
- **startDate**: Start date (ISO 8601 format)
- **endDate**: End date (ISO 8601 format)
- **mobileImage**: Separate image for mobile devices
- **isActive**: Boolean (true/false)

## 🚀 **Example 1: Basic Slider Creation**

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -F "image=@/path/to/your/banner-image.jpg" \
  -F "title=Welcome to Qahwat Al Emarat" \
  -F "description=Discover the finest Arabic coffee experience" \
  -F "buttonText=Order Now" \
  -F "buttonLink=https://***REMOVED***.com/menu" \
  -F "backgroundColor=#8B4513" \
  -F "textColor=#FFFFFF" \
  -F "position=center" \
  -F "displayOrder=1" \
  -F "isActive=true" \
  https://***REMOVED***.onrender.com/api/sliders
```

## 🎨 **Example 2: Advanced Slider with Mobile Image**

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -F "image=@/path/to/desktop-banner.jpg" \
  -F "mobileImage=@/path/to/mobile-banner.jpg" \
  -F "title=Special Ramadan Offer" \
  -F "description=Enjoy 25% off on all traditional Arabic coffee blends during Ramadan" \
  -F "buttonText=Grab Offer" \
  -F "buttonLink=https://***REMOVED***.com/ramadan-special" \
  -F "backgroundColor=#2E8B57" \
  -F "textColor=#FFFFFF" \
  -F "position=left" \
  -F "displayOrder=2" \
  -F "startDate=2025-03-10T00:00:00.000Z" \
  -F "endDate=2025-04-10T23:59:59.000Z" \
  -F "isActive=true" \
  https://***REMOVED***.onrender.com/api/sliders
```

## 🔄 **Example 3: Update Existing Slider**

```bash
curl -X PUT \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -F "image=@/path/to/new-image.jpg" \
  -F "title=Updated Coffee Experience" \
  -F "description=New flavors, same authentic taste" \
  -F "buttonText=Explore Now" \
  -F "displayOrder=1" \
  https://***REMOVED***.onrender.com/api/sliders/SLIDER_ID_HERE
```

## 📱 **Example 4: JavaScript/Frontend Implementation**

```javascript
async function createSlider(sliderData, imageFile, mobileImageFile = null) {
    const formData = new FormData();
    
    // Add image files
    formData.append('image', imageFile);
    if (mobileImageFile) {
        formData.append('mobileImage', mobileImageFile);
    }
    
    // Add text data
    Object.keys(sliderData).forEach(key => {
        formData.append(key, sliderData[key]);
    });
    
    try {
        const response = await fetch('https://***REMOVED***.onrender.com/api/sliders', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${adminToken}`
            },
            body: formData
        });
        
        const result = await response.json();
        
        if (result.success) {
            console.log('Slider created successfully:', result.data);
            return result.data;
        } else {
            console.error('Failed to create slider:', result.message);
            throw new Error(result.message);
        }
    } catch (error) {
        console.error('Error creating slider:', error);
        throw error;
    }
}

// Usage example
const sliderData = {
    title: 'Premium Arabic Coffee',
    description: 'Authentic taste from the heart of Arabia',
    buttonText: 'Order Now',
    buttonLink: 'https://***REMOVED***.com/menu',
    backgroundColor: '#8B4513',
    textColor: '#FFFFFF',
    position: 'center',
    displayOrder: 1,
    isActive: true
};

// Get file from input element
const imageInput = document.getElementById('sliderImage');
const imageFile = imageInput.files[0];

createSlider(sliderData, imageFile);
```

## 🎯 **Example 5: Python Implementation**

```python
import requests

def create_slider(admin_token, image_path, slider_data, mobile_image_path=None):
    url = 'https://***REMOVED***.onrender.com/api/sliders'
    
    headers = {
        'Authorization': f'Bearer {admin_token}'
    }
    
    files = {
        'image': open(image_path, 'rb')
    }
    
    if mobile_image_path:
        files['mobileImage'] = open(mobile_image_path, 'rb')
    
    try:
        response = requests.post(url, headers=headers, files=files, data=slider_data)
        result = response.json()
        
        if result.get('success'):
            print('Slider created successfully:', result.get('data'))
            return result.get('data')
        else:
            print('Failed to create slider:', result.get('message'))
            return None
            
    except Exception as e:
        print(f'Error creating slider: {e}')
        return None
    
    finally:
        # Close file handles
        for file in files.values():
            file.close()

# Usage
slider_data = {
    'title': 'Fresh Coffee Daily',
    'description': 'Roasted fresh every morning for the perfect cup',
    'buttonText': 'View Menu',
    'buttonLink': 'https://***REMOVED***.com/menu',
    'backgroundColor': '#D2691E',
    'textColor': '#FFFFFF',
    'position': 'right',
    'displayOrder': 3,
    'isActive': 'true'
}

create_slider(
    admin_token='YOUR_ADMIN_TOKEN',
    image_path='/path/to/coffee-banner.jpg',
    slider_data=slider_data
)
```

## 📋 **Testing Your Sliders**

After creating sliders, test them using:

```bash
# Get all sliders
curl -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  https://***REMOVED***.onrender.com/api/sliders

# Get specific slider
curl -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  https://***REMOVED***.onrender.com/api/sliders/SLIDER_ID

# Delete slider
curl -X DELETE \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  https://***REMOVED***.onrender.com/api/sliders/SLIDER_ID
```

## 🎨 **Image Recommendations**

- **Desktop Images**: 1920x600px or 1200x400px (16:9 ratio recommended)
- **Mobile Images**: 800x600px or 600x400px (4:3 ratio recommended)
- **Format**: JPG, PNG, WebP
- **Size**: Max 10MB per image
- **Quality**: High resolution for crisp display

## 🔒 **Authentication Required**

All slider operations require admin authentication. Use your admin JWT token in the Authorization header.
