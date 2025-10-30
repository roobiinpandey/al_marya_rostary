# MongoDB Atlas Address Storage Implementation Plan

## Current Status: LOCAL STORAGE ONLY ❌

**Answer**: No, saved addresses (Home/Work/etc.) are currently stored **locally on the device** using SharedPreferences, not in MongoDB Atlas.

### Current Implementation:
- **Storage**: SharedPreferences (device-specific)
- **Scope**: Per-device only
- **Persistence**: Lost when app uninstalled
- **Sync**: No cross-device synchronization

## Required Changes for MongoDB Atlas Storage ✅

### 1. Backend API Endpoints (Node.js + MongoDB)

#### **POST /api/users/:userId/addresses** - Save Address
```javascript
// backend/routes/addresses.js
const express = require('express');
const router = express.Router();
const Address = require('../models/Address');

// Save new address for user
router.post('/users/:userId/addresses', async (req, res) => {
  try {
    const { userId } = req.params;
    const {
      name,
      fullAddress,
      latitude,
      longitude,
      buildingDetails,
      landmark,
      type, // 'home', 'work', 'other'
      isDefault
    } = req.body;

    // Check for duplicate addresses (within 50m)
    const existingAddresses = await Address.find({ userId });
    const isDuplicate = existingAddresses.some(addr => {
      const distance = calculateDistance(
        addr.latitude, addr.longitude,
        latitude, longitude
      );
      return distance < 0.05; // 50 meters
    });

    if (isDuplicate) {
      return res.status(400).json({
        success: false,
        message: 'Address already exists at this location'
      });
    }

    // If setting as default, unset other defaults
    if (isDefault) {
      await Address.updateMany(
        { userId },
        { $set: { isDefault: false } }
      );
    }

    const address = new Address({
      userId,
      name,
      fullAddress,
      latitude,
      longitude,
      buildingDetails,
      landmark,
      type,
      isDefault: isDefault || existingAddresses.length === 0, // First address is default
      createdAt: new Date()
    });

    await address.save();

    res.json({
      success: true,
      data: address,
      message: 'Address saved successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to save address',
      error: error.message
    });
  }
});
```

#### **GET /api/users/:userId/addresses** - Get User Addresses
```javascript
// Get all addresses for user
router.get('/users/:userId/addresses', async (req, res) => {
  try {
    const { userId } = req.params;
    const addresses = await Address.find({ userId })
      .sort({ createdAt: -1 }); // Most recent first

    res.json({
      success: true,
      data: addresses,
      count: addresses.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch addresses',
      error: error.message
    });
  }
});
```

#### **PUT /api/users/:userId/addresses/:addressId** - Update Address
#### **DELETE /api/users/:userId/addresses/:addressId** - Delete Address
#### **PUT /api/users/:userId/addresses/:addressId/default** - Set Default

### 2. MongoDB Address Schema

```javascript
// backend/models/Address.js
const mongoose = require('mongoose');

const addressSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  fullAddress: {
    type: String,
    required: true
  },
  latitude: {
    type: Number,
    required: true
  },
  longitude: {
    type: Number,
    required: true
  },
  buildingDetails: {
    type: String,
    trim: true
  },
  landmark: {
    type: String,
    trim: true
  },
  type: {
    type: String,
    enum: ['home', 'work', 'other'],
    default: 'other'
  },
  isDefault: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Compound index for user + coordinates (prevent duplicates)
addressSchema.index({ userId: 1, latitude: 1, longitude: 1 });

// Ensure only one default address per user
addressSchema.pre('save', async function(next) {
  if (this.isDefault && this.isModified('isDefault')) {
    await mongoose.model('Address').updateMany(
      { userId: this.userId, _id: { $ne: this._id } },
      { $set: { isDefault: false } }
    );
  }
  this.updatedAt = new Date();
  next();
});

module.exports = mongoose.model('Address', addressSchema);
```

### 3. Flutter Service Update

```dart
// lib/services/address_service.dart - Updated for MongoDB
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/saved_address.dart';
import '../core/config/api_config.dart';

class AddressService {
  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  List<SavedAddress> _cachedAddresses = [];
  String? _currentUserId;

  // Set current user ID (from auth provider)
  void setUserId(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _cachedAddresses.clear(); // Clear cache on user change
    }
  }

  /// Get all saved addresses from MongoDB
  Future<List<SavedAddress>> getSavedAddresses() async {
    if (_currentUserId == null) return [];
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$_currentUserId/addresses'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _cachedAddresses = (data['data'] as List)
              .map((json) => SavedAddress.fromJson(json))
              .toList();
          return _cachedAddresses;
        }
      }
      
      throw Exception('Failed to load addresses');
    } catch (e) {
      print('Error loading addresses: $e');
      return [];
    }
  }

  /// Save address to MongoDB
  Future<bool> saveAddress(SavedAddress address) async {
    if (_currentUserId == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$_currentUserId/addresses'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'name': address.name,
          'fullAddress': address.fullAddress,
          'latitude': address.latitude,
          'longitude': address.longitude,
          'buildingDetails': address.buildingDetails,
          'landmark': address.landmark,
          'type': address.type.name,
          'isDefault': address.isDefault,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Refresh cache
          await getSavedAddresses();
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Error saving address: $e');
      return false;
    }
  }

  // Additional methods: deleteAddress, setDefaultAddress, etc.
}
```

### 4. User Authentication Integration

```dart
// Ensure addresses are linked to authenticated users
class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  
  // When user logs in
  void onUserLogin(User user) {
    _currentUser = user;
    
    // Set user ID for address service
    AddressService().setUserId(user.uid);
    
    // Initialize address provider for this user
    context.read<AddressProvider>().initialize();
  }
  
  // When user logs out
  void onUserLogout() {
    _currentUser = null;
    
    // Clear address data
    AddressService().setUserId('');
    context.read<AddressProvider>().clearAddresses();
  }
}
```

## Benefits of MongoDB Atlas Storage

### ✅ **Advantages:**
- **Cross-Device Sync**: Addresses available on all user devices
- **Backup & Recovery**: Addresses preserved when reinstalling app
- **User Profile**: Part of comprehensive user data
- **Analytics**: Track popular address types and locations
- **Sharing**: Potential for address sharing between family members

### ⚠️ **Considerations:**
- **Requires Authentication**: Users must be logged in
- **Network Dependency**: Requires internet for sync
- **Additional API Calls**: More backend requests
- **Complexity**: More moving parts to maintain

## Implementation Priority

### **Current State**: ✅ Working with local storage
### **Upgrade Path**: 
1. **Phase 1**: Keep local storage as fallback
2. **Phase 2**: Add MongoDB sync for logged-in users
3. **Phase 3**: Migrate existing local addresses to cloud

## Recommendation

For the best user experience, implement a **hybrid approach**:
- **Local Storage**: Immediate access and offline support
- **Cloud Sync**: For logged-in users with cross-device sync
- **Fallback**: Graceful degradation when offline

This ensures the feature works for all users while providing enhanced benefits for authenticated users.
