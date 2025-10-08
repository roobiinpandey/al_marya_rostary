const Settings = require('../models/Settings');
const { logAudit } = require('../utils/auditLogger');

// Get all settings or settings by category
const getSettings = async (req, res) => {
  try {
    const { category, includePrivate = false } = req.query;
    let settings;

    if (category) {
      settings = await Settings.getSettingsByCategory(category, includePrivate === 'true');
    } else {
      const query = includePrivate === 'true' ? {} : { isPublic: true };
      const settingsList = await Settings.find(query).sort({ category: 1, key: 1 });
      
      // Group by category
      settings = {};
      settingsList.forEach(setting => {
        if (!settings[setting.category]) {
          settings[setting.category] = {};
        }
        settings[setting.category][setting.key] = {
          value: setting.value,
          dataType: setting.dataType,
          description: setting.description,
          isRequired: setting.isRequired,
          validationRules: setting.validationRules
        };
      });
    }

    res.json({
      success: true,
      data: settings
    });
  } catch (error) {
    console.error('Get settings error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve settings',
      error: error.message
    });
  }
};

// Get a specific setting by key
const getSetting = async (req, res) => {
  try {
    const { key } = req.params;
    const setting = await Settings.findOne({ key });

    if (!setting) {
      return res.status(404).json({
        success: false,
        message: 'Setting not found'
      });
    }

    res.json({
      success: true,
      data: {
        key: setting.key,
        value: setting.value,
        dataType: setting.dataType,
        category: setting.category,
        description: setting.description,
        isPublic: setting.isPublic,
        isRequired: setting.isRequired,
        validationRules: setting.validationRules
      }
    });
  } catch (error) {
    console.error('Get setting error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve setting',
      error: error.message
    });
  }
};

// Update a setting
const updateSetting = async (req, res) => {
  try {
    const { key } = req.params;
    const { value, description, isPublic, isRequired, validationRules } = req.body;

    if (value === undefined || value === null) {
      return res.status(400).json({
        success: false,
        message: 'Setting value is required'
      });
    }

    const existingSetting = await Settings.findOne({ key });
    if (!existingSetting) {
      return res.status(404).json({
        success: false,
        message: 'Setting not found'
      });
    }

    // Update the setting
    const updateData = { value };
    if (description !== undefined) updateData.description = description;
    if (isPublic !== undefined) updateData.isPublic = isPublic;
    if (isRequired !== undefined) updateData.isRequired = isRequired;
    if (validationRules !== undefined) updateData.validationRules = validationRules;

    const updatedSetting = await Settings.findOneAndUpdate(
      { key },
      updateData,
      { new: true, runValidators: true }
    );

    // Log the change
    await logAudit(req.user.id, 'UPDATE_SETTING', 'Settings', key, {
      oldValue: existingSetting.value,
      newValue: value,
      category: updatedSetting.category
    });

    res.json({
      success: true,
      message: 'Setting updated successfully',
      data: {
        key: updatedSetting.key,
        value: updatedSetting.value,
        dataType: updatedSetting.dataType,
        category: updatedSetting.category,
        description: updatedSetting.description,
        isPublic: updatedSetting.isPublic,
        isRequired: updatedSetting.isRequired
      }
    });
  } catch (error) {
    console.error('Update setting error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update setting',
      error: error.message
    });
  }
};

// Create a new setting
const createSetting = async (req, res) => {
  try {
    const {
      key,
      value,
      dataType = 'string',
      category = 'general',
      description = '',
      isPublic = false,
      isRequired = false,
      validationRules = {}
    } = req.body;

    if (!key || value === undefined || value === null) {
      return res.status(400).json({
        success: false,
        message: 'Key and value are required'
      });
    }

    // Check if setting already exists
    const existingSetting = await Settings.findOne({ key });
    if (existingSetting) {
      return res.status(409).json({
        success: false,
        message: 'Setting with this key already exists'
      });
    }

    const newSetting = await Settings.setSetting(key, value, {
      dataType,
      category,
      description,
      isPublic,
      isRequired,
      validationRules
    });

    // Log the creation
    await logAudit(req.user.id, 'CREATE_SETTING', 'Settings', key, {
      value,
      category,
      dataType
    });

    res.status(201).json({
      success: true,
      message: 'Setting created successfully',
      data: {
        key: newSetting.key,
        value: newSetting.value,
        dataType: newSetting.dataType,
        category: newSetting.category,
        description: newSetting.description,
        isPublic: newSetting.isPublic,
        isRequired: newSetting.isRequired
      }
    });
  } catch (error) {
    console.error('Create setting error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create setting',
      error: error.message
    });
  }
};

// Delete a setting
const deleteSetting = async (req, res) => {
  try {
    const { key } = req.params;

    const setting = await Settings.findOne({ key });
    if (!setting) {
      return res.status(404).json({
        success: false,
        message: 'Setting not found'
      });
    }

    // Check if setting is required (prevent deletion of critical settings)
    if (setting.isRequired) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete required setting'
      });
    }

    await Settings.deleteOne({ key });

    // Log the deletion
    await logAudit(req.user.id, 'DELETE_SETTING', 'Settings', key, {
      deletedValue: setting.value,
      category: setting.category
    });

    res.json({
      success: true,
      message: 'Setting deleted successfully'
    });
  } catch (error) {
    console.error('Delete setting error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete setting',
      error: error.message
    });
  }
};

// Bulk update settings
const bulkUpdateSettings = async (req, res) => {
  try {
    const { settings } = req.body;

    if (!settings || typeof settings !== 'object') {
      return res.status(400).json({
        success: false,
        message: 'Settings object is required'
      });
    }

    const results = [];
    const errors = [];

    for (const [key, value] of Object.entries(settings)) {
      try {
        const existingSetting = await Settings.findOne({ key });
        if (existingSetting) {
          const oldValue = existingSetting.value;
          await Settings.findOneAndUpdate(
            { key },
            { value },
            { new: true, runValidators: true }
          );

          // Log the change
          await logAudit(req.user.id, 'BULK_UPDATE_SETTING', 'Settings', key, {
            oldValue,
            newValue: value,
            category: existingSetting.category
          });

          results.push({ key, status: 'updated', value });
        } else {
          errors.push({ key, error: 'Setting not found' });
        }
      } catch (error) {
        errors.push({ key, error: error.message });
      }
    }

    res.json({
      success: true,
      message: `Updated ${results.length} settings`,
      data: {
        updated: results,
        errors: errors
      }
    });
  } catch (error) {
    console.error('Bulk update settings error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to bulk update settings',
      error: error.message
    });
  }
};

// Initialize default settings
const initializeDefaults = async (req, res) => {
  try {
    await Settings.initializeDefaults();

    await logAudit(req.user.id, 'INITIALIZE_SETTINGS', 'Settings', 'system', {
      action: 'initialize_defaults'
    });

    res.json({
      success: true,
      message: 'Default settings initialized successfully'
    });
  } catch (error) {
    console.error('Initialize defaults error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to initialize default settings',
      error: error.message
    });
  }
};

// Reset settings to defaults (dangerous operation)
const resetToDefaults = async (req, res) => {
  try {
    // Clear all existing settings
    await Settings.deleteMany({});
    
    // Reinitialize defaults
    await Settings.initializeDefaults();

    await logAudit(req.user.id, 'RESET_SETTINGS', 'Settings', 'system', {
      action: 'reset_to_defaults',
      warning: 'All custom settings were deleted'
    });

    res.json({
      success: true,
      message: 'Settings reset to defaults successfully'
    });
  } catch (error) {
    console.error('Reset settings error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to reset settings',
      error: error.message
    });
  }
};

// Get public settings (for frontend/mobile app)
const getPublicSettings = async (req, res) => {
  try {
    const { category } = req.query;
    
    let settings;
    if (category) {
      settings = await Settings.getSettingsByCategory(category, false); // only public
    } else {
      const publicSettings = await Settings.find({ isPublic: true }).sort({ category: 1, key: 1 });
      settings = {};
      publicSettings.forEach(setting => {
        if (!settings[setting.category]) {
          settings[setting.category] = {};
        }
        settings[setting.category][setting.key] = setting.value;
      });
    }

    res.json({
      success: true,
      data: settings
    });
  } catch (error) {
    console.error('Get public settings error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve public settings',
      error: error.message
    });
  }
};

module.exports = {
  getSettings,
  getSetting,
  updateSetting,
  createSetting,
  deleteSetting,
  bulkUpdateSettings,
  initializeDefaults,
  resetToDefaults,
  getPublicSettings
};
