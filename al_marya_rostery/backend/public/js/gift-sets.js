// Gift Sets Management System
class GiftSetsManager {
    constructor() {
        this.giftSets = [];
        this.currentGiftSet = null;
        this.filters = {
            occasion: '',
            status: '',
            search: ''
        };
    }

    async init() {
        console.log('🎁 Initializing Gift Sets Manager...');
        await this.loadGiftSets();
    }

    async loadGiftSets() {
        try {
            showLoader('giftSetsTable');
            console.log('🎁 Loading gift sets...');
            
            const occasionFilter = document.getElementById('giftSetOccasionFilter')?.value || '';
            const statusFilter = document.getElementById('giftSetStatusFilter')?.value || '';
            
            let url = '/api/gift-sets';
            const params = new URLSearchParams();
            
            if (occasionFilter) params.append('occasion', occasionFilter);
            if (statusFilter === 'active') params.append('available', 'true');
            if (statusFilter === 'featured') params.append('featured', 'true');
            if (statusFilter === 'popular') params.append('popular', 'true');
            
            if (params.toString()) {
                url += '?' + params.toString();
            }

            console.log('🌐 Fetching from:', url);
            const response = await fetch(url);
            const data = await response.json();

            console.log('📦 Response received:', data.success, 'Data count:', data.data?.length || 0);

            if (data.success) {
                this.giftSets = data.data || [];
                console.log('✅ Gift sets loaded successfully:', this.giftSets.length);
                this.renderGiftSetsTable();
            } else {
                throw new Error(data.message || 'Failed to load gift sets');
            }
        } catch (error) {
            console.error('❌ Error loading gift sets:', error);
            showErrorMessage('Failed to load gift sets: ' + error.message);
            document.getElementById('giftSetsTable').innerHTML = 
                '<p class="error-message">Failed to load gift sets. Please try again.</p>';
        } finally {
            hideLoader('giftSetsTable');
        }
    }

    renderGiftSetsTable() {
        const container = document.getElementById('giftSetsTable');
        
        if (!this.giftSets || this.giftSets.length === 0) {
            container.innerHTML = '<p class="no-data">No gift sets found.</p>';
            return;
        }

        console.log('🎨 Rendering gift sets table with', this.giftSets.length, 'items');

        const tableHTML = `
            <div class="table-responsive">
                <table class="admin-table">
                    <thead>
                        <tr>
                            <th>Image</th>
                            <th>Name</th>
                            <th>Occasion</th>
                            <th>Audience</th>
                            <th>Price</th>
                            <th>Items</th>
                            <th>Availability</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${this.giftSets.map((giftSet, index) => {
                            try {
                                return this.renderGiftSetRow(giftSet);
                            } catch (error) {
                                console.error('Error rendering gift set row', index, ':', error, giftSet);
                                return `<tr><td colspan="9" class="error-row">Error rendering gift set: ${giftSet?.name?.en || 'Unknown'}</td></tr>`;
                            }
                        }).join('')}
                    </tbody>
                </table>
            </div>
        `;

        container.innerHTML = tableHTML;
        console.log('✅ Gift sets table rendered successfully');
    }

    renderGiftSetRow(giftSet) {
        console.log('🎯 Rendering row for gift set:', giftSet.name?.en || giftSet.name || 'No Name', giftSet);
        
        const primaryImage = giftSet.images?.find(img => img.isPrimary)?.url || 
                            giftSet.images?.[0]?.url || 
                            '/uploads/placeholder-gift.jpg';

        return `
            <tr>
                <td>
                    <img src="${primaryImage}" alt="${giftSet.name?.en || 'Gift Set'}" 
                         class="table-image" onerror="this.onerror=null; this.src='/uploads/placeholder-gift.jpg'">
                </td>
                <td>
                    <div class="item-info">
                        <div class="item-name">${giftSet.name?.en || 'N/A'}</div>
                        <div class="item-name-ar">${giftSet.name?.ar || ''}</div>
                    </div>
                </td>
                <td>
                    <span class="badge badge-${this.getOccasionBadgeClass(giftSet.occasion)}">${giftSet.occasion}</span>
                </td>
                <td>
                    <span class="badge badge-info">${giftSet.targetAudience}</span>
                </td>
                <td>
                    <div class="price-info">
                        <div class="current-price">${giftSet.price?.regular || 0} ${giftSet.price?.currency || 'AED'}</div>
                        ${giftSet.price?.sale && giftSet.price.sale < giftSet.price.regular ? 
                            `<div class="sale-price">${giftSet.price.sale} ${giftSet.price.currency}</div>` : ''}
                        ${giftSet.discountPercentage > 0 ? 
                            `<div class="discount-badge">${giftSet.discountPercentage}% OFF</div>` : ''}
                    </div>
                </td>
                <td>
                    <span class="items-count">${giftSet.totalItems || giftSet.contents?.length || 0} items</span>
                </td>
                <td>
                    <span class="badge badge-${this.getAvailabilityBadgeClass(giftSet.availabilityStatus)}">
                        ${giftSet.availabilityStatus || 'Available'}
                    </span>
                </td>
                <td>
                    <div class="status-badges">
                        <span class="badge badge-${giftSet.isActive ? 'success' : 'secondary'}">
                            ${giftSet.isActive ? 'Active' : 'Inactive'}
                        </span>
                        ${giftSet.isFeatured ? '<span class="badge badge-warning">Featured</span>' : ''}
                        ${giftSet.isPopular ? '<span class="badge badge-primary">Popular</span>' : ''}
                    </div>
                </td>
                <td>
                    <div class="action-buttons">
                        <button class="btn btn-sm btn-primary" onclick="giftSetsManager.viewGiftSet('${giftSet._id}')" title="View Details">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn btn-sm btn-secondary" onclick="giftSetsManager.editGiftSet('${giftSet._id}')" title="Edit">
                            <i class="fas fa-edit"></i>
                        </button>
                        ${giftSet.availability?.limitedQuantity ? `
                            <button class="btn btn-sm btn-warning" onclick="giftSetsManager.updateLimitedQuantity('${giftSet._id}')" title="Update Quantity">
                                <i class="fas fa-hashtag"></i>
                            </button>
                        ` : ''}
                        <button class="btn btn-sm btn-${giftSet.isActive ? 'danger' : 'success'}" 
                                onclick="giftSetsManager.toggleStatus('${giftSet._id}')" 
                                title="${giftSet.isActive ? 'Deactivate' : 'Activate'}">
                            <i class="fas fa-${giftSet.isActive ? 'times' : 'check'}"></i>
                        </button>
                        <button class="btn btn-sm btn-danger" onclick="giftSetsManager.deleteGiftSet('${giftSet._id}')" title="Delete">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }

    getOccasionBadgeClass(occasion) {
        const occasionClasses = {
            'birthday': 'primary',
            'anniversary': 'success',
            'wedding': 'warning',
            'corporate': 'info',
            'holiday': 'danger',
            'thank-you': 'secondary',
            'housewarming': 'primary',
            'graduation': 'success',
            'general': 'secondary'
        };
        return occasionClasses[occasion] || 'secondary';
    }

    getAvailabilityBadgeClass(status) {
        if (status?.includes('Unavailable') || status?.includes('Sold Out')) return 'danger';
        if (status?.includes('Limited')) return 'warning';
        if (status?.includes('Seasonal')) return 'info';
        return 'success';
    }

    async viewGiftSet(id) {
        try {
            const response = await fetch(`/api/gift-sets/${id}`);
            const data = await response.json();

            if (data.success) {
                this.showGiftSetDetailsModal(data.data);
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('Error viewing gift set:', error);
            showErrorMessage('Failed to load gift set details');
        }
    }

    showGiftSetDetailsModal(giftSet) {
        const contentsHTML = giftSet.contents?.map(item => `
            <div class="content-item">
                <span class="item-quantity">${item.quantity}x</span>
                <span class="item-name">${item.item?.customItem?.name?.en || 'Item'}</span>
                ${item.isHighlight ? '<span class="highlight-badge">★ Highlight</span>' : ''}
            </div>
        `).join('') || '<p>No contents listed</p>';

        const modalHTML = `
            <div class="modal-overlay" onclick="closeModal()">
                <div class="modal-content large-modal" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h3><i class="fas fa-gift-box"></i> Gift Set Details</h3>
                        <button class="close-btn" onclick="closeModal()">&times;</button>
                    </div>
                    <div class="modal-body">
                        <div class="gift-set-details">
                            <div class="detail-row">
                                <label>Name (English):</label>
                                <span>${giftSet.name?.en || 'N/A'}</span>
                            </div>
                            <div class="detail-row">
                                <label>Name (Arabic):</label>
                                <span>${giftSet.name?.ar || 'N/A'}</span>
                            </div>
                            <div class="detail-row">
                                <label>Occasion:</label>
                                <span class="badge badge-${this.getOccasionBadgeClass(giftSet.occasion)}">${giftSet.occasion}</span>
                            </div>
                            <div class="detail-row">
                                <label>Target Audience:</label>
                                <span class="badge badge-info">${giftSet.targetAudience}</span>
                            </div>
                            <div class="detail-row">
                                <label>Price:</label>
                                <span>${giftSet.formattedPrice || `${giftSet.price?.regular} ${giftSet.price?.currency}`}</span>
                            </div>
                            <div class="detail-row">
                                <label>Availability:</label>
                                <span class="badge badge-${this.getAvailabilityBadgeClass(giftSet.availabilityStatus)}">
                                    ${giftSet.availabilityStatus || 'Available'}
                                </span>
                            </div>
                            <div class="detail-row">
                                <label>Description (English):</label>
                                <p>${giftSet.description?.en || 'N/A'}</p>
                            </div>
                            <div class="detail-row">
                                <label>Description (Arabic):</label>
                                <p>${giftSet.description?.ar || 'N/A'}</p>
                            </div>
                            <div class="detail-row">
                                <label>Contents:</label>
                                <div class="contents-list">${contentsHTML}</div>
                            </div>
                            ${giftSet.packaging ? `
                                <div class="detail-row">
                                    <label>Packaging:</label>
                                    <span>${giftSet.packaging.type} - ${giftSet.packaging.material || 'Standard'}</span>
                                </div>
                            ` : ''}
                            ${giftSet.analytics ? `
                                <div class="detail-row">
                                    <label>Analytics:</label>
                                    <div class="analytics-info">
                                        <span>Views: ${giftSet.analytics.viewCount}</span>
                                        <span>Purchases: ${giftSet.analytics.purchaseCount}</span>
                                        <span>Rating: ${giftSet.analytics.avgRating.toFixed(1)}/5</span>
                                        <span>Conversion: ${giftSet.analytics.conversionRate.toFixed(1)}%</span>
                                    </div>
                                </div>
                            ` : ''}
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-secondary" onclick="closeModal()">Close</button>
                        <button class="btn btn-primary" onclick="giftSetsManager.editGiftSet('${giftSet._id}')">Edit</button>
                    </div>
                </div>
            </div>
        `;

        document.body.insertAdjacentHTML('beforeend', modalHTML);
    }

    async toggleStatus(id) {
        try {
            const response = await fetch(`/api/gift-sets/${id}/toggle-status`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
                }
            });

            const data = await response.json();

            if (data.success) {
                showSuccessMessage(data.message);
                await this.loadGiftSets();
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('Error toggling gift set status:', error);
            showErrorMessage('Failed to toggle gift set status');
        }
    }

    async updateLimitedQuantity(id) {
        const quantity = prompt('Enter remaining quantity:');
        if (quantity === null) return;

        const remainingQuantity = parseInt(quantity);
        if (isNaN(remainingQuantity) || remainingQuantity < 0) {
            showErrorMessage('Please enter a valid quantity');
            return;
        }

        try {
            const response = await fetch(`/api/gift-sets/${id}/limited-quantity`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
                },
                body: JSON.stringify({ quantity: remainingQuantity })
            });

            const data = await response.json();

            if (data.success) {
                showSuccessMessage('Limited quantity updated successfully');
                await this.loadGiftSets();
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('Error updating limited quantity:', error);
            showErrorMessage('Failed to update limited quantity');
        }
    }

    async deleteGiftSet(id) {
        if (!confirm('Are you sure you want to delete this gift set? This action cannot be undone.')) {
            return;
        }

        try {
            const response = await fetch(`/api/gift-sets/${id}`, {
                method: 'DELETE',
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
                }
            });

            const data = await response.json();

            if (data.success) {
                showSuccessMessage('Gift set deleted successfully');
                await this.loadGiftSets();
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('Error deleting gift set:', error);
            showErrorMessage('Failed to delete gift set');
        }
    }

    showAddModal() {
        this.currentGiftSet = null;
        this.showGiftSetModal();
    }

    async editGiftSet(id) {
        try {
            const response = await fetch(`/api/gift-sets/${id}`);
            const data = await response.json();

            if (data.success) {
                this.currentGiftSet = data.data;
                this.showGiftSetModal(data.data);
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('Error loading gift set for edit:', error);
            showErrorMessage('Failed to load gift set details');
        }
    }

    showGiftSetModal(giftSet = null) {
        const isEdit = giftSet !== null;
        const title = isEdit ? 'Edit Gift Set' : 'Add New Gift Set';
        
        const modalHTML = `
            <div class="modal-overlay" onclick="closeModal()">
                <div class="modal-content gift-set-modal" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h3><i class="fas fa-${isEdit ? 'edit' : 'plus'}"></i> ${title}</h3>
                        <button class="close-btn" onclick="closeModal()">&times;</button>
                    </div>
                    <form id="giftSetForm" class="modal-body">
                        <div class="form-grid">
                            <!-- Basic Information -->
                            <div class="form-section">
                                <h4>Basic Information</h4>
                                
                                <div class="form-row">
                                    <div class="form-group">
                                        <label for="nameEn">Name (English) *</label>
                                        <input type="text" id="nameEn" name="nameEn" required 
                                               value="${giftSet?.name?.en || ''}" placeholder="Enter English name">
                                    </div>
                                    <div class="form-group">
                                        <label for="nameAr">Name (Arabic) *</label>
                                        <input type="text" id="nameAr" name="nameAr" required 
                                               value="${giftSet?.name?.ar || ''}" placeholder="أدخل الاسم العربي">
                                    </div>
                                </div>

                                <div class="form-row">
                                    <div class="form-group">
                                        <label for="occasion">Occasion *</label>
                                        <select id="occasion" name="occasion" required>
                                            <option value="">Select Occasion</option>
                                            <option value="birthday" ${giftSet?.occasion === 'birthday' ? 'selected' : ''}>Birthday</option>
                                            <option value="anniversary" ${giftSet?.occasion === 'anniversary' ? 'selected' : ''}>Anniversary</option>
                                            <option value="wedding" ${giftSet?.occasion === 'wedding' ? 'selected' : ''}>Wedding</option>
                                            <option value="corporate" ${giftSet?.occasion === 'corporate' ? 'selected' : ''}>Corporate</option>
                                            <option value="holiday" ${giftSet?.occasion === 'holiday' ? 'selected' : ''}>Holiday</option>
                                            <option value="thank-you" ${giftSet?.occasion === 'thank-you' ? 'selected' : ''}>Thank You</option>
                                            <option value="housewarming" ${giftSet?.occasion === 'housewarming' ? 'selected' : ''}>Housewarming</option>
                                            <option value="graduation" ${giftSet?.occasion === 'graduation' ? 'selected' : ''}>Graduation</option>
                                            <option value="general" ${giftSet?.occasion === 'general' ? 'selected' : ''}>General</option>
                                        </select>
                                    </div>
                                    <div class="form-group">
                                        <label for="targetAudience">Target Audience *</label>
                                        <select id="targetAudience" name="targetAudience" required>
                                            <option value="">Select Audience</option>
                                            <option value="beginner" ${giftSet?.targetAudience === 'beginner' ? 'selected' : ''}>Beginner</option>
                                            <option value="enthusiast" ${giftSet?.targetAudience === 'enthusiast' ? 'selected' : ''}>Enthusiast</option>
                                            <option value="professional" ${giftSet?.targetAudience === 'professional' ? 'selected' : ''}>Professional</option>
                                            <option value="corporate" ${giftSet?.targetAudience === 'corporate' ? 'selected' : ''}>Corporate</option>
                                            <option value="family" ${giftSet?.targetAudience === 'family' ? 'selected' : ''}>Family</option>
                                            <option value="couple" ${giftSet?.targetAudience === 'couple' ? 'selected' : ''}>Couple</option>
                                            <option value="individual" ${giftSet?.targetAudience === 'individual' ? 'selected' : ''}>Individual</option>
                                        </select>
                                    </div>
                                </div>
                            </div>

                            <!-- Descriptions -->
                            <div class="form-section">
                                <h4>Descriptions</h4>
                                
                                <div class="form-group">
                                    <label for="descriptionEn">Description (English) *</label>
                                    <textarea id="descriptionEn" name="descriptionEn" required rows="3" 
                                              placeholder="Enter English description">${giftSet?.description?.en || ''}</textarea>
                                </div>
                                
                                <div class="form-group">
                                    <label for="descriptionAr">Description (Arabic) *</label>
                                    <textarea id="descriptionAr" name="descriptionAr" required rows="3" 
                                              placeholder="أدخل الوصف العربي">${giftSet?.description?.ar || ''}</textarea>
                                </div>
                            </div>

                            <!-- Pricing -->
                            <div class="form-section">
                                <h4>Pricing</h4>
                                
                                <div class="form-row">
                                    <div class="form-group">
                                        <label for="regularPrice">Regular Price *</label>
                                        <input type="number" id="regularPrice" name="regularPrice" required min="0" step="0.01"
                                               value="${giftSet?.price?.regular || ''}" placeholder="0.00">
                                    </div>
                                    <div class="form-group">
                                        <label for="salePrice">Sale Price</label>
                                        <input type="number" id="salePrice" name="salePrice" min="0" step="0.01"
                                               value="${giftSet?.price?.sale || ''}" placeholder="0.00">
                                    </div>
                                </div>

                                <div class="form-row">
                                    <div class="form-group">
                                        <label for="currency">Currency</label>
                                        <select id="currency" name="currency">
                                            <option value="AED" ${giftSet?.price?.currency === 'AED' ? 'selected' : ''}>AED</option>
                                            <option value="USD" ${giftSet?.price?.currency === 'USD' ? 'selected' : ''}>USD</option>
                                            <option value="EUR" ${giftSet?.price?.currency === 'EUR' ? 'selected' : ''}>EUR</option>
                                        </select>
                                    </div>
                                    <div class="form-group">
                                        <label for="discountPercentage">Discount %</label>
                                        <input type="number" id="discountPercentage" name="discountPercentage" min="0" max="100"
                                               value="${giftSet?.discountPercentage || 0}" placeholder="0">
                                    </div>
                                </div>
                            </div>

                            <!-- Availability -->
                            <div class="form-section">
                                <h4>Availability</h4>
                                
                                <div class="form-row">
                                    <div class="form-group">
                                        <label for="availabilityStatus">Availability Status</label>
                                        <select id="availabilityStatus" name="availabilityStatus">
                                            <option value="Available" ${giftSet?.availabilityStatus === 'Available' ? 'selected' : ''}>Available</option>
                                            <option value="Limited Stock" ${giftSet?.availabilityStatus === 'Limited Stock' ? 'selected' : ''}>Limited Stock</option>
                                            <option value="Seasonal" ${giftSet?.availabilityStatus === 'Seasonal' ? 'selected' : ''}>Seasonal</option>
                                            <option value="Unavailable" ${giftSet?.availabilityStatus === 'Unavailable' ? 'selected' : ''}>Unavailable</option>
                                        </select>
                                    </div>
                                    <div class="form-group">
                                        <label for="totalItems">Total Items</label>
                                        <input type="number" id="totalItems" name="totalItems" min="0"
                                               value="${giftSet?.totalItems || 0}" placeholder="0">
                                    </div>
                                </div>

                                <div class="form-group">
                                    <label>
                                        <input type="checkbox" id="limitedQuantity" name="limitedQuantity" 
                                               ${giftSet?.availability?.limitedQuantity ? 'checked' : ''}>
                                        Limited Quantity Item
                                    </label>
                                </div>
                            </div>

                            <!-- Status -->
                            <div class="form-section">
                                <h4>Status & Visibility</h4>
                                
                                <div class="form-group">
                                    <label>
                                        <input type="checkbox" id="isActive" name="isActive" 
                                               ${giftSet?.isActive !== false ? 'checked' : ''}>
                                        Active (visible to customers)
                                    </label>
                                </div>
                                
                                <div class="form-group">
                                    <label>
                                        <input type="checkbox" id="isFeatured" name="isFeatured" 
                                               ${giftSet?.isFeatured ? 'checked' : ''}>
                                        Featured item
                                    </label>
                                </div>

                                <div class="form-group">
                                    <label>
                                        <input type="checkbox" id="isPopular" name="isPopular" 
                                               ${giftSet?.isPopular ? 'checked' : ''}>
                                        Popular item
                                    </label>
                                </div>

                                <div class="form-group">
                                    <label for="displayOrder">Display Order</label>
                                    <input type="number" id="displayOrder" name="displayOrder" min="0"
                                           value="${giftSet?.displayOrder || 0}" placeholder="0">
                                </div>
                            </div>

                            <!-- Gift Set Contents -->
                            <div class="form-section">
                                <h4>Gift Set Contents</h4>
                                <p class="form-note">Note: For a complete implementation, you would need to add coffee products to this gift set. This is a simplified version.</p>
                                
                                <div class="form-group">
                                    <label for="contentsNote">Contents Description</label>
                                    <textarea id="contentsNote" name="contentsNote" rows="2" 
                                              placeholder="Describe the contents of this gift set...">${giftSet?.contentsNote || ''}</textarea>
                                </div>
                            </div>
                        </div>
                    </form>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" onclick="closeModal()">Cancel</button>
                        <button type="button" class="btn btn-primary" onclick="giftSetsManager.saveGiftSet()">
                            ${isEdit ? 'Update' : 'Create'} Gift Set
                        </button>
                    </div>
                </div>
            </div>
        `;

        document.body.insertAdjacentHTML('beforeend', modalHTML);
    }

    async saveGiftSet() {
        const form = document.getElementById('giftSetForm');
        const formData = new FormData(form);
        
        // Build gift set object
        const giftSetData = {
            name: {
                en: formData.get('nameEn'),
                ar: formData.get('nameAr')
            },
            description: {
                en: formData.get('descriptionEn'),
                ar: formData.get('descriptionAr')
            },
            occasion: formData.get('occasion'),
            targetAudience: formData.get('targetAudience'),
            price: {
                regular: parseFloat(formData.get('regularPrice')),
                sale: formData.get('salePrice') ? parseFloat(formData.get('salePrice')) : undefined,
                currency: formData.get('currency') || 'AED'
            },
            discountPercentage: parseFloat(formData.get('discountPercentage')) || 0,
            availabilityStatus: formData.get('availabilityStatus') || 'Available',
            totalItems: parseInt(formData.get('totalItems')) || 0,
            availability: {
                limitedQuantity: formData.get('limitedQuantity') === 'on'
            },
            isActive: formData.get('isActive') === 'on',
            isFeatured: formData.get('isFeatured') === 'on',
            isPopular: formData.get('isPopular') === 'on',
            displayOrder: parseInt(formData.get('displayOrder')) || 0,
            contentsNote: formData.get('contentsNote') || '',
            // Create a default content item if none exists
            contents: [{
                item: {
                    itemType: 'custom',
                    customItem: {
                        name: {
                            en: formData.get('contentsNote') || 'Gift Set Items',
                            ar: formData.get('contentsNote') || 'عناصر مجموعة الهدايا'
                        },
                        description: {
                            en: formData.get('contentsNote') || 'Contents of this gift set',
                            ar: formData.get('contentsNote') || 'محتويات مجموعة الهدايا هذه'
                        }
                    }
                },
                quantity: parseInt(formData.get('totalItems')) || 1,
                isHighlight: true
            }]
        };

        // Validation
        if (!giftSetData.name.en || !giftSetData.name.ar || !giftSetData.description.en || 
            !giftSetData.description.ar || !giftSetData.occasion || !giftSetData.targetAudience || 
            !giftSetData.price.regular) {
            showErrorMessage('Please fill in all required fields');
            return;
        }

        if (giftSetData.price.sale && giftSetData.price.sale >= giftSetData.price.regular) {
            showErrorMessage('Sale price must be less than regular price');
            return;
        }

        try {
            const isEdit = this.currentGiftSet !== null;
            const url = isEdit ? `/api/gift-sets/${this.currentGiftSet._id}` : '/api/gift-sets';
            const method = isEdit ? 'PUT' : 'POST';

            const response = await fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
                },
                body: JSON.stringify(giftSetData)
            });

            const data = await response.json();

            if (data.success) {
                showSuccessMessage(isEdit ? 'Gift set updated successfully!' : 'Gift set created successfully!');
                closeModal();
                await this.loadGiftSets();
            } else {
                // Handle validation errors specifically
                if (data.errors && Array.isArray(data.errors)) {
                    const errorMessages = data.errors.map(err => err.msg || err.message).join(', ');
                    throw new Error(`Validation errors: ${errorMessages}`);
                }
                throw new Error(data.message || 'Failed to save gift set');
            }
        } catch (error) {
            console.error('Error saving gift set:', error);
            showErrorMessage('Failed to save gift set: ' + error.message);
        }
    }
}

// Initialize the gift sets manager
const giftSetsManager = new GiftSetsManager();
