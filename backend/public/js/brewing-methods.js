/**
 * Brewing Methods Management JavaScript
 * Al Marya Rostery Admin Panel
 */

class BrewingMethodsManager {
    constructor() {
        this.currentBrewingMethod = null;
        this.brewingMethods = [];
        this.isLoading = false;
    }

    /**
     * Initialize the brewing methods manager
     */
    init() {
        console.log('🍵 Initializing Brewing Methods Manager...');
        this.loadBrewingMethods();
        this.loadStats();
    }

    /**
     * Load all brewing methods
     */
    async loadBrewingMethods() {
        if (this.isLoading) return;
        
        try {
            this.isLoading = true;
            this.showLoading();

            const response = await fetch(`${API_BASE_URL}/api/brewing-methods?limit=100`);
            const data = await response.json();
            
            if (data.success) {
                this.brewingMethods = data.data || [];
                this.renderBrewingMethodsTable();
                console.log(`✅ Loaded ${this.brewingMethods.length} brewing methods`);
            } else {
                throw new Error(data.message || 'Failed to load brewing methods');
            }
        } catch (error) {
            console.error('❌ Error loading brewing methods:', error);
            showErrorMessage('Failed to load brewing methods: ' + error.message);
            this.showError('Failed to load brewing methods: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Load brewing methods statistics
     */
    async loadStats() {
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/brewing-methods/admin/stats`);
            const data = await response.json();
            
            if (data.success) {
                this.updateStatsDisplay(data.data);
            }
        } catch (error) {
            console.error('❌ Error loading brewing methods stats:', error);
        }
    }

    /**
     * Update statistics display
     */
    updateStatsDisplay(stats) {
        const overview = stats.overview;
        
        document.getElementById('totalBrewingMethods').textContent = overview.total || 0;
        document.getElementById('activeBrewingMethods').textContent = overview.active || 0;
        document.getElementById('totalBrewingViews').textContent = overview.totalViews || 0;
        document.getElementById('avgBrewingRating').textContent = (overview.avgRating || 0).toFixed(1);
    }

    /**
     * Render brewing methods table
     */
    renderBrewingMethodsTable() {
        const tableContainer = document.getElementById('brewingMethodsTable');
        
        if (!this.brewingMethods || this.brewingMethods.length === 0) {
            tableContainer.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-flask"></i>
                    <h3>No Brewing Methods</h3>
                    <p>Start by creating your first brewing method guide.</p>
                    <button class="btn btn-primary" onclick="brewingMethodsManager.showAddModal()">
                        <i class="fas fa-plus"></i> Add Brewing Method
                    </button>
                </div>
            `;
            return;
        }

        const tableHTML = `
            <div class="table-responsive">
                <table class="table">
                    <thead>
                        <tr>
                            <th>Method</th>
                            <th>Difficulty</th>
                            <th>Time</th>
                            <th>Views</th>
                            <th>Rating</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${this.brewingMethods.map(method => this.renderBrewingMethodRow(method)).join('')}
                    </tbody>
                </table>
            </div>
        `;
        
        tableContainer.innerHTML = tableHTML;
    }

    /**
     * Render a single brewing method row
     */
    renderBrewingMethodRow(method) {
        const statusBadge = method.isActive 
            ? '<span class="badge badge-success">Active</span>'
            : '<span class="badge badge-secondary">Inactive</span>';
        
        const popularBadge = method.isPopular 
            ? '<span class="badge badge-warning">Popular</span>'
            : '';

        return `
            <tr>
                <td>
                    <div class="d-flex align-items-center">
                        ${method.image ? `<img src="${method.image}" alt="${method.name.en}" style="width: 40px; height: 40px; object-fit: cover; border-radius: 4px; margin-right: 10px;">` : ''}
                        <div>
                            <strong>${method.name.en}</strong>
                            <br>
                            <small class="text-muted">${method.name.ar}</small>
                            ${popularBadge}
                        </div>
                    </div>
                </td>
                <td>
                    <span class="badge badge-${this.getDifficultyColor(method.difficulty)}">
                        ${method.difficulty}
                    </span>
                </td>
                <td>${method.formattedTotalTime}</td>
                <td>${method.analytics.viewCount}</td>
                <td>
                    <span class="rating">
                        ${this.renderStars(method.analytics.avgRating)}
                        <small>(${method.analytics.totalRatings})</small>
                    </span>
                </td>
                <td>${statusBadge}</td>
                <td>
                    <div class="btn-group">
                        <button class="btn btn-sm btn-outline-primary" onclick="brewingMethodsManager.showEditModal('${method._id}')" title="Edit">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-${method.isActive ? 'warning' : 'success'}" 
                                onclick="brewingMethodsManager.toggleActive('${method._id}')" 
                                title="${method.isActive ? 'Deactivate' : 'Activate'}">
                            <i class="fas fa-${method.isActive ? 'eye-slash' : 'eye'}"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-danger" onclick="brewingMethodsManager.deleteBrewingMethod('${method._id}')" title="Delete">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }

    /**
     * Get color class for difficulty badge
     */
    getDifficultyColor(difficulty) {
        switch (difficulty) {
            case 'Beginner': return 'success';
            case 'Intermediate': return 'info';
            case 'Advanced': return 'warning';
            case 'Expert': return 'danger';
            default: return 'secondary';
        }
    }

    /**
     * Render star rating
     */
    renderStars(rating) {
        const fullStars = Math.floor(rating);
        const hasHalfStar = rating % 1 >= 0.5;
        const emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
        
        let starsHTML = '';
        
        // Full stars
        for (let i = 0; i < fullStars; i++) {
            starsHTML += '<i class="fas fa-star text-warning"></i>';
        }
        
        // Half star
        if (hasHalfStar) {
            starsHTML += '<i class="fas fa-star-half-alt text-warning"></i>';
        }
        
        // Empty stars
        for (let i = 0; i < emptyStars; i++) {
            starsHTML += '<i class="far fa-star text-muted"></i>';
        }
        
        return starsHTML;
    }

    /**
     * Show add brewing method modal
     */
    showAddModal() {
        this.currentBrewingMethod = null;
        this.resetForm();
        document.getElementById('brewingMethodModalTitle').textContent = '🍵 Create Brewing Method';
        document.getElementById('brewingMethodModal').style.display = 'block';
    }

    /**
     * Show edit brewing method modal
     */
    async showEditModal(methodId) {
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/brewing-methods/${methodId}`);
            const data = await response.json();
            
            if (data.success) {
                this.currentBrewingMethod = data.data;
                this.populateForm(data.data);
                document.getElementById('brewingMethodModalTitle').textContent = '🍵 Edit Brewing Method';
                document.getElementById('brewingMethodModal').style.display = 'block';
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('❌ Error loading brewing method:', error);
            this.showError('Failed to load brewing method: ' + error.message);
        }
    }

    /**
     * Close modal
     */
    closeModal() {
        document.getElementById('brewingMethodModal').style.display = 'none';
        this.resetForm();
        this.currentBrewingMethod = null;
    }

    /**
     * Reset form
     */
    resetForm() {
        document.getElementById('brewingMethodForm').reset();
        document.getElementById('brewingMethodId').value = '';
        document.getElementById('brewingMethodImagePreview').style.display = 'none';
        document.getElementById('currentImageContainer').style.display = 'none';
        document.getElementById('brewingMethodColor').value = '#A89A6A';
        document.getElementById('brewingMethodIsActive').checked = true;
        document.getElementById('brewingMethodIsPopular').checked = false;
        document.getElementById('brewingMethodServings').value = '1';
        document.getElementById('brewingMethodOrder').value = '0';
    }

    /**
     * Populate form with brewing method data
     */
    populateForm(method) {
        document.getElementById('brewingMethodId').value = method._id;
        document.getElementById('brewingMethodNameEn').value = method.name.en;
        document.getElementById('brewingMethodNameAr').value = method.name.ar;
        document.getElementById('brewingMethodDescEn').value = method.description.en;
        document.getElementById('brewingMethodDescAr').value = method.description.ar;
        document.getElementById('brewingMethodInstructionsEn').value = method.instructions.en;
        document.getElementById('brewingMethodInstructionsAr').value = method.instructions.ar;
        document.getElementById('brewingMethodGrindSize').value = method.parameters.grindSize;
        document.getElementById('brewingMethodRatio').value = method.parameters.coffeeToWaterRatio;
        document.getElementById('brewingMethodTempC').value = method.parameters.waterTemperature.celsius || '';
        document.getElementById('brewingMethodBrewTime').value = method.parameters.brewTime.minutes || '';
        document.getElementById('brewingMethodDifficulty').value = method.difficulty;
        document.getElementById('brewingMethodTotalTime').value = method.totalTime;
        document.getElementById('brewingMethodServings').value = method.servings;
        document.getElementById('brewingMethodOrder').value = method.displayOrder;
        document.getElementById('brewingMethodIcon').value = method.icon || '';
        document.getElementById('brewingMethodColor').value = method.color;
        document.getElementById('brewingMethodCategories').value = method.categories.join(', ');
        document.getElementById('brewingMethodTags').value = method.tags.join(', ');
        document.getElementById('brewingMethodIsActive').checked = method.isActive;
        document.getElementById('brewingMethodIsPopular').checked = method.isPopular;
        
        // Show current image if exists
        if (method.image) {
            document.getElementById('currentImage').src = method.image;
            document.getElementById('currentImageContainer').style.display = 'block';
        }
    }

    /**
     * Handle form submission
     */
    async handleSubmit(event) {
        event.preventDefault();
        
        if (this.isLoading) return;
        
        try {
            this.isLoading = true;
            
            const formData = new FormData();
            const methodId = document.getElementById('brewingMethodId').value;
            
            // Basic information
            formData.append('name.en', document.getElementById('brewingMethodNameEn').value);
            formData.append('name.ar', document.getElementById('brewingMethodNameAr').value);
            formData.append('description.en', document.getElementById('brewingMethodDescEn').value);
            formData.append('description.ar', document.getElementById('brewingMethodDescAr').value);
            formData.append('instructions.en', document.getElementById('brewingMethodInstructionsEn').value);
            formData.append('instructions.ar', document.getElementById('brewingMethodInstructionsAr').value);
            
            // Parameters
            formData.append('parameters.grindSize', document.getElementById('brewingMethodGrindSize').value);
            formData.append('parameters.coffeeToWaterRatio', document.getElementById('brewingMethodRatio').value);
            
            const tempC = document.getElementById('brewingMethodTempC').value;
            if (tempC) {
                formData.append('parameters.waterTemperature.celsius', tempC);
            }
            
            const brewTime = document.getElementById('brewingMethodBrewTime').value;
            if (brewTime) {
                formData.append('parameters.brewTime.minutes', brewTime);
            }
            
            // Details
            formData.append('difficulty', document.getElementById('brewingMethodDifficulty').value);
            formData.append('totalTime', document.getElementById('brewingMethodTotalTime').value);
            formData.append('servings', document.getElementById('brewingMethodServings').value);
            formData.append('displayOrder', document.getElementById('brewingMethodOrder').value);
            
            // Visual
            formData.append('icon', document.getElementById('brewingMethodIcon').value);
            formData.append('color', document.getElementById('brewingMethodColor').value);
            
            // Categories and tags
            formData.append('categories', document.getElementById('brewingMethodCategories').value);
            formData.append('tags', document.getElementById('brewingMethodTags').value);
            
            // Status
            formData.append('isActive', document.getElementById('brewingMethodIsActive').checked);
            formData.append('isPopular', document.getElementById('brewingMethodIsPopular').checked);
            
            // Image file
            const imageFile = document.getElementById('brewingMethodImage').files[0];
            if (imageFile) {
                formData.append('image', imageFile);
            }
            
            let url = `${API_BASE_URL}/api/brewing-methods`;
            let method = 'POST';
            
            if (methodId) {
                url += `/${methodId}`;
                method = 'PUT';
            }
            
            const response = await authenticatedFetch(url, {
                method: method,
                body: formData
            });
            
            const data = await response.json();
            
            if (data.success) {
                this.showSuccess(methodId ? 'Brewing method updated successfully!' : 'Brewing method created successfully!');
                this.closeModal();
                this.loadBrewingMethods();
                this.loadStats();
            } else {
                throw new Error(data.message || 'Failed to save brewing method');
            }
        } catch (error) {
            console.error('❌ Error saving brewing method:', error);
            this.showError('Failed to save brewing method: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Toggle brewing method active status
     */
    async toggleActive(methodId) {
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/brewing-methods/${methodId}/toggle-active`, {
                method: 'PATCH'
            });
            
            const data = await response.json();
            
            if (data.success) {
                this.showSuccess(data.message);
                this.loadBrewingMethods();
                this.loadStats();
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('❌ Error toggling brewing method status:', error);
            this.showError('Failed to update brewing method status: ' + error.message);
        }
    }

    /**
     * Delete brewing method
     */
    async deleteBrewingMethod(methodId) {
        const method = this.brewingMethods.find(m => m._id === methodId);
        const methodName = method ? method.name.en : 'this brewing method';
        
        if (!confirm(`Are you sure you want to delete "${methodName}"? This action cannot be undone.`)) {
            return;
        }
        
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/brewing-methods/${methodId}`, {
                method: 'DELETE'
            });
            
            const data = await response.json();
            
            if (data.success) {
                this.showSuccess('Brewing method deleted successfully!');
                this.loadBrewingMethods();
                this.loadStats();
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('❌ Error deleting brewing method:', error);
            this.showError('Failed to delete brewing method: ' + error.message);
        }
    }

    /**
     * Preview image before upload
     */
    previewImage(event) {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = function(e) {
                const preview = document.getElementById('brewingMethodImagePreview');
                preview.src = e.target.result;
                preview.style.display = 'block';
            };
            reader.readAsDataURL(file);
        }
    }

    /**
     * Show loading state
     */
    showLoading() {
        const tableContainer = document.getElementById('brewingMethodsTable');
        tableContainer.innerHTML = `
            <div class="loading-state">
                <i class="fas fa-spinner fa-spin"></i>
                <p>Loading brewing methods...</p>
            </div>
        `;
    }

    /**
     * Show success message
     */
    showSuccess(message) {
        // Create and show success notification
        const notification = document.createElement('div');
        notification.className = 'alert alert-success alert-dismissible';
        notification.innerHTML = `
            <i class="fas fa-check-circle"></i>
            ${message}
            <button type="button" class="close" onclick="this.parentElement.remove()">
                <span>&times;</span>
            </button>
        `;
        
        // Insert at top of page
        const container = document.querySelector('.main-content');
        container.insertBefore(notification, container.firstChild);
        
        // Auto remove after 5 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.remove();
            }
        }, 5000);
    }

    /**
     * Show error message
     */
    showError(message) {
        // Create and show error notification
        const notification = document.createElement('div');
        notification.className = 'alert alert-danger alert-dismissible';
        notification.innerHTML = `
            <i class="fas fa-exclamation-circle"></i>
            ${message}
            <button type="button" class="close" onclick="this.parentElement.remove()">
                <span>&times;</span>
            </button>
        `;
        
        // Insert at top of page
        const container = document.querySelector('.main-content');
        container.insertBefore(notification, container.firstChild);
        
        // Auto remove after 8 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.remove();
            }
        }, 8000);
    }
}

// Initialize brewing methods manager
const brewingMethodsManager = new BrewingMethodsManager();

// Auto-initialize when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    // Only initialize if we're on the brewing methods section
    if (window.location.hash.includes('brewing-methods') || 
        document.getElementById('brewingMethodsTable')) {
        brewingMethodsManager.init();
    }
});

// Export for global access
window.brewingMethodsManager = brewingMethodsManager;

// ============================================================================
// IMAGE DELETION FUNCTIONS
// ============================================================================

/**
 * Remove brewing method image from preview
 */
function removeBrewingMethodImage() {
    const preview = document.getElementById('brewingMethodImagePreview');
    const fileInput = document.getElementById('brewingMethodImage');
    
    if (preview) {
        preview.src = '';
        preview.style.display = 'none';
    }
    
    if (fileInput) {
        fileInput.value = '';
    }
    
    console.log('✅ Brewing method image removed from preview');
}
