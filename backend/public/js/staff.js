/**
 * Staff Management Module
 * Handles all staff-related operations in the admin panel
 */

const staffManager = {
    currentStaff: [],
    filteredStaff: [],

    /**
     * Initialize staff management
     */
    async init() {
        console.log('🔄 Initializing Staff Manager...');
        
        // Show loading indicator
        const container = document.getElementById('staffTableContainer');
        if (!container) {
            console.error('❌ staffTableContainer not found!');
            return;
        }
        
        container.innerHTML = `
            <div style="text-align: center; padding: 3rem;">
                <div class="spinner-border text-primary" role="status" style="width: 3rem; height: 3rem;">
                    <span class="sr-only">Loading...</span>
                </div>
                <p style="margin-top: 1rem; color: #6c757d;">Loading staff members...</p>
            </div>
        `;
        
        // Load staff list first, then compute stats from loaded data
        try {
            await this.loadStaffList();
            // Stats depend on currentStaff array, so load after
            await this.loadStaffStats();
            console.log('✅ Staff Manager initialized successfully');
        } catch (error) {
            console.error('❌ Error initializing staff manager:', error);
            this.showError('Failed to initialize staff manager: ' + error.message);
        }
    },

    /**
     * Load all staff members
     */
    async loadStaffList() {
        const startTime = performance.now();
        try {
            const token = localStorage.getItem('adminToken');
            if (!token) {
                throw new Error('No admin token found');
            }

            const fetchStart = performance.now();
            // Add cache-busting timestamp to prevent browser caching issues
            const timestamp = new Date().getTime();
            const response = await fetch(`/api/admin/staff?_=${timestamp}`, {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Cache-Control': 'no-cache'
                }
            });
            const fetchTime = performance.now() - fetchStart;
            console.log(`⏱️ Staff API fetch took: ${fetchTime.toFixed(2)}ms`);

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const parseStart = performance.now();
            const data = await response.json();
            const parseTime = performance.now() - parseStart;
            console.log(`⏱️ JSON parse took: ${parseTime.toFixed(2)}ms`);
            
            if (data.success) {
                this.currentStaff = data.staff || [];
                this.filteredStaff = [...this.currentStaff];
                
                const renderStart = performance.now();
                this.renderStaffTable();
                const renderTime = performance.now() - renderStart;
                console.log(`⏱️ Table render took: ${renderTime.toFixed(2)}ms`);
                
                const totalTime = performance.now() - startTime;
                console.log(`✅ Total staff load time: ${totalTime.toFixed(2)}ms for ${this.currentStaff.length} staff members`);
            } else {
                throw new Error(data.message || 'Failed to load staff');
            }
        } catch (error) {
            console.error('Error loading staff:', error);
            this.showError('Failed to load staff members: ' + error.message);
            document.getElementById('staffTableContainer').innerHTML = `
                <div style="text-align: center; padding: 2rem;">
                    <i class="fas fa-exclamation-triangle" style="font-size: 2rem; color: #dc3545;"></i>
                    <p style="margin-top: 1rem; color: #dc3545;">Failed to load staff members</p>
                    <button class="btn btn-primary" onclick="staffManager.loadStaffList()">
                        <i class="fas fa-redo"></i> Retry
                    </button>
                </div>
            `;
        }
    },

    /**
     * Load staff statistics
     */
    async loadStaffStats() {
        try {
            const stats = {
                total: this.currentStaff.length,
                active: this.currentStaff.filter(s => s.status === 'active').length,
                onBreak: this.currentStaff.filter(s => s.status === 'on_break').length,
                offDuty: this.currentStaff.filter(s => s.status === 'off_duty').length,
                baristas: this.currentStaff.filter(s => s.role === 'barista').length,
                managers: this.currentStaff.filter(s => s.role === 'manager').length,
                cashiers: this.currentStaff.filter(s => s.role === 'cashier').length
            };

            document.getElementById('staffStats').innerHTML = `
                <div class="stat-card" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
                    <div class="stat-icon"><i class="fas fa-users"></i></div>
                    <div class="stat-details">
                        <div class="stat-value">${stats.total}</div>
                        <div class="stat-label">Total Staff</div>
                    </div>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #28a745 0%, #20c997 100%);">
                    <div class="stat-icon"><i class="fas fa-check-circle"></i></div>
                    <div class="stat-details">
                        <div class="stat-value">${stats.active}</div>
                        <div class="stat-label">Active</div>
                    </div>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #ffc107 0%, #ff9800 100%);">
                    <div class="stat-icon"><i class="fas fa-coffee"></i></div>
                    <div class="stat-details">
                        <div class="stat-value">${stats.onBreak}</div>
                        <div class="stat-label">On Break</div>
                    </div>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #6c757d 0%, #495057 100%);">
                    <div class="stat-icon"><i class="fas fa-moon"></i></div>
                    <div class="stat-details">
                        <div class="stat-value">${stats.offDuty}</div>
                        <div class="stat-label">Off Duty</div>
                    </div>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #A89A6A 0%, #8B7E5A 100%);">
                    <div class="stat-icon"><i class="fas fa-mug-hot"></i></div>
                    <div class="stat-details">
                        <div class="stat-value">${stats.baristas}</div>
                        <div class="stat-label">Baristas</div>
                    </div>
                </div>
            `;
        } catch (error) {
            console.error('Error loading staff stats:', error);
        }
    },

    /**
     * Render staff table
     */
    renderStaffTable() {
        const container = document.getElementById('staffTableContainer');
        
        if (this.filteredStaff.length === 0) {
            container.innerHTML = `
                <div style="text-align: center; padding: 2rem;">
                    <i class="fas fa-user-slash" style="font-size: 2rem; color: #6c757d;"></i>
                    <p style="margin-top: 1rem; color: #6c757d;">No staff members found</p>
                </div>
            `;
            return;
        }

        const tableHTML = `
            <div class="table-responsive">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Employee ID</th>
                            <th>Name</th>
                            <th>Email</th>
                            <th>Phone</th>
                            <th>Role</th>
                            <th>Status</th>
                            <th>Shift</th>
                            <th>Last Login</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${this.filteredStaff.map(staff => this.renderStaffRow(staff)).join('')}
                    </tbody>
                </table>
            </div>
        `;

        container.innerHTML = tableHTML;
    },

    /**
     * Render single staff row
     */
    renderStaffRow(staff) {
        const statusColors = {
            active: '#28a745',
            on_break: '#ffc107',
            off_duty: '#6c757d',
            inactive: '#dc3545'
        };

        const roleIcons = {
            barista: 'fa-mug-hot',
            manager: 'fa-user-tie',
            cashier: 'fa-cash-register'
        };

        const statusColor = statusColors[staff.status] || '#6c757d';
        const roleIcon = roleIcons[staff.role] || 'fa-user';
        const lastLogin = staff.lastLoginAt ? new Date(staff.lastLoginAt).toLocaleDateString() : 'Never';
        const isPinLocked = staff.isPinLocked || (staff.pinLockedUntil && new Date(staff.pinLockedUntil) > new Date());

        return `
            <tr>
                <td><strong>${staff.employeeId}</strong></td>
                <td>
                    <div style="display: flex; align-items: center; gap: 0.5rem;">
                        ${staff.photo ? 
                            `<img src="${staff.photo}" alt="${staff.name}" style="width: 32px; height: 32px; border-radius: 50%; object-fit: cover;">` : 
                            `<div style="width: 32px; height: 32px; border-radius: 50%; background: #A89A6A; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold;">${staff.name.charAt(0)}</div>`
                        }
                        <span>${staff.name}</span>
                    </div>
                </td>
                <td>${staff.email}</td>
                <td>${staff.phone}</td>
                <td>
                    <span style="display: inline-flex; align-items: center; gap: 0.5rem;">
                        <i class="fas ${roleIcon}"></i>
                        ${staff.role.charAt(0).toUpperCase() + staff.role.slice(1)}
                    </span>
                </td>
                <td>
                    <span class="badge" style="background: ${statusColor};">
                        ${staff.status.replace('_', ' ').toUpperCase()}
                    </span>
                    ${isPinLocked ? '<span class="badge" style="background: #dc3545; margin-left: 0.5rem;">🔒 LOCKED</span>' : ''}
                    ${staff.requirePinChange ? '<span class="badge" style="background: #ffc107; color: #000; margin-left: 0.5rem;">⚠️ PIN CHANGE REQUIRED</span>' : ''}
                </td>
                <td>${staff.shiftStartTime} - ${staff.shiftEndTime}</td>
                <td>${lastLogin}</td>
                <td>
                    <div class="action-buttons">
                        <button class="btn-action btn-primary" onclick="staffManager.viewStaffDetails('${staff.id}')" title="View Details">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn-action btn-secondary" onclick="staffManager.showEditStaffModal('${staff.id}')" title="Edit">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn-action btn-warning" onclick="staffManager.showResetPinModal('${staff.id}')" title="Reset PIN">
                            <i class="fas fa-key"></i>
                        </button>
                        <button class="btn-action btn-info" onclick="staffManager.generateBadge('${staff.id}')" title="Generate Badge">
                            <i class="fas fa-id-badge"></i>
                        </button>
                        ${isPinLocked ? 
                            `<button class="btn-action btn-success" onclick="staffManager.unlockPin('${staff.id}')" title="Unlock PIN">
                                <i class="fas fa-unlock"></i>
                            </button>` : ''
                        }
                        <button class="btn-action btn-danger" onclick="staffManager.deleteStaff('${staff.id}')" title="Delete">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    },

    /**
     * Filter staff based on search and filters
     */
    filterStaff() {
        const roleFilter = document.getElementById('staffRoleFilter').value;
        const statusFilter = document.getElementById('staffStatusFilter').value;
        const searchText = document.getElementById('staffSearchInput').value.toLowerCase();

        this.filteredStaff = this.currentStaff.filter(staff => {
            const matchesRole = !roleFilter || staff.role === roleFilter;
            const matchesStatus = !statusFilter || staff.status === statusFilter;
            const matchesSearch = !searchText || 
                staff.name.toLowerCase().includes(searchText) ||
                staff.email.toLowerCase().includes(searchText) ||
                staff.employeeId.toLowerCase().includes(searchText) ||
                staff.phone.includes(searchText);

            return matchesRole && matchesStatus && matchesSearch;
        });

        this.renderStaffTable();
    },

    /**
     * Show add staff modal
     */
    showAddStaffModal() {
        const modalHTML = `
            <div class="modal-overlay" id="addStaffModal" onclick="staffManager.closeModal(event)">
                <div class="modal-content" style="max-width: 600px;" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h3><i class="fas fa-user-plus"></i> Add New Staff Member</h3>
                        <button class="close-btn" onclick="staffManager.closeModal()">&times;</button>
                    </div>
                    <div class="modal-body">
                        <form id="addStaffForm" onsubmit="staffManager.submitAddStaff(event)">
                            <div class="form-group">
                                <label>Name *</label>
                                <input type="text" name="name" class="form-control" required>
                            </div>

                            <div class="form-group">
                                <label>Email *</label>
                                <input type="email" name="email" class="form-control" required>
                            </div>

                            <div class="form-group">
                                <label>Phone *</label>
                                <input type="tel" name="phone" class="form-control" placeholder="+971..." required>
                            </div>

                            <div class="form-group">
                                <label>Role *</label>
                                <select name="role" class="form-control" required>
                                    <option value="">Select Role</option>
                                    <option value="barista">Barista</option>
                                    <option value="manager">Manager</option>
                                    <option value="cashier">Cashier</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <label>Default PIN (4 digits, optional - defaults to 1234)</label>
                                <input type="text" name="pin" class="form-control" pattern="[0-9]{4}" maxlength="4" placeholder="1234">
                                <small>Staff will be required to change this PIN on first login</small>
                            </div>

                            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                                <div class="form-group">
                                    <label>Shift Start Time</label>
                                    <input type="time" name="shiftStartTime" class="form-control" value="08:00">
                                </div>

                                <div class="form-group">
                                    <label>Shift End Time</label>
                                    <input type="time" name="shiftEndTime" class="form-control" value="16:00">
                                </div>
                            </div>

                            <div class="form-group">
                                <label>Photo URL (optional)</label>
                                <input type="url" name="photo" class="form-control" placeholder="https://...">
                            </div>

                            <div class="modal-actions">
                                <button type="button" class="btn btn-secondary" onclick="staffManager.closeModal()">Cancel</button>
                                <button type="submit" class="btn btn-primary">
                                    <i class="fas fa-user-plus"></i> Create Staff Member
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        `;

        document.body.insertAdjacentHTML('beforeend', modalHTML);
    },

    /**
     * Submit add staff form
     */
    async submitAddStaff(event) {
        event.preventDefault();
        
        const form = event.target;
        const formData = new FormData(form);
        const data = Object.fromEntries(formData.entries());

        // Remove empty optional fields
        if (!data.pin) delete data.pin;
        if (!data.photo) delete data.photo;

        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch('/api/admin/staff/create', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(data)
            });

            const result = await response.json();

            if (result.success) {
                this.showSuccess(`Staff member created successfully! Employee ID: ${result.staff.employeeId}, Default PIN: ${result.credentials.defaultPin}`);
                this.closeModal();
                await this.loadStaffList();
                await this.loadStaffStats();
            } else {
                throw new Error(result.message || 'Failed to create staff member');
            }
        } catch (error) {
            console.error('Error creating staff:', error);
            this.showError('Failed to create staff member: ' + error.message);
        }
    },

    /**
     * View staff details
     */
    async viewStaffDetails(staffId) {
        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch(`/api/admin/staff/${staffId}`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            const data = await response.json();

            if (data.success) {
                const staff = data.staff;
                const isPinLocked = staff.isPinLocked || (staff.pinLockedUntil && new Date(staff.pinLockedUntil) > new Date());

                const modalHTML = `
                    <div class="modal-overlay" id="viewStaffModal" onclick="staffManager.closeModal(event)">
                        <div class="modal-content" style="max-width: 700px;" onclick="event.stopPropagation()">
                            <div class="modal-header">
                                <h3><i class="fas fa-user"></i> Staff Details</h3>
                                <button class="close-btn" onclick="staffManager.closeModal()">&times;</button>
                            </div>
                            <div class="modal-body">
                                <div style="display: grid; grid-template-columns: 1fr 2fr; gap: 2rem;">
                                    <div style="text-align: center;">
                                        ${staff.photo ? 
                                            `<img src="${staff.photo}" alt="${staff.name}" style="width: 150px; height: 150px; border-radius: 50%; object-fit: cover; border: 4px solid #A89A6A;">` : 
                                            `<div style="width: 150px; height: 150px; border-radius: 50%; background: #A89A6A; display: flex; align-items: center; justify-content: center; color: white; font-size: 4rem; font-weight: bold; margin: 0 auto;">${staff.name.charAt(0)}</div>`
                                        }
                                        <h3 style="margin-top: 1rem;">${staff.name}</h3>
                                        <p style="color: #6c757d;">${staff.role.toUpperCase()}</p>
                                        <span class="badge" style="background: ${staff.status === 'active' ? '#28a745' : '#6c757d'};">
                                            ${staff.status.replace('_', ' ').toUpperCase()}
                                        </span>
                                    </div>
                                    <div>
                                        <h4 style="margin-bottom: 1rem; color: #A89A6A;">Personal Information</h4>
                                        <div style="display: grid; gap: 0.75rem;">
                                            <div><strong>Employee ID:</strong> ${staff.employeeId}</div>
                                            <div><strong>Email:</strong> ${staff.email}</div>
                                            <div><strong>Phone:</strong> ${staff.phone}</div>
                                            <div><strong>Hire Date:</strong> ${new Date(staff.hireDate).toLocaleDateString()}</div>
                                        </div>

                                        <h4 style="margin-top: 1.5rem; margin-bottom: 1rem; color: #A89A6A;">Work Schedule</h4>
                                        <div style="display: grid; gap: 0.75rem;">
                                            <div><strong>Shift:</strong> ${staff.shiftStartTime} - ${staff.shiftEndTime}</div>
                                            <div><strong>Last Login:</strong> ${staff.lastLoginAt ? new Date(staff.lastLoginAt).toLocaleString() : 'Never'}</div>
                                        </div>

                                        <h4 style="margin-top: 1.5rem; margin-bottom: 1rem; color: #A89A6A;">Authentication</h4>
                                        <div style="display: grid; gap: 0.75rem;">
                                            <div><strong>PIN:</strong> ${staff.hasPin ? '<span style="color: #28a745;">✓ Set</span>' : '<span style="color: #dc3545;">Not Set</span>'} ${staff.hasPin ? `<button class="btn btn-sm btn-info" onclick="staffManager.showPinInfo('${staff.id}')" style="margin-left: 8px;"><i class="fas fa-eye"></i> View</button>` : ''}</div>
                                            <div><strong>PIN Status:</strong> ${isPinLocked ? '<span style="color: #dc3545;">🔒 Locked (${staff.pinAttempts || 0}/3 attempts)</span>' : '<span style="color: #28a745;">✓ Active</span>'}</div>
                                            <div><strong>PIN Change Required:</strong> ${staff.requirePinChange ? '<span style="color: #ffc107;">Yes</span>' : '<span style="color: #28a745;">No</span>'}</div>
                                            <div><strong>QR Badge Expires:</strong> ${staff.qrBadgeExpiresAt ? new Date(staff.qrBadgeExpiresAt).toLocaleDateString() : 'Not generated'}</div>
                                        </div>

                                        <h4 style="margin-top: 1.5rem; margin-bottom: 1rem; color: #A89A6A;">Performance Stats</h4>
                                        <div style="display: grid; gap: 0.75rem;">
                                            <div><strong>Orders Processed:</strong> ${staff.stats?.totalOrdersProcessed || 0}</div>
                                            <div><strong>Orders Today:</strong> ${staff.stats?.ordersProcessedToday || 0}</div>
                                            <div><strong>Avg. Prep Time:</strong> ${staff.stats?.averagePreparationTime || 0} min</div>
                                        </div>
                                    </div>
                                </div>

                                <div style="margin-top: 2rem; display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap;">
                                    <button class="btn btn-secondary" onclick="staffManager.showEditStaffModal('${staff.id}')">
                                        <i class="fas fa-edit"></i> Edit
                                    </button>
                                    <button class="btn btn-warning" onclick="staffManager.showResetPinModal('${staff.id}')">
                                        <i class="fas fa-key"></i> Reset PIN
                                    </button>
                                    <button class="btn btn-info" onclick="staffManager.generateBadge('${staff.id}')">
                                        <i class="fas fa-id-badge"></i> Generate Badge
                                    </button>
                                    <button class="btn btn-primary" onclick="staffManager.viewLoginHistory('${staff.id}')">
                                        <i class="fas fa-history"></i> Login History
                                    </button>
                                    ${isPinLocked ? 
                                        `<button class="btn btn-success" onclick="staffManager.unlockPin('${staff.id}')">
                                            <i class="fas fa-unlock"></i> Unlock PIN
                                        </button>` : ''
                                    }
                                </div>
                            </div>
                        </div>
                    </div>
                `;

                document.body.insertAdjacentHTML('beforeend', modalHTML);
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('Error viewing staff details:', error);
            this.showError('Failed to load staff details: ' + error.message);
        }
    },

    /**
     * Show edit staff modal
     */
    async showEditStaffModal(staffId) {
        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch(`/api/admin/staff/${staffId}`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            const data = await response.json();

            if (!data.success) {
                throw new Error(data.message);
            }

            const staff = data.staff;

            const modalHTML = `
                <div class="modal-overlay" id="editStaffModal" onclick="staffManager.closeModal(event)">
                    <div class="modal-content" style="max-width: 600px;" onclick="event.stopPropagation()">
                        <div class="modal-header">
                            <h3><i class="fas fa-edit"></i> Edit Staff Member</h3>
                            <button class="close-btn" onclick="staffManager.closeModal()">&times;</button>
                        </div>
                        <div class="modal-body">
                            <form id="editStaffForm" onsubmit="staffManager.submitEditStaff(event, '${staff.id}')">
                                <div class="form-group">
                                    <label>Name *</label>
                                    <input type="text" name="name" class="form-control" value="${staff.name}" required>
                                </div>

                                <div class="form-group">
                                    <label>Email *</label>
                                    <input type="email" name="email" class="form-control" value="${staff.email}" required>
                                </div>

                                <div class="form-group">
                                    <label>Phone *</label>
                                    <input type="tel" name="phone" class="form-control" value="${staff.phone}" required>
                                </div>

                                <div class="form-group">
                                    <label>Role *</label>
                                    <select name="role" class="form-control" required>
                                        <option value="barista" ${staff.role === 'barista' ? 'selected' : ''}>Barista</option>
                                        <option value="manager" ${staff.role === 'manager' ? 'selected' : ''}>Manager</option>
                                        <option value="cashier" ${staff.role === 'cashier' ? 'selected' : ''}>Cashier</option>
                                    </select>
                                </div>

                                <div class="form-group">
                                    <label>Status *</label>
                                    <select name="status" class="form-control" required>
                                        <option value="active" ${staff.status === 'active' ? 'selected' : ''}>Active</option>
                                        <option value="on_break" ${staff.status === 'on_break' ? 'selected' : ''}>On Break</option>
                                        <option value="off_duty" ${staff.status === 'off_duty' ? 'selected' : ''}>Off Duty</option>
                                        <option value="inactive" ${staff.status === 'inactive' ? 'selected' : ''}>Inactive</option>
                                    </select>
                                </div>

                                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                                    <div class="form-group">
                                        <label>Shift Start Time</label>
                                        <input type="time" name="shiftStartTime" class="form-control" value="${staff.shiftStartTime}">
                                    </div>

                                    <div class="form-group">
                                        <label>Shift End Time</label>
                                        <input type="time" name="shiftEndTime" class="form-control" value="${staff.shiftEndTime}">
                                    </div>
                                </div>

                                <div class="form-group">
                                    <label>Photo URL (optional)</label>
                                    <input type="url" name="photo" class="form-control" value="${staff.photo || ''}" placeholder="https://...">
                                </div>

                                <div class="modal-actions">
                                    <button type="button" class="btn btn-secondary" onclick="staffManager.closeModal()">Cancel</button>
                                    <button type="submit" class="btn btn-primary">
                                        <i class="fas fa-save"></i> Update Staff Member
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            `;

            document.body.insertAdjacentHTML('beforeend', modalHTML);
        } catch (error) {
            console.error('Error loading staff for edit:', error);
            this.showError('Failed to load staff details: ' + error.message);
        }
    },

    /**
     * Submit edit staff form
     */
    async submitEditStaff(event, staffId) {
        event.preventDefault();
        
        const form = event.target;
        const formData = new FormData(form);
        const data = Object.fromEntries(formData.entries());

        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch(`/api/admin/staff/${staffId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(data)
            });

            const result = await response.json();

            if (result.success) {
                this.showSuccess('Staff member updated successfully!');
                this.closeModal();
                await this.loadStaffList();
                await this.loadStaffStats();
            } else {
                throw new Error(result.message || 'Failed to update staff member');
            }
        } catch (error) {
            console.error('Error updating staff:', error);
            this.showError('Failed to update staff member: ' + error.message);
        }
    },

    /**
     * Show reset PIN modal
     */
    showResetPinModal(staffId) {
        const modalHTML = `
            <div class="modal-overlay" id="resetPinModal" onclick="staffManager.closeModal(event)">
                <div class="modal-content" style="max-width: 400px;" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h3><i class="fas fa-key"></i> Reset Staff PIN</h3>
                        <button class="close-btn" onclick="staffManager.closeModal()">&times;</button>
                    </div>
                    <div class="modal-body">
                        <form id="resetPinForm" onsubmit="staffManager.submitResetPin(event, '${staffId}')">
                            <div class="form-group">
                                <label>New PIN (4 digits) *</label>
                                <input type="text" name="newPin" class="form-control" pattern="[0-9]{4}" maxlength="4" required placeholder="1234">
                            </div>

                            <div class="form-group">
                                <label>
                                    <input type="checkbox" name="requireChange" checked>
                                    Require PIN change on next login
                                </label>
                            </div>

                            <div class="modal-actions">
                                <button type="button" class="btn btn-secondary" onclick="staffManager.closeModal()">Cancel</button>
                                <button type="submit" class="btn btn-warning">
                                    <i class="fas fa-key"></i> Reset PIN
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        `;

        document.body.insertAdjacentHTML('beforeend', modalHTML);
    },

    /**
     * Submit reset PIN
     */
    async submitResetPin(event, staffId) {
        event.preventDefault();
        
        const form = event.target;
        const formData = new FormData(form);
        const data = {
            newPin: formData.get('newPin'),
            requireChange: formData.get('requireChange') === 'on'
        };

        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch(`/api/admin/staff/${staffId}/reset-pin`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(data)
            });

            const result = await response.json();

            if (result.success) {
                this.showSuccess(`PIN reset successfully! New PIN: ${result.newPin}`);
                this.closeModal();
                await this.loadStaffList();
            } else {
                throw new Error(result.message || 'Failed to reset PIN');
            }
        } catch (error) {
            console.error('Error resetting PIN:', error);
            this.showError('Failed to reset PIN: ' + error.message);
        }
    },

    /**
     * Unlock PIN
     */
    /**
     * Show PIN information (hashed value for security)
     */
    async showPinInfo(staffId) {
        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch(`/api/admin/staff/${staffId}`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            const data = await response.json();

            if (!data.success) {
                throw new Error(data.message);
            }

            const staff = data.staff;
            
            const modalHTML = `
                <div class="modal-overlay" id="pinInfoModal" onclick="staffManager.closeModal(event)">
                    <div class="modal-content" style="max-width: 500px;" onclick="event.stopPropagation()">
                        <div class="modal-header">
                            <h3><i class="fas fa-key"></i> PIN Information</h3>
                            <button class="close-btn" onclick="staffManager.closeModal()">&times;</button>
                        </div>
                        <div class="modal-body">
                            <div style="background: #f8f9fa; padding: 1.5rem; border-radius: 8px; margin-bottom: 1rem;">
                                <h4 style="margin-bottom: 1rem; color: #A89A6A;">Staff: ${staff.name}</h4>
                                <div style="display: grid; gap: 0.75rem;">
                                    <div><strong>Employee ID:</strong> ${staff.employeeId}</div>
                                    <div><strong>PIN Status:</strong> ${staff.hasPin ? '<span style="color: #28a745;">✓ Set</span>' : '<span style="color: #dc3545;">Not Set</span>'}</div>
                                    <div><strong>PIN Hash:</strong> <code style="font-size: 0.75rem; word-break: break-all;">${staff.pinHashedValue || 'N/A'}</code></div>
                                    <div><strong>Failed Attempts:</strong> ${staff.pinAttempts || 0}/3</div>
                                    ${staff.pinLockedUntil && new Date(staff.pinLockedUntil) > new Date() ? 
                                        `<div><strong>Locked Until:</strong> <span style="color: #dc3545;">${new Date(staff.pinLockedUntil).toLocaleString()}</span></div>` : 
                                        ''
                                    }
                                    <div><strong>Requires PIN Change:</strong> ${staff.requirePinChange ? '<span style="color: #ffc107;">Yes</span>' : '<span style="color: #28a745;">No</span>'}</div>
                                </div>
                            </div>
                            
                            <div style="background: #fff3cd; border: 1px solid #ffc107; padding: 1rem; border-radius: 8px;">
                                <p style="margin: 0; color: #856404; font-size: 0.875rem;">
                                    <i class="fas fa-info-circle"></i> <strong>Security Note:</strong> PINs are encrypted using BCrypt. The hash shown above cannot be reversed to reveal the original PIN. Staff must remember their PIN or request a reset.
                                </p>
                            </div>

                            <div style="margin-top: 1.5rem; display: flex; gap: 1rem; justify-content: center;">
                                <button class="btn btn-warning" onclick="staffManager.showResetPinModal('${staff.id}')">
                                    <i class="fas fa-key"></i> Reset PIN
                                </button>
                                ${staff.pinLockedUntil && new Date(staff.pinLockedUntil) > new Date() ?
                                    `<button class="btn btn-success" onclick="staffManager.unlockPin('${staff.id}')">
                                        <i class="fas fa-unlock"></i> Unlock PIN
                                    </button>` : ''
                                }
                            </div>
                        </div>
                    </div>
                </div>
            `;

            document.body.insertAdjacentHTML('beforeend', modalHTML);
        } catch (error) {
            console.error('Error viewing PIN info:', error);
            this.showError('Failed to load PIN information: ' + error.message);
        }
    },

    async unlockPin(staffId) {
        if (!confirm('Are you sure you want to unlock this staff member\'s PIN?')) {
            return;
        }

        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch(`/api/admin/staff/${staffId}/unlock-pin`, {
                method: 'PUT',
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            const result = await response.json();

            if (result.success) {
                this.showSuccess('PIN unlocked successfully!');
                this.closeModal();
                await this.loadStaffList();
            } else {
                throw new Error(result.message || 'Failed to unlock PIN');
            }
        } catch (error) {
            console.error('Error unlocking PIN:', error);
            this.showError('Failed to unlock PIN: ' + error.message);
        }
    },

    /**
     * Generate QR badge
     */
    async generateBadge(staffId) {
        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch(`/api/admin/staff/${staffId}/generate-badge`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            const result = await response.json();

            if (result.success) {
                // Download the badge PDF using fetch with authorization header
                const pdfResponse = await fetch(`/api/admin/staff/${staffId}/badge-pdf`, {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });

                if (!pdfResponse.ok) {
                    throw new Error('Failed to download badge PDF');
                }

                // Get the PDF as a blob and download it
                const blob = await pdfResponse.blob();
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `badge_${result.staff.employeeId}_${result.staff.name.replace(/\s+/g, '_')}.pdf`;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                window.URL.revokeObjectURL(url);

                this.showSuccess('Badge generated successfully! PDF is downloading...');
            } else {
                throw new Error(result.message || 'Failed to generate badge');
            }
        } catch (error) {
            console.error('Error generating badge:', error);
            this.showError('Failed to generate badge: ' + error.message);
        }
    },

    /**
     * View login history
     */
    async viewLoginHistory(staffId) {
        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch(`/api/admin/staff/${staffId}/login-history`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            const data = await response.json();

            if (!data.success) {
                throw new Error(data.message);
            }

            const modalHTML = `
                <div class="modal-overlay" id="loginHistoryModal" onclick="staffManager.closeModal(event)">
                    <div class="modal-content" style="max-width: 900px;" onclick="event.stopPropagation()">
                        <div class="modal-header">
                            <h3><i class="fas fa-history"></i> Login History - ${data.staff.name}</h3>
                            <button class="close-btn" onclick="staffManager.closeModal()">&times;</button>
                        </div>
                        <div class="modal-body">
                            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 1rem; margin-bottom: 2rem;">
                                <div class="stat-card" style="background: #667eea;">
                                    <div class="stat-value">${data.stats.totalLogins}</div>
                                    <div class="stat-label">Total Logins</div>
                                </div>
                                <div class="stat-card" style="background: #28a745;">
                                    <div class="stat-value">${data.stats.pinLogins}</div>
                                    <div class="stat-label">PIN Logins</div>
                                </div>
                                <div class="stat-card" style="background: #A89A6A;">
                                    <div class="stat-value">${data.stats.qrLogins}</div>
                                    <div class="stat-label">QR Logins</div>
                                </div>
                                <div class="stat-card" style="background: #dc3545;">
                                    <div class="stat-value">${data.stats.failedAttempts}</div>
                                    <div class="stat-label">Failed Attempts</div>
                                </div>
                            </div>

                            <div class="table-responsive">
                                <table class="data-table">
                                    <thead>
                                        <tr>
                                            <th>Date & Time</th>
                                            <th>Method</th>
                                            <th>Device</th>
                                            <th>IP Address</th>
                                            <th>Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        ${data.loginHistory.map(entry => `
                                            <tr>
                                                <td>${new Date(entry.timestamp).toLocaleString()}</td>
                                                <td>
                                                    <span class="badge" style="background: ${entry.method === 'pin' ? '#28a745' : '#A89A6A'};">
                                                        ${entry.method === 'pin' ? '🔑 PIN' : '📱 QR'}
                                                    </span>
                                                </td>
                                                <td>${entry.deviceInfo || 'Unknown'}</td>
                                                <td>${entry.ipAddress || 'Unknown'}</td>
                                                <td>
                                                    <span class="badge" style="background: ${entry.success ? '#28a745' : '#dc3545'};">
                                                        ${entry.success ? '✓ Success' : '✗ Failed'}
                                                    </span>
                                                </td>
                                            </tr>
                                        `).join('')}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            `;

            document.body.insertAdjacentHTML('beforeend', modalHTML);
        } catch (error) {
            console.error('Error loading login history:', error);
            this.showError('Failed to load login history: ' + error.message);
        }
    },

    /**
     * Delete staff
     */
    async deleteStaff(staffId) {
        const staff = this.currentStaff.find(s => s._id === staffId);
        
        if (!confirm(`Are you sure you want to delete ${staff?.name}? This action cannot be undone.`)) {
            return;
        }

        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch(`/api/admin/staff/${staffId}`, {
                method: 'DELETE',
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            const result = await response.json();

            if (result.success) {
                this.showSuccess('Staff member deleted successfully!');
                await this.loadStaffList();
                await this.loadStaffStats();
            } else {
                throw new Error(result.message || 'Failed to delete staff member');
            }
        } catch (error) {
            console.error('Error deleting staff:', error);
            this.showError('Failed to delete staff member: ' + error.message);
        }
    },

    /**
     * Refresh staff list
     */
    async refreshStaffList() {
        await this.loadStaffList();
        await this.loadStaffStats();
        this.showSuccess('Staff list refreshed!');
    },

    /**
     * Close modal
     */
    closeModal(event) {
        // Only close if clicking overlay or close button
        if (!event || event.target.classList.contains('modal-overlay') || event.target.classList.contains('close-btn') || event.target.closest('.close-btn')) {
            const modals = document.querySelectorAll('.modal-overlay');
            modals.forEach(modal => modal.remove());
        }
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
    },

    /**
     * Show bulk import modal
     */
    showBulkImportModal() {
        const modalHTML = `
            <div class="modal-overlay" id="bulkImportModal" onclick="staffManager.closeModal(event)">
                <div class="modal-content" style="max-width: 700px;" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h3><i class="fas fa-file-upload"></i> Bulk Import Staff</h3>
                        <button class="close-btn" onclick="staffManager.closeModal()">&times;</button>
                    </div>
                    <div class="modal-body">
                        <div class="alert alert-info">
                            <i class="fas fa-info-circle"></i>
                            <strong>Instructions:</strong>
                            <ul style="margin-top: 0.5rem; margin-bottom: 0;">
                                <li>Download the CSV template below</li>
                                <li>Fill in staff details (name, email, phone, role, shift times)</li>
                                <li>Valid roles: <code>barista</code>, <code>manager</code>, <code>cashier</code></li>
                                <li>Upload the completed CSV file</li>
                            </ul>
                        </div>

                        <div style="margin: 1.5rem 0;">
                            <button class="btn btn-secondary" onclick="staffManager.downloadTemplate()">
                                <i class="fas fa-download"></i> Download CSV Template
                            </button>
                        </div>

                        <form id="bulkImportForm" onsubmit="staffManager.uploadCSV(event)">
                            <div class="form-group">
                                <label>Upload CSV File *</label>
                                <input 
                                    type="file" 
                                    id="csvFileInput" 
                                    name="csvFile" 
                                    accept=".csv" 
                                    class="form-control" 
                                    required
                                >
                                <small class="form-text text-muted">
                                    Maximum file size: 5MB
                                </small>
                            </div>

                            <div id="importProgress" style="display: none;">
                                <div class="progress" style="height: 30px;">
                                    <div class="progress-bar progress-bar-striped progress-bar-animated" 
                                         role="progressbar" 
                                         style="width: 100%">
                                        Processing...
                                    </div>
                                </div>
                            </div>

                            <div style="display: flex; gap: 1rem; justify-content: flex-end; margin-top: 1.5rem;">
                                <button type="button" class="btn btn-secondary" onclick="staffManager.closeModal()">
                                    Cancel
                                </button>
                                <button type="submit" class="btn btn-primary">
                                    <i class="fas fa-upload"></i> Import Staff
                                </button>
                            </div>
                        </form>

                        <div id="importResults" style="margin-top: 1.5rem; display: none;"></div>
                    </div>
                </div>
            </div>
        `;

        document.body.insertAdjacentHTML('beforeend', modalHTML);
    },

    /**
     * Download CSV template
     */
    async downloadTemplate() {
        try {
            const token = localStorage.getItem('adminToken');
            const response = await fetch('/api/admin/staff/bulk-import/template', {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (!response.ok) {
                throw new Error('Failed to download template');
            }

            const blob = await response.blob();
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'staff_import_template.csv';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            window.URL.revokeObjectURL(url);

            this.showSuccess('Template downloaded successfully!');
        } catch (error) {
            console.error('Error downloading template:', error);
            this.showError('Failed to download template: ' + error.message);
        }
    },

    /**
     * Upload and process CSV file
     */
    async uploadCSV(event) {
        event.preventDefault();

        const fileInput = document.getElementById('csvFileInput');
        const file = fileInput.files[0];

        if (!file) {
            this.showError('Please select a CSV file');
            return;
        }

        // Show progress
        document.getElementById('importProgress').style.display = 'block';
        document.getElementById('importResults').style.display = 'none';

        try {
            const token = localStorage.getItem('adminToken');
            const formData = new FormData();
            formData.append('csvFile', file);

            const response = await fetch('/api/admin/staff/bulk-import', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`
                },
                body: formData
            });

            const data = await response.json();

            // Hide progress
            document.getElementById('importProgress').style.display = 'none';

            if (data.success) {
                this.showImportResults(data);
                // Reload staff list
                await this.loadStaffList();
                await this.loadStaffStats();
            } else {
                throw new Error(data.message || 'Import failed');
            }
        } catch (error) {
            console.error('Error uploading CSV:', error);
            document.getElementById('importProgress').style.display = 'none';
            this.showError('Failed to import staff: ' + error.message);
        }
    },

    /**
     * Show import results
     */
    showImportResults(data) {
        const resultsDiv = document.getElementById('importResults');
        const { summary, imported, skipped, errors } = data;

        let html = `
            <div class="alert alert-success">
                <h5><i class="fas fa-check-circle"></i> Import Complete!</h5>
                <div style="margin-top: 1rem;">
                    <strong>Summary:</strong>
                    <ul>
                        <li>Total rows: ${summary.total}</li>
                        <li>✅ Imported: ${summary.imported}</li>
                        <li>⚠️ Skipped: ${summary.skipped}</li>
                        <li>❌ Errors: ${summary.errors}</li>
                    </ul>
                </div>
            </div>
        `;

        if (imported.length > 0) {
            html += `
                <div style="margin-top: 1rem;">
                    <h6>✅ Successfully Imported (${imported.length})</h6>
                    <div class="table-responsive" style="max-height: 200px; overflow-y: auto;">
                        <table class="table table-sm">
                            <thead>
                                <tr>
                                    <th>Employee ID</th>
                                    <th>Name</th>
                                    <th>Email</th>
                                    <th>Role</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${imported.map(s => `
                                    <tr>
                                        <td>${s.employeeId}</td>
                                        <td>${s.name}</td>
                                        <td>${s.email}</td>
                                        <td>${s.role}</td>
                                    </tr>
                                `).join('')}
                            </tbody>
                        </table>
                    </div>
                </div>
            `;
        }

        if (skipped.length > 0) {
            html += `
                <div style="margin-top: 1rem;">
                    <h6>⚠️ Skipped (${skipped.length})</h6>
                    <div class="table-responsive" style="max-height: 150px; overflow-y: auto;">
                        <table class="table table-sm table-warning">
                            <thead>
                                <tr>
                                    <th>Row</th>
                                    <th>Email</th>
                                    <th>Reason</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${skipped.map(s => `
                                    <tr>
                                        <td>${s.row}</td>
                                        <td>${s.email}</td>
                                        <td>${s.reason}</td>
                                    </tr>
                                `).join('')}
                            </tbody>
                        </table>
                    </div>
                </div>
            `;
        }

        if (errors.length > 0) {
            html += `
                <div style="margin-top: 1rem;">
                    <h6>❌ Errors (${errors.length})</h6>
                    <div class="table-responsive" style="max-height: 150px; overflow-y: auto;">
                        <table class="table table-sm table-danger">
                            <thead>
                                <tr>
                                    <th>Row</th>
                                    <th>Data</th>
                                    <th>Error</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${errors.map(e => `
                                    <tr>
                                        <td>${e.row}</td>
                                        <td>${JSON.stringify(e.data)}</td>
                                        <td>${e.error}</td>
                                    </tr>
                                `).join('')}
                            </tbody>
                        </table>
                    </div>
                </div>
            `;
        }

        resultsDiv.innerHTML = html;
        resultsDiv.style.display = 'block';
    }
};

// Initialize when staff section is shown
if (typeof window !== 'undefined') {
    console.log('Staff manager loaded');
}
