/**
 * Quick Categories Management JavaScript
 * Handles CRUD operations for quick categories in the admin panel
 */

const quickCategoriesManager = {
    currentQuickCategories: [],
    currentEditingId: null,

    /**
     * Initialize quick categories management
     */
    init() {
        console.log('🟢 Quick Categories Manager initialized');
        this.loadQuickCategories();
    },

    /**
     * Load quick categories from the API
     */
    async loadQuickCategories() {
        try {
            showLoading('quickCategoriesTable');
            console.log('📊 Loading quick categories...');

            const response = await authenticatedFetch(`${API_BASE_URL}/api/quick-categories`);

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            console.log('✅ Quick categories loaded:', data);

            if (data.success) {
                this.currentQuickCategories = data.data || [];
                this.renderQuickCategoriesTable();
                this.updateStats();
            } else {
                throw new Error(data.message || 'Failed to load quick categories');
            }

        } catch (error) {
            console.error('❌ Error loading quick categories:', error);
            showToast('Failed to load quick categories: ' + error.message, 'error');
            this.renderErrorState();
        }
    },

    /**
     * Render the quick categories table
     */
    renderQuickCategoriesTable() {
        const container = document.getElementById('quickCategoriesTable');
        if (!container) return;

        if (!this.currentQuickCategories || this.currentQuickCategories.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <div class="empty-icon">⚡</div>
                    <h3>No Quick Categories</h3>
                    <p>Create your first quick category to get started</p>
                    <button class="btn btn-primary" onclick="quickCategoriesManager.showAddModal()">
                        <i class="fas fa-plus"></i> Add Quick Category
                    </button>
                </div>
            `;
            return;
        }

        const tableHTML = `
            <div class="table-container">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Image</th>
                            <th>Title</th>
                            <th>Subtitle</th>
                            <th>Order</th>
                            <th>Status</th>
                            <th>Analytics</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${this.currentQuickCategories.map(category => this.renderQuickCategoryRow(category)).join('')}
                    </tbody>
                </table>
            </div>
        `;

        container.innerHTML = tableHTML;
    },

    /**
     * Render a single quick category row
     */
    renderQuickCategoryRow(category) {
        const imageUrl = category.imageUrl || '/images/placeholder.jpg';
        const status = category.isActive ? 'Active' : 'Inactive';
        const statusClass = category.isActive ? 'status-active' : 'status-inactive';
        const colorStyle = `background-color: ${category.color}; width: 20px; height: 20px; border-radius: 50%; display: inline-block; margin-right: 8px;`;

        return `
            <tr data-id="${category._id}">
                <td>
                    <div class="product-image">
                        <img src="${imageUrl}" alt="${category.title}" style="width: 50px; height: 50px; object-fit: cover; border-radius: 8px;">
                    </div>
                </td>
                <td>
                    <div class="category-info">
                        <div style="display: flex; align-items: center;">
                            <span style="${colorStyle}"></span>
                            <strong>${category.title}</strong>
                        </div>
                        <small style="color: #666;">${category.description || 'No description'}</small>
                    </div>
                </td>
                <td>${category.subtitle}</td>
                <td>
                    <span class="order-badge">${category.displayOrder}</span>
                </td>
                <td>
                    <span class="status-badge ${statusClass}">${status}</span>
                </td>
                <td>
                    <div class="analytics-info">
                        <div>👆 ${category.clickCount || 0} clicks</div>
                        <div>👁️ ${category.viewCount || 0} views</div>
                        <div>📈 ${this.calculateCTR(category)}% CTR</div>
                    </div>
                </td>
                <td>
                    <div class="action-buttons">
                        <button class="btn-icon btn-primary" onclick="quickCategoriesManager.editQuickCategory('${category._id}')" title="Edit">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn-icon ${category.isActive ? 'btn-warning' : 'btn-success'}" onclick="quickCategoriesManager.toggleStatus('${category._id}')" title="${category.isActive ? 'Deactivate' : 'Activate'}">
                            <i class="fas fa-${category.isActive ? 'eye-slash' : 'eye'}"></i>
                        </button>
                        <button class="btn-icon btn-secondary" onclick="quickCategoriesManager.moveUp('${category._id}')" title="Move Up">
                            <i class="fas fa-arrow-up"></i>
                        </button>
                        <button class="btn-icon btn-secondary" onclick="quickCategoriesManager.moveDown('${category._id}')" title="Move Down">
                            <i class="fas fa-arrow-down"></i>
                        </button>
                        <button class="btn-icon btn-danger" onclick="quickCategoriesManager.deleteQuickCategory('${category._id}')" title="Delete">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    },

    /**
     * Calculate click-through rate
     */
    calculateCTR(category) {
        if (!category.viewCount || category.viewCount === 0) return 0;
        return ((category.clickCount || 0) / category.viewCount * 100).toFixed(1);
    },

    /**
     * Update statistics
     */
    updateStats() {
        const total = this.currentQuickCategories.length;
        const active = this.currentQuickCategories.filter(c => c.isActive).length;
        const totalClicks = this.currentQuickCategories.reduce((sum, c) => sum + (c.clickCount || 0), 0);
        const totalViews = this.currentQuickCategories.reduce((sum, c) => sum + (c.viewCount || 0), 0);
        const avgClickRate = totalViews > 0 ? ((totalClicks / totalViews) * 100).toFixed(1) : 0;

        // Update stat cards
        const elements = {
            'totalQuickCategories': total,
            'activeQuickCategories': active,
            'totalQuickClicks': totalClicks,
            'avgClickRate': `${avgClickRate}%`
        };

        Object.entries(elements).forEach(([id, value]) => {
            const element = document.getElementById(id);
            if (element) element.textContent = value;
        });
    },

    /**
     * Show add modal
     */
    showAddModal() {
        this.currentEditingId = null;
        this.resetForm();
        document.getElementById('quickCategoryModalTitle').textContent = '⚡ Create Quick Category';
        document.getElementById('quickCategoryModal').style.display = 'flex';
    },

    /**
     * Edit quick category
     */
    async editQuickCategory(id) {
        try {
            const category = this.currentQuickCategories.find(c => c._id === id);
            if (!category) {
                throw new Error('Quick category not found');
            }

            this.currentEditingId = id;
            this.populateForm(category);
            document.getElementById('quickCategoryModalTitle').textContent = '⚡ Edit Quick Category';
            document.getElementById('quickCategoryModal').style.display = 'flex';

        } catch (error) {
            console.error('❌ Error editing quick category:', error);
            showToast('Error loading quick category: ' + error.message, 'error');
        }
    },

    /**
     * Populate form with category data
     */
    populateForm(category) {
        document.getElementById('quickCategoryId').value = category._id;
        document.getElementById('quickCategoryTitle').value = category.title;
        document.getElementById('quickCategorySubtitle').value = category.subtitle;
        document.getElementById('quickCategoryDescription').value = category.description || '';
        document.getElementById('quickCategoryColor').value = category.color;
        document.getElementById('quickCategoryOrder').value = category.displayOrder;
        document.getElementById('quickCategoryLinkTo').value = category.linkTo || 'none';
        document.getElementById('quickCategoryLinkValue').value = category.linkValue || '';
        document.getElementById('quickCategoryTags').value = (category.tags || []).join(', ');
        document.getElementById('quickCategoryIsActive').checked = category.isActive;

        // Show current image if exists
        if (category.imageUrl) {
            const currentImageContainer = document.getElementById('currentImageContainer');
            const currentImage = document.getElementById('currentImage');
            currentImage.src = category.imageUrl;
            currentImageContainer.style.display = 'block';
        }
    },

    /**
     * Reset form
     */
    resetForm() {
        document.getElementById('quickCategoryForm').reset();
        document.getElementById('quickCategoryId').value = '';
        document.getElementById('quickCategoryColor').value = '#A89A6A';
        document.getElementById('quickCategoryOrder').value = '0';
        document.getElementById('quickCategoryIsActive').checked = true;
        
        // Hide image previews
        document.getElementById('quickCategoryImagePreview').style.display = 'none';
        document.getElementById('currentImageContainer').style.display = 'none';
    },

    /**
     * Handle form submission
     */
    async handleSubmit(event) {
        event.preventDefault();
        
        try {
            // Show loading on the submit button instead
            const submitBtn = event.target.querySelector('button[type="submit"]');
            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...';
            }
            
            const formData = new FormData();
            
            // Get form values
            const title = document.getElementById('quickCategoryTitle').value.trim();
            const subtitle = document.getElementById('quickCategorySubtitle').value.trim();
            const description = document.getElementById('quickCategoryDescription').value.trim();
            const color = document.getElementById('quickCategoryColor').value;
            const displayOrder = parseInt(document.getElementById('quickCategoryOrder').value) || 0;
            const linkTo = document.getElementById('quickCategoryLinkTo').value;
            const linkValue = document.getElementById('quickCategoryLinkValue').value.trim();
            const tags = document.getElementById('quickCategoryTags').value.split(',').map(t => t.trim()).filter(t => t);
            const isActive = document.getElementById('quickCategoryIsActive').checked;
            const imageFile = document.getElementById('quickCategoryImage').files[0];

            // Validation
            if (!title || !subtitle) {
                throw new Error('Title and subtitle are required');
            }

            // Append form data
            formData.append('title', title);
            formData.append('subtitle', subtitle);
            formData.append('description', description);
            formData.append('color', color);
            formData.append('displayOrder', displayOrder);
            formData.append('linkTo', linkTo);
            formData.append('linkValue', linkValue);
            formData.append('isActive', isActive);
            
            // Add tags
            tags.forEach(tag => formData.append('tags', tag));
            
            // Add image if selected
            if (imageFile) {
                formData.append('image', imageFile);
            }

            // API call
            const url = this.currentEditingId 
                ? `${API_BASE_URL}/api/quick-categories/${this.currentEditingId}`
                : `${API_BASE_URL}/api/quick-categories`;
            const method = this.currentEditingId ? 'PUT' : 'POST';

            // For FormData, we need to handle authentication differently
            const headers = {};
            if (authToken && isValidToken(authToken)) {
                headers['Authorization'] = `Bearer ${authToken}`;
            }

            const response = await fetch(url, {
                method: method,
                headers: headers,
                body: formData
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const result = await response.json();
            
            if (result.success) {
                showToast(
                    this.currentEditingId ? 'Quick category updated successfully!' : 'Quick category created successfully!',
                    'success'
                );
                this.closeModal();
                this.loadQuickCategories();
            } else {
                throw new Error(result.message || 'Failed to save quick category');
            }

        } catch (error) {
            console.error('❌ Error saving quick category:', error);
            showToast('Error saving quick category: ' + error.message, 'error');
        } finally {
            // Restore submit button
            const submitBtn = document.querySelector('#quickCategoryForm button[type="submit"]');
            if (submitBtn) {
                submitBtn.disabled = false;
                submitBtn.innerHTML = this.currentEditingId ? 
                    '<i class="fas fa-save"></i> Update Category' : 
                    '<i class="fas fa-plus"></i> Create Category';
            }
        }
    },

    /**
     * Preview image
     */
    previewImage(event) {
        const file = event.target.files[0];
        const preview = document.getElementById('quickCategoryImagePreview');
        
        if (file) {
            const reader = new FileReader();
            reader.onload = function(e) {
                preview.src = e.target.result;
                preview.style.display = 'block';
            };
            reader.readAsDataURL(file);
        } else {
            preview.style.display = 'none';
        }
    },

    /**
     * Close modal
     */
    closeModal() {
        document.getElementById('quickCategoryModal').style.display = 'none';
        this.resetForm();
        this.currentEditingId = null;
    },

    /**
     * Toggle status
     */
    async toggleStatus(id) {
        try {
            showLoading('quickCategoriesTable');
            
            const response = await authenticatedFetch(`${API_BASE_URL}/api/quick-categories/${id}/toggle-status`, {
                method: 'PUT'
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const result = await response.json();
            
            if (result.success) {
                showToast('Status updated successfully!', 'success');
                this.loadQuickCategories();
            } else {
                throw new Error(result.message || 'Failed to toggle status');
            }

        } catch (error) {
            console.error('❌ Error toggling status:', error);
            showToast('Error updating status: ' + error.message, 'error');
        }
    },

    /**
     * Delete quick category
     */
    async deleteQuickCategory(id) {
        const category = this.currentQuickCategories.find(c => c._id === id);
        if (!category) return;

        if (!confirm(`Are you sure you want to delete "${category.title}"?\n\nThis action cannot be undone.`)) {
            return;
        }

        try {
            showLoading('quickCategoriesTable');
            
            const response = await authenticatedFetch(`${API_BASE_URL}/api/quick-categories/${id}`, {
                method: 'DELETE'
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const result = await response.json();
            
            if (result.success) {
                showToast('Quick category deleted successfully!', 'success');
                this.loadQuickCategories();
            } else {
                throw new Error(result.message || 'Failed to delete quick category');
            }

        } catch (error) {
            console.error('❌ Error deleting quick category:', error);
            showToast('Error deleting quick category: ' + error.message, 'error');
        }
    },

    /**
     * Move category up in display order
     */
    async moveUp(id) {
        const categories = [...this.currentQuickCategories].sort((a, b) => a.displayOrder - b.displayOrder);
        const currentIndex = categories.findIndex(c => c._id === id);
        
        if (currentIndex <= 0) return; // Already at top
        
        const current = categories[currentIndex];
        const previous = categories[currentIndex - 1];
        
        await this.swapDisplayOrder(current._id, previous._id);
    },

    /**
     * Move category down in display order
     */
    async moveDown(id) {
        const categories = [...this.currentQuickCategories].sort((a, b) => a.displayOrder - b.displayOrder);
        const currentIndex = categories.findIndex(c => c._id === id);
        
        if (currentIndex >= categories.length - 1) return; // Already at bottom
        
        const current = categories[currentIndex];
        const next = categories[currentIndex + 1];
        
        await this.swapDisplayOrder(current._id, next._id);
    },

    /**
     * Swap display order of two categories
     */
    async swapDisplayOrder(id1, id2) {
        const cat1 = this.currentQuickCategories.find(c => c._id === id1);
        const cat2 = this.currentQuickCategories.find(c => c._id === id2);
        
        if (!cat1 || !cat2) return;

        try {
            // Just show a brief loading state on the table
            const orderedIds = [...this.currentQuickCategories]
                .sort((a, b) => a.displayOrder - b.displayOrder)
                .map(c => {
                    if (c._id === id1) return id2;
                    if (c._id === id2) return id1;
                    return c._id;
                });

            const response = await authenticatedFetch(`${API_BASE_URL}/api/quick-categories/reorder`, {
                method: 'PUT',
                body: JSON.stringify({ orderedIds })
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const result = await response.json();
            
            if (result.success) {
                showToast('Order updated successfully!', 'success');
                this.loadQuickCategories();
            } else {
                throw new Error(result.message || 'Failed to reorder categories');
            }

        } catch (error) {
            console.error('❌ Error reordering categories:', error);
            showToast('Error updating order: ' + error.message, 'error');
        }
    },

    /**
     * Render error state
     */
    renderErrorState() {
        const container = document.getElementById('quickCategoriesTable');
        if (!container) return;

        container.innerHTML = `
            <div class="error-state">
                <div class="error-icon">❌</div>
                <h3>Error Loading Quick Categories</h3>
                <p>There was a problem loading the quick categories. Please try again.</p>
                <button class="btn btn-primary" onclick="quickCategoriesManager.loadQuickCategories()">
                    <i class="fas fa-refresh"></i> Retry
                </button>
            </div>
        `;
    }
};

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    if (typeof window !== 'undefined') {
        window.quickCategoriesManager = quickCategoriesManager;
    }
});

// Auto-initialize if admin sections are being shown
if (typeof showSection !== 'undefined') {
    const originalShowSection = showSection;
    showSection = function(section) {
        originalShowSection(section);
        if (section === 'quick-categories') {
            setTimeout(() => {
                quickCategoriesManager.init();
            }, 100);
        }
    };
}
