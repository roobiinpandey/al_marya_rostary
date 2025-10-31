/* Attribute Management Module */

// ============================================================================
// STATE MANAGEMENT
// ============================================================================

let attributeGroups = [];
let attributeValues = {};
let currentEditingGroup = null;
let currentEditingValue = null;
let currentGroupKey = null;

// ============================================================================
// LOAD ATTRIBUTE GROUPS
// ============================================================================

async function loadAttributeGroups() {
    try {
        showLoading('attributeGroupsContainer');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/attributes/groups`);
        const data = await response.json();
        
        if (data.success) {
            attributeGroups = data.data;
            renderAttributeGroups();
        } else {
            showErrorById('attributeGroupsContainer', 'Failed to load attribute groups');
        }
    } catch (error) {
        console.error('Error loading attribute groups:', error);
        showErrorById('attributeGroupsContainer', 'Error loading attribute groups');
    }
}

function renderAttributeGroups() {
    const container = document.getElementById('attributeGroupsContainer');
    
    if (!attributeGroups || attributeGroups.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">🎨</div>
                <h3>No Attribute Groups Yet</h3>
                <p>Create your first attribute group to start organizing product attributes</p>
                <button class="btn btn-primary btn-lg" onclick="showAttributeGroupModal()">
                    <i class="fas fa-plus-circle"></i> Create Your First Group
                </button>
            </div>
        `;
        return;
    }
    
    const getScopeInfo = (scope) => {
        const scopes = {
            'product-attribute': { icon: '📦', label: 'Product Attribute', class: 'scope-product' },
            'filter-only': { icon: '🔍', label: 'Filter Only', class: 'scope-filter' },
            'both': { icon: '⚡', label: 'Product & Filter', class: 'scope-both' }
        };
        return scopes[scope] || scopes['product-attribute'];
    };
    
    const getTypeInfo = (type) => {
        const types = {
            'single-select': { icon: '☝️', label: 'Single Select' },
            'multi-select': { icon: '✋', label: 'Multi Select' },
            'checkbox-group': { icon: '☑️', label: 'Checkboxes' },
            'radio-group': { icon: '🔘', label: 'Radio Buttons' }
        };
        return types[type] || types['single-select'];
    };
    
    const quickTips = `
        <div style="background: linear-gradient(135deg, #e3f2fd 0%, #f3e5f5 100%); border-radius: 16px; padding: 20px 24px; margin-bottom: 24px; border-left: 4px solid #A89A6A;">
            <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 8px;">
                <i class="fas fa-lightbulb" style="color: #A89A6A; font-size: 24px;"></i>
                <h4 style="margin: 0; color: #2c3e50; font-size: 16px;">Quick Tip</h4>
            </div>
            <p style="margin: 0; color: #495057; font-size: 14px; line-height: 1.6;">
                Click <strong>"Manage Values"</strong> to add or edit attribute values for each group. 
                Use the <i class="fas fa-edit"></i> button to modify group settings, and organize your attributes with display orders.
            </p>
        </div>
    `;
    
    container.innerHTML = quickTips + `
        ${attributeGroups.map(group => {
            const scopeInfo = getScopeInfo(group.scope);
            const typeInfo = getTypeInfo(group.type);
            
            return `
                <div class="attr-card" data-group-id="${group._id}">
                    <div class="attr-card-header" style="background: linear-gradient(135deg, ${group.color || '#A89A6A'}15 0%, ${group.color || '#A89A6A'}05 100%);">
                        <div class="attr-icon" style="background: ${group.color || '#A89A6A'};">
                            ${group.icon || '📦'}
                        </div>
                        <div class="attr-info">
                            <h3 class="attr-title">${group.name?.en || group.localizedName}</h3>
                            <div class="attr-badges">
                                <span class="badge ${scopeInfo.class}" title="${scopeInfo.label}">
                                    ${scopeInfo.icon} ${scopeInfo.label}
                                </span>
                                <span class="badge badge-type" title="${typeInfo.label}">
                                    ${typeInfo.icon} ${typeInfo.label}
                                </span>
                            </div>
                        </div>
                        <div class="attr-actions">
                            <button class="action-btn edit-btn" onclick="editAttributeGroup('${group._id}')" title="Edit Group">
                                <i class="fas fa-edit"></i>
                            </button>
                            <button class="action-btn delete-btn" onclick="deleteAttributeGroup('${group._id}')" title="Delete Group">
                                <i class="fas fa-trash-alt"></i>
                            </button>
                        </div>
                    </div>
                    
                    <div class="attr-card-body">
                        <div class="attr-stats">
                            <div class="stat-item">
                                <div class="stat-value">${group.valueCount || 0}</div>
                                <div class="stat-label">Values</div>
                            </div>
                            <div class="stat-item">
                                <div class="stat-value">${group.displayOrder || 0}</div>
                                <div class="stat-label">Order</div>
                            </div>
                            <div class="stat-item">
                                <div class="stat-icon ${group.isRequired ? 'required' : 'optional'}">
                                    ${group.isRequired ? '<i class="fas fa-star"></i>' : '<i class="far fa-star"></i>'}
                                </div>
                                <div class="stat-label">${group.isRequired ? 'Required' : 'Optional'}</div>
                            </div>
                            <div class="stat-item">
                                <div class="stat-icon ${group.isActive ? 'active' : 'inactive'}">
                                    ${group.isActive ? '<i class="fas fa-check-circle"></i>' : '<i class="fas fa-times-circle"></i>'}
                                </div>
                                <div class="stat-label">${group.isActive ? 'Active' : 'Inactive'}</div>
                            </div>
                        </div>
                        
                        <div class="attr-key">
                            <i class="fas fa-key"></i> <code>${group.key}</code>
                        </div>
                        
                        <button class="manage-values-btn" onclick="viewAttributeValues('${group.key}', '${(group.name?.en || group.localizedName).replace(/'/g, "&apos;")}')">
                            <i class="fas fa-list-ul"></i> Manage Values
                            <span class="value-count">${group.valueCount || 0}</span>
                        </button>
                    </div>
                </div>
            `;
        }).join('')}
    `;
}

// ============================================================================
// ATTRIBUTE GROUP CRUD
// ============================================================================

function showAttributeGroupModal(groupId = null) {
    currentEditingGroup = groupId;
    
    const modal = document.getElementById('attributeGroupModal');
    const title = document.getElementById('attributeGroupModalTitle');
    const form = document.getElementById('attributeGroupForm');
    
    if (groupId) {
        title.textContent = 'Edit Attribute Group';
        const group = attributeGroups.find(g => g._id === groupId);
        if (group) {
            const setValueIfExists = (id, value) => {
                const el = document.getElementById(id);
                if (el) el.value = value;
            };
            
            setValueIfExists('groupNameEn', group.name?.en || '');
            setValueIfExists('groupNameAr', group.name?.ar || '');
            setValueIfExists('groupKey', group.key || '');
            setValueIfExists('groupType', group.type || 'single-select');
            setValueIfExists('groupScope', group.scope || 'product-attribute');
            setValueIfExists('groupIcon', group.icon || '');
            setValueIfExists('groupColor', group.color || '#4CAF50');
            setValueIfExists('groupDisplayOrder', group.displayOrder || 0);
            
            const keyEl = document.getElementById('groupKey');
            if (keyEl) keyEl.disabled = true; // Can't change key
            
            const isRequiredEl = document.getElementById('groupIsRequired');
            if (isRequiredEl) isRequiredEl.checked = group.isRequired || false;
            
            const isActiveEl = document.getElementById('groupIsActive');
            if (isActiveEl) isActiveEl.checked = group.isActive !== false;
        }
    } else {
        title.textContent = 'Create Attribute Group';
        form.reset();
        const keyEl = document.getElementById('groupKey');
        if (keyEl) keyEl.disabled = false;
        
        const isActiveEl = document.getElementById('groupIsActive');
        if (isActiveEl) isActiveEl.checked = true;
    }
    
    modal.style.display = 'flex';
}

function closeAttributeGroupModal() {
    document.getElementById('attributeGroupModal').style.display = 'none';
    currentEditingGroup = null;
}

async function saveAttributeGroup(event) {
    event.preventDefault();
    
    const getValueIfExists = (id, defaultValue = '') => {
        const el = document.getElementById(id);
        return el ? el.value : defaultValue;
    };
    
    const getCheckedIfExists = (id, defaultValue = false) => {
        const el = document.getElementById(id);
        return el ? el.checked : defaultValue;
    };
    
    const formData = {
        name: {
            en: getValueIfExists('groupNameEn'),
            ar: getValueIfExists('groupNameAr')
        },
        key: getValueIfExists('groupKey'),
        type: getValueIfExists('groupType', 'single-select'),
        scope: getValueIfExists('groupScope', 'product-attribute'),
        icon: getValueIfExists('groupIcon'),
        color: getValueIfExists('groupColor', '#4CAF50'),
        displayOrder: parseInt(getValueIfExists('groupDisplayOrder', '0')) || 0,
        isRequired: getCheckedIfExists('groupIsRequired'),
        isActive: getCheckedIfExists('groupIsActive', true)
    };
    
    try {
        const url = currentEditingGroup 
            ? `${API_BASE_URL}/api/attributes/groups/${currentEditingGroup}`
            : `${API_BASE_URL}/api/attributes/groups`;
        
        const method = currentEditingGroup ? 'PUT' : 'POST';
        
        const response = await authenticatedFetch(url, {
            method: method,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(formData)
        });
        
        const data = await response.json();
        
        if (data.success) {
            showToast(currentEditingGroup ? 'Group updated successfully' : 'Group created successfully', 'success');
            closeAttributeGroupModal();
            loadAttributeGroups();
        } else {
            showToast('Failed to save group: ' + (data.message || 'Unknown error'), 'error');
        }
    } catch (error) {
        console.error('Error saving attribute group:', error);
        showToast('Error saving attribute group', 'error');
    }
}

async function deleteAttributeGroup(groupId) {
    const group = attributeGroups.find(g => g._id === groupId);
    const groupName = group?.name?.en || 'this group';
    
    if (!confirm(`Are you sure you want to delete "${groupName}"? This will also delete all associated values.`)) {
        return;
    }
    
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/attributes/groups/${groupId}`, {
            method: 'DELETE'
        });
        
        const data = await response.json();
        
        if (data.success) {
            showToast('Group deleted successfully', 'success');
            loadAttributeGroups();
        } else {
            showToast('Failed to delete group: ' + (data.message || 'Unknown error'), 'error');
        }
    } catch (error) {
        console.error('Error deleting attribute group:', error);
        showToast('Error deleting attribute group', 'error');
    }
}

async function editAttributeGroup(groupId) {
    showAttributeGroupModal(groupId);
}

// ============================================================================
// ATTRIBUTE VALUES MANAGEMENT
// ============================================================================

async function viewAttributeValues(groupKey, groupName) {
    currentGroupKey = groupKey;
    
    const nameEl = document.getElementById('valuesGroupName');
    if (nameEl) nameEl.textContent = groupName;
    
    document.getElementById('attributeGroupsView').style.display = 'none';
    document.getElementById('attributeValuesView').style.display = 'block';
    
    // Update header buttons
    document.getElementById('backToGroupsBtn').style.display = 'inline-block';
    document.getElementById('createGroupBtn').style.display = 'none';
    document.getElementById('createValueBtn').style.display = 'inline-block';
    
    await loadAttributeValues(groupKey);
}

function backToGroups() {
    document.getElementById('attributeValuesView').style.display = 'none';
    document.getElementById('attributeGroupsView').style.display = 'block';
    
    // Update header buttons
    document.getElementById('backToGroupsBtn').style.display = 'none';
    document.getElementById('createGroupBtn').style.display = 'inline-block';
    document.getElementById('createValueBtn').style.display = 'none';
    currentGroupKey = null;
}

async function loadAttributeValues(groupKey) {
    try {
        showLoading('attributeValuesContainer');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/attributes/${groupKey}/values?hierarchical=true`);
        const data = await response.json();
        
        if (data.success) {
            attributeValues[groupKey] = data.data;
            renderAttributeValues(groupKey);
        } else {
            showErrorById('attributeValuesContainer', 'Failed to load attribute values');
        }
    } catch (error) {
        console.error('Error loading attribute values:', error);
        showErrorById('attributeValuesContainer', 'Error loading attribute values');
    }
}

function renderAttributeValues(groupKey) {
    const container = document.getElementById('attributeValuesContainer');
    const values = attributeValues[groupKey] || [];
    
    if (values.length === 0) {
        container.innerHTML = `
            <div class="values-empty">
                <i class="fas fa-inbox"></i>
                <h3>No Values Yet</h3>
                <p>Start by creating your first attribute value</p>
            </div>
        `;
        return;
    }
    
    const html = `
        <div class="attribute-values-list">
            ${values.map(value => renderValueItem(value, groupKey)).join('')}
        </div>
    `;
    
    container.innerHTML = html;
}

function renderValueItem(value, groupKey, level = 0) {
    const levelClass = level > 0 ? `level-${Math.min(level, 2)}` : '';
    const isActive = value.isActive !== false;
    const statusClass = isActive ? 'active' : 'inactive';
    
    let html = `
        <div class="attribute-value-item ${levelClass}" data-value-id="${value._id}">
            <div class="attribute-value-icon" style="background: ${value.color || '#f8f9fa'};">
                ${value.icon || '📌'}
            </div>
            <div class="attribute-value-info">
                <h5>
                    ${value.name?.en || value.localizedName}
                    ${value.name?.ar ? `<span style="color: #6c757d; font-weight: 400; font-size: 14px;" dir="rtl"> • ${value.name.ar}</span>` : ''}
                </h5>
                <div class="value-meta">
                    <code>${value.value}</code>
                    ${value.color ? `<span style="width: 16px; height: 16px; background: ${value.color}; border-radius: 4px; display: inline-block; border: 1px solid #dee2e6;"></span>` : ''}
                    <span style="color: #6c757d;">Order: ${value.displayOrder || 0}</span>
                    <span class="badge badge-${statusClass}" style="background: ${isActive ? '#d4edda' : '#f8d7da'}; color: ${isActive ? '#155724' : '#721c24'}; padding: 2px 8px; border-radius: 12px; font-size: 11px;">
                        ${isActive ? '✓ Active' : '✗ Inactive'}
                    </span>
                    ${value.children && value.children.length > 0 ? `<span style="color: #A89A6A; font-weight: 600;">${value.children.length} sub-value${value.children.length > 1 ? 's' : ''}</span>` : ''}
                </div>
            </div>
            <div class="attribute-value-actions">
                ${level < 2 ? `
                    <button class="btn-add-child" onclick="showAttributeValueModal('${groupKey}', null, '${value._id}')" title="Add Child Value">
                        <i class="fas fa-plus"></i> Child
                    </button>
                ` : ''}
                <button class="btn-edit-value" onclick="editAttributeValue('${groupKey}', '${value._id}')" title="Edit Value">
                    <i class="fas fa-edit"></i> Edit
                </button>
                <button class="btn-delete-value" onclick="deleteAttributeValue('${groupKey}', '${value._id}')" title="Delete Value">
                    <i class="fas fa-trash-alt"></i>
                </button>
            </div>
        </div>
    `;
    
    // Render children recursively
    if (value.children && value.children.length > 0) {
        html += value.children.map(child => renderValueItem(child, groupKey, level + 1)).join('');
    }
    
    return html;
}

// ============================================================================
// ATTRIBUTE VALUE CRUD
// ============================================================================

function showAttributeValueModal(groupKey, valueId = null) {
    currentEditingValue = valueId;
    
    const modal = document.getElementById('attributeValueModal');
    const title = document.getElementById('attributeValueModalTitle');
    const form = document.getElementById('attributeValueForm');
    
    // Load parent options
    loadParentOptions(groupKey, valueId);
    
    if (valueId) {
        title.textContent = 'Edit Attribute Value';
        const value = findValueById(attributeValues[groupKey], valueId);
        if (value) {
            document.getElementById('valueNameEn').value = value.name?.en || '';
            document.getElementById('valueNameAr').value = value.name?.ar || '';
            document.getElementById('valueValue').value = value.value || '';
            document.getElementById('valueValue').disabled = true; // Can't change value key
            document.getElementById('valueDescEn').value = value.description?.en || '';
            document.getElementById('valueDescAr').value = value.description?.ar || '';
            document.getElementById('valueIcon').value = value.icon || '';
            document.getElementById('valueColor').value = value.color || '';
            document.getElementById('valueDisplayOrder').value = value.displayOrder || 0;
            document.getElementById('valueParent').value = value.parentValue?._id || '';
            document.getElementById('valueIsActive').checked = value.isActive !== false;
        }
    } else {
        title.textContent = 'Create Attribute Value';
        form.reset();
        document.getElementById('valueValue').disabled = false;
        document.getElementById('valueIsActive').checked = true;
    }
    
    modal.style.display = 'flex';
}

function closeAttributeValueModal() {
    document.getElementById('attributeValueModal').style.display = 'none';
    currentEditingValue = null;
}

function loadParentOptions(groupKey, excludeId = null) {
    const select = document.getElementById('valueParent');
    const values = attributeValues[groupKey] || [];
    
    select.innerHTML = '<option value="">None (Top Level)</option>';
    
    const addOptions = (items, level = 0) => {
        items.forEach(item => {
            if (item._id !== excludeId) {
                const option = document.createElement('option');
                option.value = item._id;
                option.textContent = '  '.repeat(level) + (item.name?.en || item.localizedName);
                select.appendChild(option);
                
                if (item.children && item.children.length > 0) {
                    addOptions(item.children, level + 1);
                }
            }
        });
    };
    
    addOptions(values);
}

function findValueById(values, id) {
    for (const value of values) {
        if (value._id === id) return value;
        if (value.children) {
            const found = findValueById(value.children, id);
            if (found) return found;
        }
    }
    return null;
}

async function saveAttributeValue(event) {
    event.preventDefault();
    
    if (!currentGroupKey) {
        showToast('No group selected', 'error');
        return;
    }
    
    const formData = {
        name: {
            en: document.getElementById('valueNameEn').value,
            ar: document.getElementById('valueNameAr').value
        },
        value: document.getElementById('valueValue').value,
        description: {
            en: document.getElementById('valueDescEn').value,
            ar: document.getElementById('valueDescAr').value
        },
        icon: document.getElementById('valueIcon').value,
        color: document.getElementById('valueColor').value,
        displayOrder: parseInt(document.getElementById('valueDisplayOrder').value) || 0,
        parentValue: document.getElementById('valueParent').value || null,
        isActive: document.getElementById('valueIsActive').checked
    };
    
    try {
        const url = currentEditingValue
            ? `${API_BASE_URL}/api/attributes/values/${currentEditingValue}`
            : `${API_BASE_URL}/api/attributes/${currentGroupKey}/values`;
        
        const method = currentEditingValue ? 'PUT' : 'POST';
        
        const response = await authenticatedFetch(url, {
            method: method,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(formData)
        });
        
        const data = await response.json();
        
        if (data.success) {
            showToast(currentEditingValue ? 'Value updated successfully' : 'Value created successfully', 'success');
            closeAttributeValueModal();
            loadAttributeValues(currentGroupKey);
        } else {
            showToast('Failed to save value: ' + (data.message || 'Unknown error'), 'error');
        }
    } catch (error) {
        console.error('Error saving attribute value:', error);
        showToast('Error saving attribute value', 'error');
    }
}

async function deleteAttributeValue(groupKey, valueId) {
    const value = findValueById(attributeValues[groupKey], valueId);
    const valueName = value?.name?.en || 'this value';
    
    if (!confirm(`Are you sure you want to delete "${valueName}"?`)) {
        return;
    }
    
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/attributes/values/${valueId}`, {
            method: 'DELETE'
        });
        
        const data = await response.json();
        
        if (data.success) {
            showToast('Value deleted successfully', 'success');
            loadAttributeValues(groupKey);
        } else {
            showToast('Failed to delete value: ' + (data.message || 'Unknown error'), 'error');
        }
    } catch (error) {
        console.error('Error deleting attribute value:', error);
        showToast('Error deleting attribute value', 'error');
    }
}

async function editAttributeValue(groupKey, valueId) {
    showAttributeValueModal(groupKey, valueId);
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

function autoGenerateKey() {
    const nameEn = document.getElementById('groupNameEn').value;
    const keyField = document.getElementById('groupKey');
    
    if (nameEn && keyField && !keyField.disabled) {
        const key = nameEn
            .toLowerCase()
            .replace(/[^\w\s-]/g, '')
            .replace(/\s+/g, '_')
            .replace(/-+/g, '_')
            .trim();
        keyField.value = key;
    }
}

function autoGenerateValue() {
    const nameEn = document.getElementById('valueNameEn').value;
    const valueField = document.getElementById('valueValue');
    
    if (nameEn && valueField && !valueField.disabled) {
        const value = nameEn
            .toLowerCase()
            .replace(/[^\w\s-]/g, '')
            .replace(/\s+/g, '_')
            .replace(/-+/g, '_')
            .trim();
        valueField.value = value;
    }
}

// ============================================================================
// INITIALIZATION
// ============================================================================

// Load attributes when the attributes section is opened
function initializeAttributesSection() {
    loadAttributeGroups();
}

// Auto-initialize if attributes section exists
document.addEventListener('DOMContentLoaded', function() {
    const attributesSection = document.getElementById('attributesSection');
    if (attributesSection && attributesSection.classList.contains('active')) {
        initializeAttributesSection();
    }
});

console.log('✅ Attributes management module loaded');
