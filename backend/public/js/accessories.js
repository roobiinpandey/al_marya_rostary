// Accessories Management System
class AccessoriesManager {
    constructor() {
        this.accessories = [];
        this.accessoryTypes = [];
        this.currentAccessory = null;
        this.filters = {
            type: '',
            status: '',
            search: ''
        };
    }

    async init() {
        console.log('🛠️ Initializing Accessories Manager...');
        await this.loadAccessoryTypes();
        await this.loadAccessories();
        this.populateTypeFilters();
    }

    async loadAccessoryTypes() {
        try {
            const response = await fetch('/api/accessory-types?active=true');
            const data = await response.json();
            
            if (data.success) {
                this.accessoryTypes = data.data || [];
                console.log(`✅ Loaded ${this.accessoryTypes.length} accessory types`);
            }
        } catch (error) {
            console.error('Error loading accessory types:', error);
            // Continue even if types fail to load
        }
    }

    populateTypeFilters() {
        const typeSelect = document.getElementById('accessoryType');
        const typeFilter = document.getElementById('accessoryTypeFilter');
        
        if (typeSelect || typeFilter) {
            const optionsHTML = `
                <option value="">-- Select Type --</option>
                ${this.accessoryTypes.map(type => `
                    <option value="${type.slug}">${type.name.en}</option>
                `).join('')}
            `;
            
            if (typeSelect) typeSelect.innerHTML = optionsHTML;
            if (typeFilter) typeFilter.innerHTML = `<option value="">All Types</option>` + optionsHTML;
        }
    }

    async loadAccessories() {
        try {
            showLoader('accessoriesTable');
            
            const typeFilter = document.getElementById('accessoryTypeFilter')?.value || '';
            const statusFilter = document.getElementById('accessoryStatusFilter')?.value || '';
            
            let url = '/api/accessories';
            const params = new URLSearchParams();
            
            if (typeFilter) params.append('type', typeFilter);
            if (statusFilter === 'active') params.append('featured', 'false');
            if (statusFilter === 'inactive') params.append('featured', 'false');
            if (statusFilter === 'featured') params.append('featured', 'true');
            
            if (params.toString()) {
                url += '?' + params.toString();
            }

            const response = await fetch(url);
            const data = await response.json();

            if (data.success) {
                this.accessories = data.data || [];
                this.renderAccessoriesTable();
            } else {
                throw new Error(data.message || 'Failed to load accessories');
            }
        } catch (error) {
            console.error('Error loading accessories:', error);
            showErrorMessage('Failed to load accessories: ' + error.message);
            document.getElementById('accessoriesTable').innerHTML = 
                '<p class="error-message">Failed to load accessories. Please try again.</p>';
        } finally {
            hideLoader('accessoriesTable');
        }
    }

    renderAccessoriesTable() {
        const container = document.getElementById('accessoriesTable');
        
        if (!this.accessories || this.accessories.length === 0) {
            container.innerHTML = '<p class="no-data">No accessories found.</p>';
            return;
        }

        const tableHTML = `
            <div class="table-responsive">
                <table class="admin-table">
                    <thead>
                        <tr>
                            <th>Image</th>
                            <th>Name</th>
                            <th>Type</th>
                            <th>Category</th>
                            <th>Price</th>
                            <th>Stock</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${this.accessories.map(accessory => this.renderAccessoryRow(accessory)).join('')}
                    </tbody>
                </table>
            </div>
        `;

        container.innerHTML = tableHTML;
    }

    renderAccessoryRow(accessory) {
        const primaryImage = accessory.images?.find(img => img.isPrimary)?.url || 
                            accessory.images?.[0]?.url || 
                            '/uploads/placeholder-accessory.jpg';
        
        const stockStatus = accessory.stock?.isInStock ? 
            (accessory.stock.quantity <= accessory.stock.lowStockThreshold ? 'Low Stock' : 'In Stock') : 
            'Out of Stock';
        
        const stockClass = accessory.stock?.isInStock ? 
            (accessory.stock.quantity <= accessory.stock.lowStockThreshold ? 'warning' : 'success') : 
            'error';

        return `
            <tr>
                <td>
                    <img src="${primaryImage}" alt="${accessory.name?.en || 'Accessory'}" 
                         class="table-image" onerror="this.onerror=null; this.src='/uploads/placeholder-accessory.jpg'">
                </td>
                <td>
                    <div class="item-info">
                        <div class="item-name">${accessory.name?.en || 'N/A'}</div>
                        <div class="item-name-ar">${accessory.name?.ar || ''}</div>
                        ${accessory.brand ? `<div class="item-brand">${accessory.brand}</div>` : ''}
                    </div>
                </td>
                <td>
                    <span class="badge badge-${this.getTypeBadgeClass(accessory.type)}">${accessory.type}</span>
                </td>
                <td>${accessory.category || 'N/A'}</td>
                <td>
                    <div class="price-info">
                        <div class="current-price">${accessory.price?.regular || 0} ${accessory.price?.currency || 'AED'}</div>
                        ${accessory.price?.sale && accessory.price.sale < accessory.price.regular ? 
                            `<div class="sale-price">${accessory.price.sale} ${accessory.price.currency}</div>` : ''}
                    </div>
                </td>
                <td>
                    <div class="stock-info">
                        <span class="stock-quantity">${accessory.stock?.quantity || 0}</span>
                        <span class="stock-status badge badge-${stockClass}">${stockStatus}</span>
                    </div>
                </td>
                <td>
                    <div class="status-badges">
                        <span class="badge badge-${accessory.isActive ? 'success' : 'secondary'}">
                            ${accessory.isActive ? 'Active' : 'Inactive'}
                        </span>
                        ${accessory.isFeatured ? '<span class="badge badge-warning">Featured</span>' : ''}
                    </div>
                </td>
                <td>
                    <div class="action-buttons">
                        <button class="btn btn-sm btn-primary" onclick="accessoriesManager.viewAccessory('${accessory._id}')" title="View Details">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn btn-sm btn-secondary" onclick="accessoriesManager.editAccessory('${accessory._id}')" title="Edit">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-warning" onclick="accessoriesManager.updateStock('${accessory._id}')" title="Update Stock">
                            <i class="fas fa-boxes"></i>
                        </button>
                        <button class="btn btn-sm btn-${accessory.isActive ? 'danger' : 'success'}" 
                                onclick="accessoriesManager.toggleStatus('${accessory._id}')" 
                                title="${accessory.isActive ? 'Deactivate' : 'Activate'}">
                            <i class="fas fa-${accessory.isActive ? 'times' : 'check'}"></i>
                        </button>
                        <button class="btn btn-sm btn-danger" onclick="accessoriesManager.deleteAccessory('${accessory._id}')" title="Delete">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }

    getTypeBadgeClass(type) {
        const typeClasses = {
            'grinder': 'primary',
            'mug': 'info',
            'filter': 'warning',
            'scale': 'success',
            'kettle': 'secondary',
            'dripper': 'primary',
            'press': 'info',
            'other': 'secondary'
        };
        return typeClasses[type] || 'secondary';
    }

    async viewAccessory(id) {
        try {
            const response = await fetch(`/api/accessories/${id}`);
            const data = await response.json();

            if (data.success) {
                this.showAccessoryDetailsModal(data.data);
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('Error viewing accessory:', error);
            showErrorMessage('Failed to load accessory details');
        }
    }

    showAccessoryDetailsModal(accessory) {
        const modalHTML = `
            <div class="modal-overlay" onclick="closeModal()">
                <div class="modal-content" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h3><i class="fas fa-tools"></i> Accessory Details</h3>
                        <button class="close-btn" onclick="closeModal()">&times;</button>
                    </div>
                    <div class="modal-body">
                        <div class="accessory-details">
                            <div class="detail-row">
                                <label>Name (English):</label>
                                <span>${accessory.name?.en || 'N/A'}</span>
                            </div>
                            <div class="detail-row">
                                <label>Name (Arabic):</label>
                                <span>${accessory.name?.ar || 'N/A'}</span>
                            </div>
                            <div class="detail-row">
                                <label>Type:</label>
                                <span class="badge badge-${this.getTypeBadgeClass(accessory.type)}">${accessory.type}</span>
                            </div>
                            <div class="detail-row">
                                <label>Category:</label>
                                <span>${accessory.category}</span>
                            </div>
                            ${accessory.brand ? `
                                <div class="detail-row">
                                    <label>Brand:</label>
                                    <span>${accessory.brand}</span>
                                </div>
                            ` : ''}
                            <div class="detail-row">
                                <label>Price:</label>
                                <span>${accessory.formattedPrice || `${accessory.price?.regular} ${accessory.price?.currency}`}</span>
                            </div>
                            <div class="detail-row">
                                <label>Stock:</label>
                                <span>${accessory.stockStatus} (${accessory.stock?.quantity || 0} units)</span>
                            </div>
                            <div class="detail-row">
                                <label>Description (English):</label>
                                <p>${accessory.description?.en || 'N/A'}</p>
                            </div>
                            <div class="detail-row">
                                <label>Description (Arabic):</label>
                                <p>${accessory.description?.ar || 'N/A'}</p>
                            </div>
                            ${accessory.specifications?.material?.length ? `
                                <div class="detail-row">
                                    <label>Materials:</label>
                                    <span>${accessory.specifications.material.join(', ')}</span>
                                </div>
                            ` : ''}
                            ${accessory.analytics ? `
                                <div class="detail-row">
                                    <label>Analytics:</label>
                                    <div class="analytics-info">
                                        <span>Views: ${accessory.analytics.viewCount}</span>
                                        <span>Purchases: ${accessory.analytics.purchaseCount}</span>
                                        <span>Rating: ${accessory.analytics.avgRating.toFixed(1)}/5</span>
                                    </div>
                                </div>
                            ` : ''}
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-secondary" onclick="closeModal()">Close</button>
                        <button class="btn btn-primary" onclick="accessoriesManager.editAccessory('${accessory._id}')">Edit</button>
                    </div>
                </div>
            </div>
        `;

        document.body.insertAdjacentHTML('beforeend', modalHTML);
    }

    async toggleStatus(id) {
        try {
            const response = await fetch(`/api/accessories/${id}/toggle-status`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
                }
            });

            const data = await response.json();

            if (data.success) {
                showSuccessMessage(data.message);
                await this.loadAccessories();
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('Error toggling accessory status:', error);
            showErrorMessage('Failed to toggle accessory status');
        }
    }

    async updateStock(id) {
        const quantity = prompt('Enter new stock quantity:');
        if (quantity === null) return;

        const stockQuantity = parseInt(quantity);
        if (isNaN(stockQuantity) || stockQuantity < 0) {
            showErrorMessage('Please enter a valid stock quantity');
            return;
        }

        try {
            const response = await fetch(`/api/accessories/${id}/stock`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
                },
                body: JSON.stringify({ quantity: stockQuantity })
            });

            const data = await response.json();

            if (data.success) {
                showSuccessMessage('Stock updated successfully');
                await this.loadAccessories();
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('Error updating stock:', error);
            showErrorMessage('Failed to update stock');
        }
    }

    async deleteAccessory(id) {
        if (!confirm('Are you sure you want to delete this accessory? This action cannot be undone.')) {
            return;
        }

        try {
            const response = await fetch(`/api/accessories/${id}`, {
                method: 'DELETE',
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
                }
            });

            const data = await response.json();

            if (data.success) {
                showSuccessMessage('Accessory deleted successfully');
                await this.loadAccessories();
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('Error deleting accessory:', error);
            showErrorMessage('Failed to delete accessory');
        }
    }

    showAddModal() {
        this.currentAccessory = null;
        this.showAccessoryModal();
    }

    async editAccessory(id) {
        try {
            const response = await fetch(`/api/accessories/${id}`);
            const data = await response.json();

            if (data.success) {
                this.currentAccessory = data.data;
                this.showAccessoryModal(data.data);
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('Error loading accessory for edit:', error);
            showErrorMessage('Failed to load accessory details');
        }
    }

    showAccessoryModal(accessory = null) {
        const isEdit = accessory !== null;
        const title = isEdit ? 'Edit Accessory' : 'Add New Accessory';
        
        const modalHTML = `
            <div class="modal-overlay" onclick="closeModal()">
                <div class="modal-content accessory-modal" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h3><i class="fas fa-${isEdit ? 'edit' : 'plus'}"></i> ${title}</h3>
                        <button class="close-btn" onclick="closeModal()">&times;</button>
                    </div>
                    <form id="accessoryForm" class="modal-body">
                        <div class="form-grid">
                            <!-- Basic Information -->
                            <div class="form-section">
                                <h4>Basic Information</h4>
                                
                                <div class="form-row">
                                    <div class="form-group">
                                        <label for="nameEn">Name (English) *</label>
                                        <input type="text" id="nameEn" name="nameEn" required 
                                               value="${accessory?.name?.en || ''}" placeholder="Enter English name">
                                    </div>
                                    <div class="form-group">
                                        <label for="nameAr">Name (Arabic) *</label>
                                        <input type="text" id="nameAr" name="nameAr" required 
                                               value="${accessory?.name?.ar || ''}" placeholder="أدخل الاسم العربي">
                                    </div>
                                </div>

                                <div class="form-row">
                                    <div class="form-group">
                                        <label for="accessoryType">Type *</label>
                                        <select id="accessoryType" name="type" required>
                                            <option value="">Select Type</option>
                                            ${this.accessoryTypes.map(type => `
                                                <option value="${type.slug}" ${accessory?.type === type.slug ? 'selected' : ''}>
                                                    ${type.name.en}
                                                </option>
                                            `).join('')}
                                        </select>
                                        <small class="form-help">
                                            Don't see your type? <a href="#" onclick="alert('Go to Accessory Types Management to add new types')">Add new type</a>
                                        </small>
                                    </div>
                                    <div class="form-group">
                                        <label for="category">Category *</label>
                                        <input type="text" id="category" name="category" required 
                                               value="${accessory?.category || ''}" placeholder="e.g., Brewing Equipment">
                                    </div>
                                </div>

                                <div class="form-row">
                                    <div class="form-group">
                                        <label for="brand">Brand</label>
                                        <input type="text" id="brand" name="brand" 
                                               value="${accessory?.brand || ''}" placeholder="Brand name">
                                    </div>
                                    <div class="form-group">
                                        <label for="sku">SKU</label>
                                        <input type="text" id="sku" name="sku" 
                                               value="${accessory?.sku || ''}" placeholder="Product SKU">
                                    </div>
                                </div>
                            </div>

                            <!-- Descriptions -->
                            <div class="form-section">
                                <h4>Descriptions</h4>
                                
                                <div class="form-group">
                                    <label for="descriptionEn">Description (English) *</label>
                                    <textarea id="descriptionEn" name="descriptionEn" required rows="3" 
                                              placeholder="Enter English description">${accessory?.description?.en || ''}</textarea>
                                </div>
                                
                                <div class="form-group">
                                    <label for="descriptionAr">Description (Arabic) *</label>
                                    <textarea id="descriptionAr" name="descriptionAr" required rows="3" 
                                              placeholder="أدخل الوصف العربي">${accessory?.description?.ar || ''}</textarea>
                                </div>
                            </div>

                            <!-- Pricing -->
                            <div class="form-section">
                                <h4>Pricing</h4>
                                
                                <div class="form-row">
                                    <div class="form-group">
                                        <label for="regularPrice">Regular Price *</label>
                                        <input type="number" id="regularPrice" name="regularPrice" required min="0" step="0.01"
                                               value="${accessory?.price?.regular || ''}" placeholder="0.00">
                                    </div>
                                    <div class="form-group">
                                        <label for="salePrice">Sale Price</label>
                                        <input type="number" id="salePrice" name="salePrice" min="0" step="0.01"
                                               value="${accessory?.price?.sale || ''}" placeholder="0.00">
                                    </div>
                                </div>

                                <div class="form-row">
                                    <div class="form-group">
                                        <label for="currency">Currency</label>
                                        <select id="currency" name="currency">
                                            <option value="AED" ${accessory?.price?.currency === 'AED' ? 'selected' : ''}>AED</option>
                                            <option value="USD" ${accessory?.price?.currency === 'USD' ? 'selected' : ''}>USD</option>
                                            <option value="EUR" ${accessory?.price?.currency === 'EUR' ? 'selected' : ''}>EUR</option>
                                        </select>
                                    </div>
                                </div>
                            </div>

                            <!-- Stock -->
                            <div class="form-section">
                                <h4>Stock Management</h4>
                                
                                <div class="form-row">
                                    <div class="form-group">
                                        <label for="quantity">Stock Quantity *</label>
                                        <input type="number" id="quantity" name="quantity" required min="0"
                                               value="${accessory?.stock?.quantity || 0}" placeholder="0">
                                    </div>
                                    <div class="form-group">
                                        <label for="lowStockThreshold">Low Stock Threshold</label>
                                        <input type="number" id="lowStockThreshold" name="lowStockThreshold" min="0"
                                               value="${accessory?.stock?.lowStockThreshold || 5}" placeholder="5">
                                    </div>
                                </div>

                                <div class="form-group">
                                    <label>
                                        <input type="checkbox" id="isInStock" name="isInStock" 
                                               ${accessory?.stock?.isInStock !== false ? 'checked' : ''}>
                                        Item is in stock
                                    </label>
                                </div>
                            </div>

                            <!-- Images -->
                            <div class="form-section">
                                <h4>Product Images</h4>
                                
                                <div class="form-group">
                                    <label>Upload Image</label>
                                    <input type="file" id="accessoryImageFile" accept="image/*" 
                                           onchange="accessoriesManager.handleImageUpload(event)">
                                    <small class="form-help">Upload a new image (JPG, PNG, WebP - Max 5MB)</small>
                                </div>
                                
                                <div class="form-group">
                                    <label for="imageUrl">Or use Image URL</label>
                                    <input type="url" id="imageUrl" name="imageUrl" 
                                           value="${accessory?.images?.[0]?.url || ''}" 
                                           placeholder="https://example.com/image.jpg or /uploads/accessory.jpg">
                                    <small class="form-help">Paste an existing image URL or use the upload above</small>
                                </div>

                                <div class="form-group">
                                    <label for="imageAltEn">Image Alt Text (English)</label>
                                    <input type="text" id="imageAltEn" name="imageAltEn" 
                                           value="${accessory?.images?.[0]?.alt?.en || ''}" 
                                           placeholder="Describe the image">
                                </div>

                                <div class="form-group">
                                    <label for="imageAltAr">Image Alt Text (Arabic)</label>
                                    <input type="text" id="imageAltAr" name="imageAltAr" 
                                           value="${accessory?.images?.[0]?.alt?.ar || ''}" 
                                           placeholder="وصف الصورة">
                                </div>

                                <div id="accessoryImagePreview" class="image-preview" style="display: ${accessory?.images?.[0]?.url ? 'block' : 'none'}">
                                    <label>Image Preview:</label>
                                    <img id="accessoryPreviewImg" src="${accessory?.images?.[0]?.url || ''}" alt="Preview" 
                                         style="max-width: 200px; max-height: 200px; object-fit: cover; border-radius: 8px; border: 1px solid #ddd; margin-top: 8px;">
                                    <button type="button" class="btn btn-sm btn-danger" style="margin-top: 8px;" 
                                            onclick="accessoriesManager.removeImage()">
                                        <i class="fas fa-times"></i> Remove Image
                                    </button>
                                </div>

                                <div id="accessoryImageUploadProgress" style="display: none; margin-top: 10px;">
                                    <div class="progress-bar">
                                        <div class="progress-fill" id="accessoryUploadProgressBar" style="width: 0%"></div>
                                    </div>
                                    <p class="progress-text">Uploading: <span id="accessoryUploadProgressText">0%</span></p>
                                </div>

                                <div class="form-help-box">
                                    <i class="fas fa-info-circle"></i>
                                    <div>
                                        <strong>Image Guidelines:</strong>
                                        <ul>
                                            <li>Click "Upload Image" to upload from your computer</li>
                                            <li>Or paste an existing image URL</li>
                                            <li>Recommended size: 800x800px or higher</li>
                                            <li>Format: JPG, PNG, or WebP</li>
                                            <li>Maximum file size: 5MB</li>
                                        </ul>
                                    </div>
                                </div>
                            </div>

                            <!-- Status -->
                            <div class="form-section">
                                <h4>Status & Visibility</h4>
                                
                                <div class="form-group">
                                    <label>
                                        <input type="checkbox" id="isActive" name="isActive" 
                                               ${accessory?.isActive !== false ? 'checked' : ''}>
                                        Active (visible to customers)
                                    </label>
                                </div>
                                
                                <div class="form-group">
                                    <label>
                                        <input type="checkbox" id="isFeatured" name="isFeatured" 
                                               ${accessory?.isFeatured ? 'checked' : ''}>
                                        Featured item
                                    </label>
                                </div>

                                <div class="form-group">
                                    <label for="displayOrder">Display Order</label>
                                    <input type="number" id="displayOrder" name="displayOrder" min="0"
                                           value="${accessory?.displayOrder || 0}" placeholder="0">
                                </div>
                            </div>
                        </div>
                    </form>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" onclick="closeModal()">Cancel</button>
                        <button type="button" class="btn btn-primary" onclick="accessoriesManager.saveAccessory()">
                            ${isEdit ? 'Update' : 'Create'} Accessory
                        </button>
                    </div>
                </div>
            </div>
        `;

        document.body.insertAdjacentHTML('beforeend', modalHTML);
    }

    async saveAccessory() {
        const form = document.getElementById('accessoryForm');
        const formData = new FormData(form);
        
        // Build accessory object
        const accessoryData = {
            name: {
                en: formData.get('nameEn'),
                ar: formData.get('nameAr')
            },
            description: {
                en: formData.get('descriptionEn'),
                ar: formData.get('descriptionAr')
            },
            type: formData.get('type'),
            category: formData.get('category'),
            brand: formData.get('brand') || undefined,
            sku: formData.get('sku') || undefined,
            price: {
                regular: parseFloat(formData.get('regularPrice')),
                sale: formData.get('salePrice') ? parseFloat(formData.get('salePrice')) : undefined,
                currency: formData.get('currency') || 'AED'
            },
            stock: {
                quantity: parseInt(formData.get('quantity')),
                lowStockThreshold: parseInt(formData.get('lowStockThreshold')) || 5,
                isInStock: formData.get('isInStock') === 'on'
            },
            isActive: formData.get('isActive') === 'on',
            isFeatured: formData.get('isFeatured') === 'on',
            displayOrder: parseInt(formData.get('displayOrder')) || 0
        };

        // Add image if provided
        const imageUrl = formData.get('imageUrl');
        if (imageUrl && imageUrl.trim()) {
            accessoryData.images = [{
                url: imageUrl.trim(),
                alt: {
                    en: formData.get('imageAltEn') || accessoryData.name.en,
                    ar: formData.get('imageAltAr') || accessoryData.name.ar
                },
                isPrimary: true,
                order: 0
            }];
        }

        // Validation
        if (!accessoryData.name.en || !accessoryData.name.ar || !accessoryData.description.en || 
            !accessoryData.description.ar || !accessoryData.type || !accessoryData.category || 
            !accessoryData.price.regular) {
            showErrorMessage('Please fill in all required fields');
            return;
        }

        if (accessoryData.price.sale && accessoryData.price.sale >= accessoryData.price.regular) {
            showErrorMessage('Sale price must be less than regular price');
            return;
        }

        try {
            const isEdit = this.currentAccessory !== null;
            const url = isEdit ? `/api/accessories/${this.currentAccessory._id}` : '/api/accessories';
            const method = isEdit ? 'PUT' : 'POST';

            const response = await fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
                },
                body: JSON.stringify(accessoryData)
            });

            const data = await response.json();

            if (data.success) {
                showSuccessMessage(isEdit ? 'Accessory updated successfully!' : 'Accessory created successfully!');
                closeModal();
                await this.loadAccessories();
            } else {
                throw new Error(data.message || 'Failed to save accessory');
            }
        } catch (error) {
            console.error('Error saving accessory:', error);
            showErrorMessage('Failed to save accessory: ' + error.message);
        }
    }

    async handleImageUpload(event) {
        const file = event.target.files[0];
        if (!file) return;

        // Validate file
        const maxSize = 5 * 1024 * 1024; // 5MB
        if (file.size > maxSize) {
            showErrorMessage('Image file size must be less than 5MB');
            event.target.value = '';
            return;
        }

        const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];
        if (!allowedTypes.includes(file.type)) {
            showErrorMessage('Only JPG, PNG, and WebP images are allowed');
            event.target.value = '';
            return;
        }

        try {
            // Show progress
            document.getElementById('accessoryImageUploadProgress').style.display = 'block';
            
            const formData = new FormData();
            formData.append('image', file);

            // Upload with progress tracking
            const xhr = new XMLHttpRequest();
            
            xhr.upload.addEventListener('progress', (e) => {
                if (e.lengthComputable) {
                    const percentComplete = (e.loaded / e.total) * 100;
                    document.getElementById('accessoryUploadProgressBar').style.width = percentComplete + '%';
                    document.getElementById('accessoryUploadProgressText').textContent = Math.round(percentComplete) + '%';
                }
            });

            xhr.addEventListener('load', () => {
                document.getElementById('accessoryImageUploadProgress').style.display = 'none';
                
                if (xhr.status === 200) {
                    const response = JSON.parse(xhr.responseText);
                    if (response.success) {
                        const imageUrl = response.url || response.imageUrl || response.data?.url;
                        
                        // Update the image URL field
                        document.getElementById('imageUrl').value = imageUrl;
                        
                        // Show preview
                        document.getElementById('accessoryImagePreview').style.display = 'block';
                        document.getElementById('accessoryPreviewImg').src = imageUrl;
                        
                        showSuccessMessage('Image uploaded successfully!');
                    } else {
                        throw new Error(response.message || 'Upload failed');
                    }
                } else {
                    throw new Error('Upload failed with status: ' + xhr.status);
                }
            });

            xhr.addEventListener('error', () => {
                document.getElementById('accessoryImageUploadProgress').style.display = 'none';
                showErrorMessage('Failed to upload image. Please try again.');
            });

            xhr.open('POST', '/api/accessories/upload/image');
            const token = localStorage.getItem('adminToken');
            if (token) {
                xhr.setRequestHeader('Authorization', 'Bearer ' + token);
            }
            xhr.send(formData);

        } catch (error) {
            console.error('Error uploading image:', error);
            showErrorMessage('Failed to upload image: ' + error.message);
            document.getElementById('accessoryImageUploadProgress').style.display = 'none';
        }
    }

    removeImage() {
        document.getElementById('imageUrl').value = '';
        document.getElementById('accessoryImagePreview').style.display = 'none';
        document.getElementById('accessoryPreviewImg').src = '';
        document.getElementById('accessoryImageFile').value = '';
        showSuccessMessage('Image removed');
    }
}

// Initialize the accessories manager
const accessoriesManager = new AccessoriesManager();
