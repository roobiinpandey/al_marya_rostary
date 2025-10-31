const express = require('express');
const router = express.Router();
const AttributeGroup = require('../models/AttributeGroup');
const AttributeValue = require('../models/AttributeValue');
const { protect, authorize } = require('../middleware/auth');
const cacheManager = require('../utils/cacheManager');

// ============================================================================
// ATTRIBUTE GROUPS ROUTES
// ============================================================================

/**
 * @route   GET /api/attributes/groups
 * @desc    Get all attribute groups
 * @access  Public
 * @query   ?active=true&scope=product-attribute&language=en
 */
router.get('/groups', async (req, res) => {
  try {
    const { active, scope, language = 'en' } = req.query;
    
    let query = {};
    if (active === 'true') query.isActive = true;
    if (scope) query.scope = scope;
    
    const groups = await AttributeGroup.find(query)
      .sort({ displayOrder: 1, 'name.en': 1 });
    
    // Get value count for each group
    const groupsWithCount = await Promise.all(
      groups.map(async (group) => {
        const valueCount = await group.getValueCount();
        const localized = group.getLocalizedContent(language);
        return {
          ...localized,
          valueCount
        };
      })
    );
    
    res.json({
      success: true,
      count: groupsWithCount.length,
      data: groupsWithCount
    });
  } catch (error) {
    console.error('Error fetching attribute groups:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch attribute groups',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/attributes/groups/:id
 * @desc    Get attribute group by ID
 * @access  Public
 */
router.get('/groups/:id', async (req, res) => {
  try {
    const { language = 'en' } = req.query;
    
    const group = await AttributeGroup.findById(req.params.id);
    
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Attribute group not found'
      });
    }
    
    const valueCount = await group.getValueCount();
    const localized = group.getLocalizedContent(language);
    
    res.json({
      success: true,
      data: {
        ...localized,
        valueCount
      }
    });
  } catch (error) {
    console.error('Error fetching attribute group:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch attribute group',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/attributes/groups/key/:key
 * @desc    Get attribute group by key
 * @access  Public
 */
router.get('/groups/key/:key', async (req, res) => {
  try {
    const { language = 'en' } = req.query;
    
    const group = await AttributeGroup.findByKey(req.params.key);
    
    if (!group) {
      return res.status(404).json({
        success: false,
        message: `Attribute group with key "${req.params.key}" not found`
      });
    }
    
    const valueCount = await group.getValueCount();
    const localized = group.getLocalizedContent(language);
    
    res.json({
      success: true,
      data: {
        ...localized,
        valueCount
      }
    });
  } catch (error) {
    console.error('Error fetching attribute group:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch attribute group',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/attributes/groups
 * @desc    Create new attribute group
 * @access  Private (Admin only)
 */
router.post('/groups', protect, authorize("admin"), async (req, res) => {
  try {
    const groupData = {
      name: {
        en: req.body.nameEn || req.body.name?.en,
        ar: req.body.nameAr || req.body.name?.ar
      },
      key: req.body.key,
      description: {
        en: req.body.descriptionEn || req.body.description?.en || '',
        ar: req.body.descriptionAr || req.body.description?.ar || ''
      },
      type: req.body.type || 'single-select',
      scope: req.body.scope || 'product-attribute',
      isRequired: req.body.isRequired || false,
      displayOrder: req.body.displayOrder || 0,
      icon: req.body.icon || null,
      color: req.body.color || '#A89A6A',
      isActive: req.body.isActive !== undefined ? req.body.isActive : true,
      allowCustomValues: req.body.allowCustomValues || false,
      usedInSKU: req.body.usedInSKU || false,
      validation: req.body.validation || {},
      helpText: {
        en: req.body.helpTextEn || req.body.helpText?.en || '',
        ar: req.body.helpTextAr || req.body.helpText?.ar || ''
      },
      placeholder: {
        en: req.body.placeholderEn || req.body.placeholder?.en || '',
        ar: req.body.placeholderAr || req.body.placeholder?.ar || ''
      }
    };
    
    const newGroup = new AttributeGroup(groupData);
    await newGroup.save();
    
    res.status(201).json({
      success: true,
      message: 'Attribute group created successfully',
      data: newGroup
    });
  } catch (error) {
    console.error('Error creating attribute group:', error);
    
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Attribute group with this key already exists',
        error: error.message
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Failed to create attribute group',
      error: error.message
    });
  }
});

/**
 * @route   PUT /api/attributes/groups/:id
 * @desc    Update attribute group
 * @access  Private (Admin only)
 */
router.put('/groups/:id', protect, authorize("admin"), async (req, res) => {
  try {
    const group = await AttributeGroup.findById(req.params.id);
    
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Attribute group not found'
      });
    }
    
    // Update fields
    if (req.body.nameEn || req.body.name?.en) group.name.en = req.body.nameEn || req.body.name.en;
    if (req.body.nameAr || req.body.name?.ar) group.name.ar = req.body.nameAr || req.body.name.ar;
    if (req.body.descriptionEn !== undefined) group.description.en = req.body.descriptionEn;
    if (req.body.descriptionAr !== undefined) group.description.ar = req.body.descriptionAr;
    if (req.body.type) group.type = req.body.type;
    if (req.body.scope) group.scope = req.body.scope;
    if (req.body.isRequired !== undefined) group.isRequired = req.body.isRequired;
    if (req.body.displayOrder !== undefined) group.displayOrder = req.body.displayOrder;
    if (req.body.icon !== undefined) group.icon = req.body.icon;
    if (req.body.color) group.color = req.body.color;
    if (req.body.isActive !== undefined) group.isActive = req.body.isActive;
    if (req.body.allowCustomValues !== undefined) group.allowCustomValues = req.body.allowCustomValues;
    if (req.body.usedInSKU !== undefined) group.usedInSKU = req.body.usedInSKU;
    if (req.body.validation) group.validation = req.body.validation;
    if (req.body.helpTextEn !== undefined) group.helpText.en = req.body.helpTextEn;
    if (req.body.helpTextAr !== undefined) group.helpText.ar = req.body.helpTextAr;
    if (req.body.placeholderEn !== undefined) group.placeholder.en = req.body.placeholderEn;
    if (req.body.placeholderAr !== undefined) group.placeholder.ar = req.body.placeholderAr;
    
    await group.save();
    
    res.json({
      success: true,
      message: 'Attribute group updated successfully',
      data: group
    });
  } catch (error) {
    console.error('Error updating attribute group:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update attribute group',
      error: error.message
    });
  }
});

/**
 * @route   DELETE /api/attributes/groups/:id
 * @desc    Delete attribute group
 * @access  Private (Admin only)
 */
router.delete('/groups/:id', protect, authorize("admin"), async (req, res) => {
  try {
    const group = await AttributeGroup.findById(req.params.id);
    
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Attribute group not found'
      });
    }
    
    // Check if group has values
    const valueCount = await AttributeValue.countDocuments({ attributeGroup: group._id });
    
    if (valueCount > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete attribute group because it has ${valueCount} associated values. Delete values first.`
      });
    }
    
    await group.deleteOne();
    
    res.json({
      success: true,
      message: 'Attribute group deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting attribute group:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete attribute group',
      error: error.message
    });
  }
});

// ============================================================================
// ATTRIBUTE VALUES ROUTES
// ============================================================================

/**
 * @route   GET /api/attributes/:groupKey/values
 * @desc    Get all values for a specific attribute group by key
 * @access  Public
 * @query   ?active=true&language=en&hierarchical=true
 */
router.get('/:groupKey/values', async (req, res) => {
  try {
    const { active, language = 'en', hierarchical } = req.query;
    const cacheKey = `${req.params.groupKey}_${active}_${language}_${hierarchical}`;
    
    // Check cache first (5 minutes TTL)
    const cached = cacheManager.get('attributes', cacheKey);
    if (cached) {
      return res.json(cached);
    }
    
    const group = await AttributeGroup.findByKey(req.params.groupKey);
    
    if (!group) {
      return res.status(404).json({
        success: false,
        message: `Attribute group "${req.params.groupKey}" not found`
      });
    }
    
    let values;
    
    if (hierarchical === 'true') {
      // Return hierarchical structure (parent-child)
      values = await AttributeValue.findHierarchical(group._id);
    } else {
      // Return flat list
      const query = { attributeGroup: group._id };
      if (active === 'true') query.isActive = true;
      
      values = await AttributeValue.find(query)
        .populate('parentValue', 'name value')
        .sort({ displayOrder: 1, 'name.en': 1 })
        .lean(); // Use lean() for better performance
    }
    
    // Localize if language specified
    const localizedValues = language ? values.map(val => ({
      ...val,
      localizedName: val.name?.[language] || val.name?.en,
      localizedDescription: val.description?.[language] || val.description?.en || '',
      parentName: val.parentValue?.name?.[language] || val.parentValue?.name?.en || null
    })) : values;
    
    const response = {
      success: true,
      group: group.getLocalizedContent(language),
      count: localizedValues.length,
      data: localizedValues
    };
    
    // Cache the response for 5 minutes
    cacheManager.set('attributes', cacheKey, response, 300);
    
    res.json(response);
  } catch (error) {
    console.error('Error fetching attribute values:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch attribute values',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/attributes/values/:id
 * @desc    Get specific attribute value by ID
 * @access  Public
 */
router.get('/values/:id', async (req, res) => {
  try {
    const { language = 'en' } = req.query;
    
    const value = await AttributeValue.findById(req.params.id)
      .populate('attributeGroup', 'name key')
      .populate('parentValue', 'name value');
    
    if (!value) {
      return res.status(404).json({
        success: false,
        message: 'Attribute value not found'
      });
    }
    
    const localized = value.getLocalizedContent(language);
    
    res.json({
      success: true,
      data: localized
    });
  } catch (error) {
    console.error('Error fetching attribute value:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch attribute value',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/attributes/:groupKey/values
 * @desc    Create a new attribute value
 * @access  Private/Admin
 */
router.post('/:groupKey/values', protect, authorize("admin"), async (req, res) => {
  // Clear cache for this attribute group
  cacheManager.clearNamespace('attributes');
  try {
    const group = await AttributeGroup.findByKey(req.params.groupKey);
    
    if (!group) {
      return res.status(404).json({
        success: false,
        message: `Attribute group "${req.params.groupKey}" not found`
      });
    }
    
    const valueData = {
      attributeGroup: group._id,
      name: {
        en: req.body.nameEn || req.body.name?.en,
        ar: req.body.nameAr || req.body.name?.ar
      },
      value: req.body.value,
      description: {
        en: req.body.descriptionEn || req.body.description?.en || '',
        ar: req.body.descriptionAr || req.body.description?.ar || ''
      },
      icon: req.body.icon || null,
      color: req.body.color || null,
      displayOrder: req.body.displayOrder || 0,
      isActive: req.body.isActive !== undefined ? req.body.isActive : true,
      parentValue: req.body.parentValue || null,
      metadata: req.body.metadata || {},
      aliases: req.body.aliases || [],
      image: req.body.image || null
    };
    
    const newValue = new AttributeValue(valueData);
    await newValue.save();
    
    res.status(201).json({
      success: true,
      message: 'Attribute value created successfully',
      data: newValue
    });
  } catch (error) {
    console.error('Error creating attribute value:', error);
    
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Attribute value with this name already exists in this group',
        error: error.message
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Failed to create attribute value',
      error: error.message
    });
  }
});

/**
 * @route   PUT /api/attributes/values/:id
 * @desc    Update attribute value
 * @access  Private (Admin only)
 */
router.put('/values/:id', protect, authorize("admin"), async (req, res) => {
  // Clear cache for all attributes
  cacheManager.clearNamespace('attributes');
  
  try {
    const value = await AttributeValue.findById(req.params.id);
    
    if (!value) {
      return res.status(404).json({
        success: false,
        message: 'Attribute value not found'
      });
    }
    
    // Update fields
    if (req.body.nameEn || req.body.name?.en) value.name.en = req.body.nameEn || req.body.name.en;
    if (req.body.nameAr || req.body.name?.ar) value.name.ar = req.body.nameAr || req.body.name.ar;
    if (req.body.value) value.value = req.body.value;
    if (req.body.descriptionEn !== undefined) value.description.en = req.body.descriptionEn;
    if (req.body.descriptionAr !== undefined) value.description.ar = req.body.descriptionAr;
    if (req.body.icon !== undefined) value.icon = req.body.icon;
    if (req.body.color !== undefined) value.color = req.body.color;
    if (req.body.displayOrder !== undefined) value.displayOrder = req.body.displayOrder;
    if (req.body.isActive !== undefined) value.isActive = req.body.isActive;
    if (req.body.parentValue !== undefined) value.parentValue = req.body.parentValue;
    if (req.body.metadata) value.metadata = req.body.metadata;
    if (req.body.aliases) value.aliases = req.body.aliases;
    if (req.body.image !== undefined) value.image = req.body.image;
    
    await value.save();
    
    res.json({
      success: true,
      message: 'Attribute value updated successfully',
      data: value
    });
  } catch (error) {
    console.error('Error updating attribute value:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update attribute value',
      error: error.message
    });
  }
});

/**
 * @route   DELETE /api/attributes/values/:id
 * @desc    Delete attribute value
 * @access  Private (Admin only)
 */
router.delete('/values/:id', protect, authorize("admin"), async (req, res) => {
  // Clear cache for all attributes
  cacheManager.clearNamespace('attributes');
  
  try {
    const value = await AttributeValue.findById(req.params.id);
    
    if (!value) {
      return res.status(404).json({
        success: false,
        message: 'Attribute value not found'
      });
    }
    
    // Check if value is used in products
    if (value.usageCount > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete this value because it is used in ${value.usageCount} product(s). Remove it from products first or deactivate instead.`
      });
    }
    
    // Check if it has children
    const childCount = await AttributeValue.countDocuments({ parentValue: value._id });
    
    if (childCount > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete this value because it has ${childCount} child value(s). Delete children first.`
      });
    }
    
    await value.deleteOne();
    
    res.json({
      success: true,
      message: 'Attribute value deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting attribute value:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete attribute value',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/attributes/values/bulk
 * @desc    Bulk create attribute values
 * @access  Private (Admin only)
 */
router.post('/values/bulk', protect, authorize("admin"), async (req, res) => {
  try {
    const { groupKey, values } = req.body;
    
    if (!groupKey || !values || !Array.isArray(values)) {
      return res.status(400).json({
        success: false,
        message: 'groupKey and values array are required'
      });
    }
    
    const group = await AttributeGroup.findByKey(groupKey);
    
    if (!group) {
      return res.status(404).json({
        success: false,
        message: `Attribute group "${groupKey}" not found`
      });
    }
    
    const createdValues = [];
    const errors = [];
    
    for (const valueData of values) {
      try {
        const newValue = new AttributeValue({
          attributeGroup: group._id,
          ...valueData,
          name: {
            en: valueData.nameEn || valueData.name?.en,
            ar: valueData.nameAr || valueData.name?.ar
          }
        });
        
        await newValue.save();
        createdValues.push(newValue);
      } catch (error) {
        errors.push({
          value: valueData,
          error: error.message
        });
      }
    }
    
    res.status(201).json({
      success: true,
      message: `Created ${createdValues.length} values`,
      data: createdValues,
      errors: errors.length > 0 ? errors : undefined
    });
  } catch (error) {
    console.error('Error bulk creating attribute values:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to bulk create attribute values',
      error: error.message
    });
  }
});

module.exports = router;
