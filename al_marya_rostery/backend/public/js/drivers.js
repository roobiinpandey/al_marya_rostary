/**
 * Driver Management Module
 * Handles all driver-related operations in the Admin Panel
 * Similar to Staff Management but for delivery drivers
 */

const driverManager = {
    currentDrivers: [],
    filteredDrivers: [],
    currentFilter: 'all', // all, available, on_delivery, offline, on_break, inactive

    /**
     * Initialize the driver management module
     */
    async init() {
        console.log('🚗 Initializing Driver Management Module...');
        
        // Load drivers and stats
        await this.loadDriverList();
        await this.loadDriverStats();
        
        // Set up event listeners
        this.setupEventListeners();
        
        console.log('✅ Driver Management Module Initialized');
    },

    /**
     * Set up all event listeners
     */
    setupEventListeners() {
        // Search functionality
        const searchInput = document.getElementById('driverSearch');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.filterDrivers(e.target.value);
            });
        }

        // Filter buttons
        const filterButtons = document.querySelectorAll('.driver-filter-btn');
        filterButtons.forEach(btn => {
            btn.addEventListener('click', (e) => {
                const filter = e.target.dataset.filter;
                this.setFilter(filter);
            });
        });

        // Add driver button
        const addDriverBtn = document.getElementById('addDriverBtn');
        if (addDriverBtn) {
            addDriverBtn.addEventListener('click', () => {
                this.showAddDriverModal();
            });
        }

        // Refresh button
        const refreshBtn = document.getElementById('refreshDriversBtn');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', async () => {
                await this.loadDriverList();
                await this.loadDriverStats();
            });
        }
    },

    /**
     * Load all drivers from the API
     */
    async loadDriverList() {
        try {
            console.log('📡 Loading drivers list...');
            const loadStart = performance.now();

            const token = localStorage.getItem('adminToken');
            if (!token) {
                throw new Error('No authentication token found');
            }

            // Add cache-busting timestamp
            const timestamp = new Date().getTime();
            const response = await fetch(`/api/admin/drivers?_=${timestamp}`, {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const result = await response.json();
            
            if (result.success) {
                // Backend returns { success: true, drivers: [...], count: N }
                // Normalize to ensure we have an array
                let driversArray = [];
                if (Array.isArray(result.drivers)) {
                    driversArray = result.drivers;
                } else if (Array.isArray(result.data)) {
                    driversArray = result.data;
                } else {
                    // fallback: empty list
                    driversArray = [];
                }

                this.currentDrivers = driversArray;
                this.filteredDrivers = [...this.currentDrivers];
                this.renderDriverTable();

                const loadTime = (performance.now() - loadStart).toFixed(2);
                console.log(`✅ Loaded ${this.currentDrivers.length} drivers in ${loadTime}ms`);
            } else {
                throw new Error(result.message || 'Failed to load drivers');
            }
        } catch (error) {
            console.error('❌ Error loading drivers:', error);
            this.showError('Error loading drivers: ' + error.message);
        }
    },

    /**
     * Load driver statistics
     */
    async loadDriverStats() {
        try {
            const token = localStorage.getItem('adminToken');
            if (!token) return;

            const response = await fetch('/api/admin/drivers/stats', {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const result = await response.json();
            
            if (result.success) {
                // Backend returns { success: true, stats: {...} }
                const statsObj = (result.stats && typeof result.stats === 'object') ? result.stats : {};
                this.updateStatsCards(statsObj);
                console.log('✅ Driver statistics loaded');
            }
        } catch (error) {
            console.error('❌ Error loading driver stats:', error);
        }
    },

    /**
     * Update statistics cards in the UI
     */
    updateStatsCards(stats) {
        // Defensive guard: if stats is missing or not an object, replace with empty object
        if (!stats || typeof stats !== 'object') {
            console.warn('Driver stats missing or invalid, using defaults');
            stats = {};
        }
        // Update total drivers
        const totalEl = document.getElementById('totalDriversCount');
        if (totalEl) totalEl.textContent = stats.totalDrivers || 0;

        // Update available drivers
        const availableEl = document.getElementById('availableDriversCount');
        if (availableEl) availableEl.textContent = stats.availableDrivers || 0;

        // Update on delivery drivers
        const onDeliveryEl = document.getElementById('onDeliveryDriversCount');
        if (onDeliveryEl) onDeliveryEl.textContent = stats.onDeliveryDrivers || 0;

        // Update offline drivers
        const offlineEl = document.getElementById('offlineDriversCount');
        if (offlineEl) offlineEl.textContent = stats.offlineDrivers || 0;

        // Update total deliveries
        const deliveriesEl = document.getElementById('totalDeliveriesCount');
        if (deliveriesEl) deliveriesEl.textContent = stats.totalDeliveries || 0;

        // Update total earnings
        const earningsEl = document.getElementById('totalEarningsCount');
        if (earningsEl) earningsEl.textContent = `${(stats.totalEarnings || 0).toFixed(2)} AED`;
    },

    /**
     * Render the driver table
     */
    renderDriverTable() {
        const tableBody = document.getElementById('driversTableBody');
        if (!tableBody) return;

        if (this.filteredDrivers.length === 0) {
            tableBody.innerHTML = `
                <tr>
                    <td colspan="8" style="padding: 4rem; text-align: center;">
                        <div style="display: flex; flex-direction: column; align-items: center; gap: 1rem;">
                            <i class="fas fa-search" style="font-size: 3rem; color: #d1d5db;"></i>
                            <div style="font-size: 1.25rem; font-weight: 600; color: #6b7280;">No Drivers Found</div>
                            <div style="color: #9ca3af; font-size: 0.95rem;">Try adjusting your search or filter criteria</div>
                        </div>
                    </td>
                </tr>
            `;
            return;
        }

        tableBody.innerHTML = this.filteredDrivers.map((driver, index) => `
            <tr style="border-bottom: 1px solid #e5e7eb; transition: all 0.2s; ${index % 2 === 0 ? 'background: #f9fafb;' : 'background: white;'}" 
                onmouseover="this.style.background='#f3f4f6'; this.style.transform='translateX(4px)'; this.style.boxShadow='0 2px 4px rgba(0,0,0,0.05)';" 
                onmouseout="this.style.background='${index % 2 === 0 ? '#f9fafb' : 'white'}'; this.style.transform='translateX(0)'; this.style.boxShadow='none';">
                <td style="padding: 1rem; vertical-align: middle;">
                    <div style="font-weight: 600; color: #667eea; font-size: 0.9rem;">${this.escapeHtml(driver.driverId)}</div>
                </td>
                <td style="padding: 1rem; vertical-align: middle;">
                    <div style="font-weight: 600; color: #1f2937; font-size: 0.95rem; margin-bottom: 0.25rem;">
                        <i class="fas fa-user-circle" style="color: #667eea; margin-right: 0.5rem;"></i>${this.escapeHtml(driver.name)}
                    </div>
                    <div style="color: #6b7280; font-size: 0.85rem;">
                        <i class="fas fa-envelope" style="margin-right: 0.5rem;"></i>${this.escapeHtml(driver.email)}
                    </div>
                </td>
                <td style="padding: 1rem; vertical-align: middle;">
                    <div style="color: #374151; font-size: 0.9rem;">
                        <i class="fas fa-phone-alt" style="color: #10b981; margin-right: 0.5rem;"></i>${this.escapeHtml(driver.phone || 'N/A')}
                    </div>
                </td>
                <td style="padding: 1rem; vertical-align: middle;">
                    ${this.renderStatusBadge(driver.status)}
                </td>
                <td style="padding: 1rem; vertical-align: middle;">
                    <div style="font-weight: 500; color: #374151; font-size: 0.9rem; margin-bottom: 0.25rem;">
                        <i class="fas fa-car" style="color: #667eea; margin-right: 0.5rem;"></i>${driver.vehicleInfo?.type || 'N/A'}
                    </div>
                    ${driver.vehicleInfo?.plateNumber ? `<div style="color: #6b7280; font-size: 0.85rem; margin-left: 1.5rem;">${driver.vehicleInfo.plateNumber}</div>` : ''}
                </td>
                <td style="padding: 1rem; vertical-align: middle; text-align: center;">
                    <div style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 0.5rem 1rem; border-radius: 20px; font-weight: 600; font-size: 0.9rem;">
                        ${driver.stats?.completedDeliveries || 0}
                    </div>
                </td>
                <td style="padding: 1rem; vertical-align: middle; text-align: center;">
                    ${this.renderActiveBadge(driver.isActive)}
                </td>
                <td style="padding: 1rem; vertical-align: middle;">
                    <div style="display: flex; gap: 0.5rem; justify-content: center; flex-wrap: wrap;">
                        <button onclick="driverManager.viewDriver('${driver._id}')" 
                                style="padding: 0.5rem; background: #667eea; color: white; border: none; border-radius: 6px; cursor: pointer; transition: all 0.2s; width: 36px; height: 36px; display: flex; align-items: center; justify-content: center;" 
                                onmouseover="this.style.background='#5568d3'; this.style.transform='scale(1.1)';" 
                                onmouseout="this.style.background='#667eea'; this.style.transform='scale(1)';"
                                title="View Details">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button onclick="driverManager.showEditDriverModal('${driver._id}')" 
                                style="padding: 0.5rem; background: #8b5cf6; color: white; border: none; border-radius: 6px; cursor: pointer; transition: all 0.2s; width: 36px; height: 36px; display: flex; align-items: center; justify-content: center;" 
                                onmouseover="this.style.background='#7c3aed'; this.style.transform='scale(1.1)';" 
                                onmouseout="this.style.background='#8b5cf6'; this.style.transform='scale(1)';"
                                title="Edit Driver">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button onclick="driverManager.showPinChangeModal('${driver._id}')" 
                                style="padding: 0.5rem; background: #a855f7; color: white; border: none; border-radius: 6px; cursor: pointer; transition: all 0.2s; width: 36px; height: 36px; display: flex; align-items: center; justify-content: center;" 
                                onmouseover="this.style.background='#9333ea'; this.style.transform='scale(1.1)';" 
                                onmouseout="this.style.background='#a855f7'; this.style.transform='scale(1)';"
                                title="Change PIN">
                            <i class="fas fa-key"></i>
                        </button>
                        <button onclick="driverManager.viewDeliveryHistory('${driver._id}')" 
                                style="padding: 0.5rem; background: #6b7280; color: white; border: none; border-radius: 6px; cursor: pointer; transition: all 0.2s; width: 36px; height: 36px; display: flex; align-items: center; justify-content: center;" 
                                onmouseover="this.style.background='#4b5563'; this.style.transform='scale(1.1)';" 
                                onmouseout="this.style.background='#6b7280'; this.style.transform='scale(1)';"
                                title="Delivery History">
                            <i class="fas fa-history"></i>
                        </button>
                        <button onclick="driverManager.deleteDriver('${driver._id}', '${this.escapeHtml(driver.name)}')" 
                                style="padding: 0.5rem; background: #ef4444; color: white; border: none; border-radius: 6px; cursor: pointer; transition: all 0.2s; width: 36px; height: 36px; display: flex; align-items: center; justify-content: center;" 
                                onmouseover="this.style.background='#dc2626'; this.style.transform='scale(1.1)';" 
                                onmouseout="this.style.background='#ef4444'; this.style.transform='scale(1)';"
                                title="Delete Driver">
                            <i class="fas fa-trash-alt"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `).join('');
    },

    /**
     * Render status badge
     */
    renderStatusBadge(status) {
        const statusConfig = {
            available: { 
                bg: '#10b981', 
                text: 'Available', 
                icon: 'check-circle' 
            },
            on_delivery: { 
                bg: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)', 
                text: 'On Delivery', 
                icon: 'shipping-fast' 
            },
            offline: { 
                bg: '#6b7280', 
                text: 'Offline', 
                icon: 'power-off' 
            },
            on_break: { 
                bg: 'linear-gradient(135deg, #818cf8 0%, #667eea 100%)', 
                text: 'On Break', 
                icon: 'coffee' 
            }
        };

        const config = statusConfig[status] || { 
            bg: '#6b7280', 
            text: 'Unknown', 
            icon: 'question-circle' 
        };

        return `
            <span style="display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.5rem 1rem; border-radius: 20px; background: ${config.bg}; color: white; font-weight: 600; font-size: 0.85rem; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                <i class="fas fa-${config.icon}"></i>
                ${config.text}
            </span>
        `;
    },

    /**
     * Render active/inactive badge
     */
    renderActiveBadge(isActive) {
        if (isActive) {
            return `
                <span style="display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.5rem 1rem; border-radius: 20px; background: #10b981; color: white; font-weight: 600; font-size: 0.85rem; box-shadow: 0 2px 4px rgba(16, 185, 129, 0.3);">
                    <i class="fas fa-check-circle"></i>
                    Active
                </span>
            `;
        } else {
            return `
                <span style="display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.5rem 1rem; border-radius: 20px; background: #ef4444; color: white; font-weight: 600; font-size: 0.85rem; box-shadow: 0 2px 4px rgba(239, 68, 68, 0.3);">
                    <i class="fas fa-times-circle"></i>
                    Inactive
                </span>
            `;
        }
    },

    /**
     * Filter drivers by status
     */
    setFilter(filter) {
        this.currentFilter = filter;

        // Update filter button states with visual feedback
        const filterButtons = document.querySelectorAll('.driver-filter-btn');
        filterButtons.forEach(btn => {
            if (btn.dataset.filter === filter) {
                btn.classList.add('active');
                // Apply active styling based on filter type
                const filterColors = {
                    all: '#667eea',
                    available: '#10b981',
                    on_delivery: '#f59e0b',
                    offline: '#6b7280',
                    on_break: '#3b82f6',
                    inactive: '#ef4444'
                };
                const color = filterColors[filter] || '#667eea';
                btn.style.background = color;
                btn.style.color = 'white';
                btn.style.borderColor = color;
                btn.style.transform = 'scale(1.05)';
                btn.style.boxShadow = `0 4px 6px ${color}40`;
            } else {
                btn.classList.remove('active');
                // Reset to outline styling
                const filterColors = {
                    all: '#667eea',
                    available: '#10b981',
                    on_delivery: '#f59e0b',
                    offline: '#6b7280',
                    on_break: '#3b82f6',
                    inactive: '#ef4444'
                };
                const color = filterColors[btn.dataset.filter] || '#667eea';
                btn.style.background = 'white';
                btn.style.color = color;
                btn.style.borderColor = color;
                btn.style.transform = 'scale(1)';
                btn.style.boxShadow = 'none';
            }
        });

        // Apply filter
        this.applyFilters();
    },

    /**
     * Filter drivers by search term
     */
    filterDrivers(searchTerm) {
        this.applyFilters(searchTerm);
    },

    /**
     * Apply all filters
     */
    applyFilters(searchTerm = '') {
        this.filteredDrivers = this.currentDrivers.filter(driver => {
            // Status filter
            if (this.currentFilter !== 'all') {
                if (this.currentFilter === 'inactive' && driver.isActive) {
                    return false;
                } else if (this.currentFilter !== 'inactive' && driver.status !== this.currentFilter) {
                    return false;
                }
            }

            // Search filter
            if (searchTerm) {
                const search = searchTerm.toLowerCase();
                const matchesName = driver.name.toLowerCase().includes(search);
                const matchesEmail = driver.email.toLowerCase().includes(search);
                const matchesPhone = driver.phone?.toLowerCase().includes(search);
                const matchesDriverId = driver.driverId.toLowerCase().includes(search);
                
                if (!matchesName && !matchesEmail && !matchesPhone && !matchesDriverId) {
                    return false;
                }
            }

            return true;
        });

        this.renderDriverTable();
    },

    /**
     * Show add driver modal
     */
    showAddDriverModal() {
        const modal = document.getElementById('addDriverModal');
        if (!modal) return;

        // Reset form
        document.getElementById('addDriverForm').reset();

        // Show modal
        modal.classList.remove('hidden');
    },

    /**
     * Hide add driver modal
     */
    hideAddDriverModal() {
        const modal = document.getElementById('addDriverModal');
        if (modal) {
            modal.classList.add('hidden');
        }
    },

    /**
     * Submit new driver
     */
    async submitAddDriver(event) {
        event.preventDefault();

        const formData = {
            name: document.getElementById('addDriverName').value,
            email: document.getElementById('addDriverEmail').value,
            phone: document.getElementById('addDriverPhone').value,
            pin: document.getElementById('addDriverPin').value,
            vehicleInfo: {
                type: document.getElementById('addDriverVehicleType').value,
                plateNumber: document.getElementById('addDriverPlateNumber').value,
                color: document.getElementById('addDriverVehicleColor').value
            }
        };

        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch('/api/admin/drivers', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(formData)
            });

            const result = await response.json();

            if (result.success) {
                this.showSuccess('Driver added successfully');
                this.hideAddDriverModal();
                await this.loadDriverList();
                await this.loadDriverStats();
            } else {
                throw new Error(result.message || 'Failed to add driver');
            }
        } catch (error) {
            console.error('❌ Error adding driver:', error);
            this.showError('Error adding driver: ' + error.message);
        }
    },

    /**
     * Show edit driver modal
     */
    async showEditDriverModal(driverId) {
        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch(`/api/admin/drivers/${driverId}`, {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            });

            const result = await response.json();

            if (result.success) {
                // Backend returns result.driver, not result.data
                const driver = result.driver || result.data;
                
                // Populate form
                document.getElementById('editDriverId').value = driver._id;
                document.getElementById('editDriverName').value = driver.name;
                document.getElementById('editDriverEmail').value = driver.email;
                document.getElementById('editDriverPhone').value = driver.phone || '';
                document.getElementById('editDriverVehicleType').value = driver.vehicleInfo?.type || '';
                document.getElementById('editDriverPlateNumber').value = driver.vehicleInfo?.plateNumber || '';
                document.getElementById('editDriverVehicleColor').value = driver.vehicleInfo?.color || '';
                document.getElementById('editDriverStatus').value = driver.status;

                // Show modal
                const modal = document.getElementById('editDriverModal');
                if (modal) {
                    modal.classList.remove('hidden');
                }
            } else {
                throw new Error(result.message || 'Failed to load driver details');
            }
        } catch (error) {
            console.error('❌ Error loading driver:', error);
            this.showError('Error loading driver: ' + error.message);
        }
    },

    /**
     * Hide edit driver modal
     */
    hideEditDriverModal() {
        const modal = document.getElementById('editDriverModal');
        if (modal) {
            modal.classList.add('hidden');
        }
    },

    /**
     * Submit edit driver
     */
    async submitEditDriver(event) {
        event.preventDefault();

        const driverId = document.getElementById('editDriverId').value;
        const formData = {
            name: document.getElementById('editDriverName').value,
            email: document.getElementById('editDriverEmail').value,
            phone: document.getElementById('editDriverPhone').value,
            vehicleInfo: {
                type: document.getElementById('editDriverVehicleType').value,
                plateNumber: document.getElementById('editDriverPlateNumber').value,
                color: document.getElementById('editDriverVehicleColor').value
            },
            status: document.getElementById('editDriverStatus').value
        };

        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch(`/api/admin/drivers/${driverId}`, {
                method: 'PUT',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(formData)
            });

            const result = await response.json();

            if (result.success) {
                this.showSuccess('Driver updated successfully');
                this.hideEditDriverModal();
                await this.loadDriverList();
                await this.loadDriverStats();
            } else {
                throw new Error(result.message || 'Failed to update driver');
            }
        } catch (error) {
            console.error('❌ Error updating driver:', error);
            this.showError('Error updating driver: ' + error.message);
        }
    },

    /**
     * Show PIN change modal
     */
    showPinChangeModal(driverId) {
        const driver = this.currentDrivers.find(d => d._id === driverId);
        if (!driver) return;

        document.getElementById('pinChangeDriverId').value = driverId;
        document.getElementById('pinChangeDriverName').textContent = driver.name;
        
        // Reset form
        document.getElementById('pinChangeForm').reset();

        // Show modal
        const modal = document.getElementById('pinChangeModal');
        if (modal) {
            modal.classList.remove('hidden');
        }
    },

    /**
     * Hide PIN change modal
     */
    hidePinChangeModal() {
        const modal = document.getElementById('pinChangeModal');
        if (modal) {
            modal.classList.add('hidden');
        }
    },

    /**
     * Submit PIN change
     */
    async submitPinChange(event) {
        event.preventDefault();

        const driverId = document.getElementById('pinChangeDriverId').value;
        const newPin = document.getElementById('newPin').value;
        const confirmPin = document.getElementById('confirmPin').value;

        if (newPin !== confirmPin) {
            this.showError('PINs do not match');
            return;
        }

        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch(`/api/admin/drivers/${driverId}/pin`, {
                method: 'PUT',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ pin: newPin })
            });

            const result = await response.json();

            if (result.success) {
                this.showSuccess('PIN updated successfully');
                this.hidePinChangeModal();
            } else {
                throw new Error(result.message || 'Failed to update PIN');
            }
        } catch (error) {
            console.error('❌ Error updating PIN:', error);
            this.showError('Error updating PIN: ' + error.message);
        }
    },

    /**
     * Toggle driver active status
     */
    async toggleDriverActive(driverId) {
        if (!confirm('Are you sure you want to change the driver status?')) {
            return;
        }

        try {
            const token = localStorage.getItem('adminToken');
            if (!token) {
                this.showError('No authentication token found');
                return;
            }

            const response = await fetch(`/api/admin/drivers/${driverId}/toggle-active`, {
                method: 'PATCH',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            });

            const result = await response.json();

            if (result.success) {
                await this.loadDriverList();
                await this.loadDriverStats();
            } else {
                throw new Error(result.message || 'Failed to toggle driver status');
            }
        } catch (error) {
            console.error('❌ Error toggling driver status:', error);
            this.showError('Error toggling driver status: ' + error.message);
        }
    },

    /**
     * View driver details
     */
    async viewDriver(driverId) {
        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch(`/api/admin/drivers/${driverId}`, {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            });

            const result = await response.json();

            if (result.success) {
                // Backend returns result.driver, not result.data
                const driver = result.driver || result.data;
                this.showDriverDetailsModal(driver);
            } else {
                throw new Error(result.message || 'Failed to load driver details');
            }
        } catch (error) {
            console.error('❌ Error loading driver details:', error);
            this.showError('Error loading driver details: ' + error.message);
        }
    },

    /**
     * Show driver details modal
     */
    showDriverDetailsModal(driver) {
        const modalContent = `
            <div class="space-y-4">
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700">Driver ID</label>
                        <p class="mt-1 text-sm text-gray-900">${this.escapeHtml(driver.driverId)}</p>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700">Name</label>
                        <p class="mt-1 text-sm text-gray-900">${this.escapeHtml(driver.name)}</p>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700">Email</label>
                        <p class="mt-1 text-sm text-gray-900">${this.escapeHtml(driver.email)}</p>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700">Phone</label>
                        <p class="mt-1 text-sm text-gray-900">${this.escapeHtml(driver.phone || 'N/A')}</p>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700">Status</label>
                        <p class="mt-1">${this.renderStatusBadge(driver.status)}</p>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700">Active Status</label>
                        <p class="mt-1">${this.renderActiveBadge(driver.isActive)}</p>
                    </div>
                </div>

                <div class="border-t pt-4">
                    <h4 class="text-lg font-medium text-gray-900 mb-3">Vehicle Information</h4>
                    <div class="grid grid-cols-3 gap-4">
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Type</label>
                            <p class="mt-1 text-sm text-gray-900">${this.escapeHtml(driver.vehicleInfo?.type || 'N/A')}</p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Plate Number</label>
                            <p class="mt-1 text-sm text-gray-900">${this.escapeHtml(driver.vehicleInfo?.plateNumber || 'N/A')}</p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Color</label>
                            <p class="mt-1 text-sm text-gray-900">${this.escapeHtml(driver.vehicleInfo?.color || 'N/A')}</p>
                        </div>
                    </div>
                </div>

                <div class="border-t pt-4">
                    <h4 class="text-lg font-medium text-gray-900 mb-3">Statistics</h4>
                    <div class="grid grid-cols-4 gap-4">
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Total Deliveries</label>
                            <p class="mt-1 text-sm text-gray-900">${driver.stats?.totalDeliveries || 0}</p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Completed</label>
                            <p class="mt-1 text-sm text-green-600 font-semibold">${driver.stats?.completedDeliveries || 0}</p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Cancelled</label>
                            <p class="mt-1 text-sm text-red-600 font-semibold">${driver.stats?.cancelledDeliveries || 0}</p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Total Earnings</label>
                            <p class="mt-1 text-sm text-blue-600 font-semibold">$${(driver.stats?.totalEarnings || 0).toFixed(2)}</p>
                        </div>
                    </div>
                </div>

                ${driver.location ? `
                <div class="border-t pt-4">
                    <h4 class="text-lg font-medium text-gray-900 mb-3">Location</h4>
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Latitude</label>
                            <p class="mt-1 text-sm text-gray-900">${driver.location.latitude?.toFixed(6) || 'N/A'}</p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Longitude</label>
                            <p class="mt-1 text-sm text-gray-900">${driver.location.longitude?.toFixed(6) || 'N/A'}</p>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700">Last Updated</label>
                            <p class="mt-1 text-sm text-gray-900">${driver.location.lastUpdated ? new Date(driver.location.lastUpdated).toLocaleString() : 'N/A'}</p>
                        </div>
                    </div>
                </div>
                ` : ''}

                <div class="border-t pt-4">
                    <div class="grid grid-cols-2 gap-4 text-sm text-gray-500">
                        <div>
                            <label class="block font-medium">Created At</label>
                            <p>${new Date(driver.createdAt).toLocaleString()}</p>
                        </div>
                        <div>
                            <label class="block font-medium">Last Updated</label>
                            <p>${new Date(driver.updatedAt).toLocaleString()}</p>
                        </div>
                    </div>
                </div>
            </div>
        `;

        document.getElementById('driverDetailsContent').innerHTML = modalContent;
        
        const modal = document.getElementById('driverDetailsModal');
        if (modal) {
            modal.classList.remove('hidden');
        }
    },

    /**
     * Hide driver details modal
     */
    hideDriverDetailsModal() {
        const modal = document.getElementById('driverDetailsModal');
        if (modal) {
            modal.classList.add('hidden');
        }
    },

    /**
     * View delivery history
     */
    async viewDeliveryHistory(driverId) {
        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch(`/api/admin/drivers/${driverId}/deliveries`, {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            });

            const result = await response.json();

            if (result.success) {
                // Backend returns result.deliveries, not result.data
                const deliveries = result.deliveries || result.data || [];
                this.showDeliveryHistoryModal(deliveries);
            } else {
                throw new Error(result.message || 'Failed to load delivery history');
            }
        } catch (error) {
            console.error('❌ Error loading delivery history:', error);
            this.showError('Error loading delivery history: ' + error.message);
        }
    },

    /**
     * Show delivery history modal
     */
    showDeliveryHistoryModal(deliveries) {
        const tableRows = deliveries.length > 0 ? deliveries.map(order => `
            <tr class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">${this.escapeHtml(order.orderNumber || order._id)}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">${new Date(order.createdAt).toLocaleDateString()}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">$${order.total.toFixed(2)}</td>
                <td class="px-6 py-4 whitespace-nowrap">
                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full 
                        ${order.status === 'delivered' ? 'bg-green-100 text-green-800' : 
                          order.status === 'cancelled' ? 'bg-red-100 text-red-800' : 
                          'bg-yellow-100 text-yellow-800'}">
                        ${order.status}
                    </span>
                </td>
                <td class="px-6 py-4 text-sm text-gray-900">${this.escapeHtml(order.deliveryAddress?.street || 'N/A')}</td>
            </tr>
        `).join('') : `
            <tr>
                <td colspan="5" class="px-6 py-4 text-center text-gray-500">No delivery history found</td>
            </tr>
        `;

        const modalContent = `
            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                        <tr>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Order #</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Address</th>
                        </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                        ${tableRows}
                    </tbody>
                </table>
            </div>
        `;

        document.getElementById('deliveryHistoryContent').innerHTML = modalContent;
        
        const modal = document.getElementById('deliveryHistoryModal');
        if (modal) {
            modal.classList.remove('hidden');
        }
    },

    /**
     * Hide delivery history modal
     */
    hideDeliveryHistoryModal() {
        const modal = document.getElementById('deliveryHistoryModal');
        if (modal) {
            modal.classList.add('hidden');
        }
    },

    /**
     * Delete driver
     */
    async deleteDriver(driverId, driverName) {
        if (!confirm(`Are you sure you want to delete driver "${driverName}"? This action cannot be undone.`)) {
            return;
        }

        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch(`/api/admin/drivers/${driverId}`, {
                method: 'DELETE',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            });

            const result = await response.json();

            if (result.success) {
                this.showSuccess('Driver deleted successfully');
                await this.loadDriverList();
                await this.loadDriverStats();
            } else {
                throw new Error(result.message || 'Failed to delete driver');
            }
        } catch (error) {
            console.error('❌ Error deleting driver:', error);
            this.showError('Error deleting driver: ' + error.message);
        }
    },

    /**
     * Escape HTML to prevent XSS
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    },

    /**
     * Show success message
     */
    showSuccess(message) {
        alert('✅ ' + message);
    },

    /**
     * Show error message
     */
    showError(message) {
        alert('❌ ' + message);
    }
};

// Make driverManager globally accessible
window.driverManager = driverManager;
