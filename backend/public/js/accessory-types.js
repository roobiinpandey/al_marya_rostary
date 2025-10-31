// Accessory Types Management System
class AccessoryTypesManager {
    constructor() {
        this.types = [];
        this.currentType = null;
    }

    async init() {
        console.log('🏷️ Initializing Accessory Types Manager...');
        await this.loadTypes();
        this.setupEventListeners();
    }

    setupEventListeners() {
        // Add new type button
        const addBtn = document.getElementById('addAccessoryTypeBtn');
        if (addBtn) {
            addBtn.addEventListener('click', () => this.showAddModal());
        }

        // Seed default types button
        const seedBtn = document.getElementById('seedAccessoryTypesBtn');
        if (seedBtn) {
            seedBtn.addEventListener('click', () => this.seedDefaultTypes());
        }
    }

    async loadTypes() {
        try {
            showLoader('accessoryTypesTable');
            
            const response = await fetch('/api/accessory-types');
            const data = await response.json();

            if (data.success) {
                this.types = data.data || [];
                this.renderTypesTable();
            } else {
                throw new Error(data.message || 'Failed to load accessory types');
            }
        } catch (error) {
            console.error('Error loading accessory types:', error);
            showErrorMessage('Failed to load accessory types: ' + error.message);
            document.getElementById('accessoryTypesTable').innerHTML = 
                '<p class="error-message">Failed to load accessory types. Please try again.</p>';
        } finally {
            hideLoader('accessoryTypesTable');
        }
    }

    renderTypesTable() {
        const container = document.getElementById('accessoryTypesTable');
        
        if (!this.types || this.types.length === 0) {
            container.innerHTML = `
                <div class="no-data">
                    <p>No accessory types found.</p>
                    <button onclick="accessoryTypesManager.seedDefaultTypes()" class="btn btn-primary">
                        <i class="fas fa-seedling"></i> Seed Default Types
                    </button>
                </div>
            `;
            return;
        }

        const tableHTML = `
            <div class="table-responsive">
                <table class="admin-table">
                    <thead>
                        <tr>
                            <th>Order</th>
                            <th>Icon</th>
                            <th>Name</th>
                            <th>Slug</th>
                            <th>Description</th>
                            <th>Products</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${this.types.map(type => this.renderTypeRow(type)).join('')}
                    </tbody>
                </table>
            </div>
        `;

        container.innerHTML = tableHTML;
    }

    renderTypeRow(type) {
        const statusBadge = type.isActive ? 
            '<span class="badge badge-success">Active</span>' : 
            '<span class="badge badge-secondary">Inactive</span>';

        const mainPageBadge = type.showOnMainPage ? 
            '<span class="badge badge-info">On Main Page</span>' : '';

        return `
            <tr>
                <td>${type.displayOrder || 0}</td>
                <td>
                    <div class="type-icon" style="color: ${type.icon?.color || '#8C8C8C'}">
                        <i class="material-icons">${type.icon?.name || 'settings'}</i>
                    </div>
                </td>
                <td>
                    <div class="item-info">
                        <div class="item-name">${type.name?.en || 'N/A'}</div>
                        <div class="item-name-ar">${type.name?.ar || ''}</div>
                    </div>
                </td>
                <td><code>${type.slug}</code></td>
                <td class="description-cell">${type.description?.en || 'No description'}</td>
                <td>
                    <span class="product-count">${type.productCount || 0}</span>
                    <button class="btn btn-sm btn-link" onclick="accessoryTypesManager.updateProductCount('${type.slug}')" title="Update Count">
                        <i class="fas fa-sync-alt"></i>
                    </button>
                </td>
                <td>
                    <div class="status-badges">
                        ${statusBadge}
                        ${mainPageBadge}
                    </div>
                </td>
                <td>
                    <div class="action-buttons">
                        <button class="btn btn-sm btn-primary" onclick="accessoryTypesManager.viewType('${type.slug}')" title="View Details">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn btn-sm btn-secondary" onclick="accessoryTypesManager.editType('${type.slug}')" title="Edit">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-${type.isActive ? 'warning' : 'success'}" 
                                onclick="accessoryTypesManager.toggleType('${type.slug}')" 
                                title="${type.isActive ? 'Deactivate' : 'Activate'}">
                            <i class="fas fa-${type.isActive ? 'toggle-on' : 'toggle-off'}"></i>
                        </button>
                        <button class="btn btn-sm btn-danger" onclick="accessoryTypesManager.deleteType('${type.slug}')" title="Delete">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }

    showAddModal() {
        const modal = document.getElementById('accessoryTypeModal');
        const form = document.getElementById('accessoryTypeForm');
        
        document.getElementById('modalTitle').textContent = 'Add New Accessory Type';
        form.reset();
        this.currentType = null;
        
        // Show icon preview section
        this.updateIconPreview();
        
        modal.style.display = 'block';
    }

    async editType(slug) {
        const type = this.types.find(t => t.slug === slug);
        if (!type) return;

        this.currentType = type;
        
        const modal = document.getElementById('accessoryTypeModal');
        const form = document.getElementById('accessoryTypeForm');
        
        document.getElementById('modalTitle').textContent = 'Edit Accessory Type';
        
        // Populate form
        document.getElementById('typeSlug').value = type.slug;
        document.getElementById('typeSlug').disabled = true; // Cannot change slug
        document.getElementById('typeNameEn').value = type.name?.en || '';
        document.getElementById('typeNameAr').value = type.name?.ar || '';
        document.getElementById('typeDescEn').value = type.description?.en || '';
        document.getElementById('typeDescAr').value = type.description?.ar || '';
        document.getElementById('typeIcon').value = type.icon?.name || '';
        document.getElementById('typeIconColor').value = type.icon?.color || '#8C8C8C';
        document.getElementById('typeRoute').value = type.route || '';
        document.getElementById('typeDisplayOrder').value = type.displayOrder || 0;
        document.getElementById('typeShowOnMain').checked = type.showOnMainPage !== false;
        document.getElementById('typeIsActive').checked = type.isActive !== false;
        
        this.updateIconPreview();
        
        modal.style.display = 'block';
    }

    updateIconPreview() {
        const iconName = document.getElementById('typeIcon').value || 'settings';
        const iconColor = document.getElementById('typeIconColor').value || '#8C8C8C';
        
        const preview = document.getElementById('iconPreview');
        if (preview) {
            preview.innerHTML = `<i class="material-icons" style="font-size: 48px; color: ${iconColor}">${iconName}</i>`;
        }
    }

    async saveType() {
        const form = document.getElementById('accessoryTypeForm');
        
        const formData = {
            slug: document.getElementById('typeSlug').value.trim().toLowerCase(),
            name: {
                en: document.getElementById('typeNameEn').value.trim(),
                ar: document.getElementById('typeNameAr').value.trim()
            },
            description: {
                en: document.getElementById('typeDescEn').value.trim(),
                ar: document.getElementById('typeDescAr').value.trim()
            },
            icon: {
                name: document.getElementById('typeIcon').value.trim() || 'settings',
                color: document.getElementById('typeIconColor').value || '#8C8C8C'
            },
            route: document.getElementById('typeRoute').value.trim(),
            displayOrder: parseInt(document.getElementById('typeDisplayOrder').value) || 0,
            showOnMainPage: document.getElementById('typeShowOnMain').checked,
            isActive: document.getElementById('typeIsActive').checked
        };

        // Validation
        if (!formData.slug || !formData.name.en || !formData.name.ar) {
            showErrorMessage('Please fill in all required fields');
            return;
        }

        try {
            const url = this.currentType 
                ? `/api/accessory-types/${this.currentType.slug}`
                : '/api/accessory-types';
            
            const method = this.currentType ? 'PUT' : 'POST';

            const response = await fetch(url, {
                method,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });

            const data = await response.json();

            if (data.success) {
                showSuccessMessage(data.message || 'Accessory type saved successfully');
                this.closeModal();
                await this.loadTypes();
            } else {
                showErrorMessage(data.message || 'Failed to save accessory type');
            }
        } catch (error) {
            console.error('Error saving accessory type:', error);
            showErrorMessage('Error saving accessory type: ' + error.message);
        }
    }

    async deleteType(slug) {
        if (!confirm(`Are you sure you want to delete the accessory type "${slug}"?\n\nNote: This will only work if no accessories are using this type.`)) {
            return;
        }

        try {
            const response = await fetch(`/api/accessory-types/${slug}`, {
                method: 'DELETE'
            });

            const data = await response.json();

            if (data.success) {
                showSuccessMessage(data.message || 'Accessory type deleted successfully');
                await this.loadTypes();
            } else {
                showErrorMessage(data.message || 'Failed to delete accessory type');
            }
        } catch (error) {
            console.error('Error deleting accessory type:', error);
            showErrorMessage('Error deleting accessory type: ' + error.message);
        }
    }

    async toggleType(slug) {
        try {
            const response = await fetch(`/api/accessory-types/${slug}/toggle`, {
                method: 'PATCH'
            });

            const data = await response.json();

            if (data.success) {
                showSuccessMessage(data.message);
                await this.loadTypes();
            } else {
                showErrorMessage(data.message || 'Failed to toggle accessory type');
            }
        } catch (error) {
            console.error('Error toggling accessory type:', error);
            showErrorMessage('Error toggling accessory type: ' + error.message);
        }
    }

    async updateProductCount(slug) {
        try {
            const response = await fetch(`/api/accessory-types/${slug}/update-count`, {
                method: 'POST'
            });

            const data = await response.json();

            if (data.success) {
                showSuccessMessage(`Product count updated: ${data.productCount}`);
                await this.loadTypes();
            } else {
                showErrorMessage(data.message || 'Failed to update product count');
            }
        } catch (error) {
            console.error('Error updating product count:', error);
            showErrorMessage('Error updating product count: ' + error.message);
        }
    }

    async seedDefaultTypes() {
        if (!confirm('This will seed default accessory types (mug, grinder, filter, etc.). Continue?')) {
            return;
        }

        try {
            const response = await fetch('/api/accessory-types/seed', {
                method: 'POST'
            });

            const data = await response.json();

            if (data.success) {
                showSuccessMessage('Default accessory types seeded successfully');
                await this.loadTypes();
            } else {
                showErrorMessage(data.message || 'Failed to seed default types');
            }
        } catch (error) {
            console.error('Error seeding default types:', error);
            showErrorMessage('Error seeding default types: ' + error.message);
        }
    }

    viewType(slug) {
        const type = this.types.find(t => t.slug === slug);
        if (!type) return;

        const details = `
            <div class="type-details">
                <h3>${type.name?.en} (${type.name?.ar})</h3>
                <p><strong>Slug:</strong> ${type.slug}</p>
                <p><strong>Description (EN):</strong> ${type.description?.en || 'N/A'}</p>
                <p><strong>Description (AR):</strong> ${type.description?.ar || 'N/A'}</p>
                <p><strong>Icon:</strong> ${type.icon?.name} (${type.icon?.color})</p>
                <p><strong>Route:</strong> ${type.route || 'N/A'}</p>
                <p><strong>Display Order:</strong> ${type.displayOrder}</p>
                <p><strong>Product Count:</strong> ${type.productCount || 0}</p>
                <p><strong>Status:</strong> ${type.isActive ? 'Active' : 'Inactive'}</p>
                <p><strong>Show on Main Page:</strong> ${type.showOnMainPage ? 'Yes' : 'No'}</p>
            </div>
        `;

        showModal('Accessory Type Details', details);
    }

    closeModal() {
        const modal = document.getElementById('accessoryTypeModal');
        modal.style.display = 'none';
        document.getElementById('typeSlug').disabled = false;
    }
}

// Initialize manager
let accessoryTypesManager;

document.addEventListener('DOMContentLoaded', function() {
    if (document.getElementById('accessoryTypesTable')) {
        accessoryTypesManager = new AccessoryTypesManager();
        accessoryTypesManager.init();
    }
});
