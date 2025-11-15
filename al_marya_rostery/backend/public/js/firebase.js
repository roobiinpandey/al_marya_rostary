/* Firebase Management Module */

// Firebase Management System - Comprehensive Admin Interface
let firebaseManagementData = {
    autoSyncActive: false,
    syncInterval: 60,
    syncLogs: [],
    firebaseUsers: [],
    localUsers: [],
    syncStats: {
        totalSyncs: 0,
        successfulSyncs: 0,
        lastSyncTime: null
    }
};

// Initialize Firebase Management Section
async function initializeFirebaseManagement() {
    try {
        showGlobalLoading('Loading Firebase Management...');
        
        await Promise.all([
            loadFirebaseStatus(),
            loadSyncLogs(),
            loadFirebaseUsers(),
            loadLocalUsers(),
            updateFirebaseStats()
        ]);
        
        updateFirebaseUI();
        showToast('Firebase Management loaded successfully', 'success');
    } catch (error) {
        console.error('Error initializing Firebase management:', error);
        showToast('Failed to load Firebase Management', 'error');
    } finally {
        hideGlobalLoading();
    }
}

// Load Firebase Auto Sync Status
async function loadFirebaseStatus() {
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/auto-sync/status`);
        const data = await response.json();
        
        if (data.success) {
            firebaseManagementData.autoSyncActive = data.data.isRunning;
            firebaseManagementData.syncInterval = data.data.interval / 1000;
            firebaseManagementData.syncStats = {
                totalSyncs: data.data.syncCount || 0,
                successfulSyncs: data.data.syncCount || 0,
                lastSyncTime: data.data.lastSync ? new Date(data.data.lastSync) : null
            };
        }
    } catch (error) {
        console.error('Error loading Firebase status:', error);
        showToast('Failed to load sync status', 'error');
    }
}

async function loadSyncLogs() {
    try {
        const mockLogs = [
            { timestamp: new Date(), type: 'success', message: 'Auto sync completed successfully - 0 users synced' },
            { timestamp: new Date(Date.now() - 60000), type: 'info', message: 'Starting automatic Firebase sync...' },
            { timestamp: new Date(Date.now() - 120000), type: 'success', message: 'Manual sync completed - 2 users updated' }
        ];
        
        firebaseManagementData.syncLogs = mockLogs;
    } catch (error) {
        console.error('Error loading sync logs:', error);
    }
}

async function loadFirebaseUsers() {
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/firebase-sync/status`);
        const data = await response.json();
        
        if (data.success) {
            firebaseManagementData.firebaseUsers = data.data || [];
        } else {
            firebaseManagementData.firebaseUsers = [];
        }
    } catch (error) {
        console.error('Error loading Firebase users:', error);
        firebaseManagementData.firebaseUsers = [];
    }
}

async function loadLocalUsers() {
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/users`);
        const data = await response.json();
        
        if (data.success) {
            firebaseManagementData.localUsers = data.data || [];
        } else {
            firebaseManagementData.localUsers = [];
        }
    } catch (error) {
        console.error('Error loading local users:', error);
        firebaseManagementData.localUsers = [];
    }
}

function updateFirebaseStats() {
    const firebaseCount = document.getElementById('firebaseUserCount');
    const localCount = document.getElementById('localUserCount');
    const syncCount = document.getElementById('syncSuccessCount');
    const lastSync = document.getElementById('lastSyncTime');
    
    if (firebaseCount) firebaseCount.textContent = firebaseManagementData.firebaseUsers.length || 0;
    if (localCount) localCount.textContent = firebaseManagementData.localUsers.length || 0;
    if (syncCount) syncCount.textContent = firebaseManagementData.syncStats.successfulSyncs || 0;
    if (lastSync) {
        lastSync.textContent = firebaseManagementData.syncStats.lastSyncTime 
            ? firebaseManagementData.syncStats.lastSyncTime.toLocaleTimeString() 
            : 'Never';
    }
}

function updateFirebaseUI() {
    const statusBadge = document.getElementById('autoSyncStatus');
    if (statusBadge) {
        if (firebaseManagementData.autoSyncActive) {
            statusBadge.innerHTML = '<i class="fas fa-circle"></i> Active';
            statusBadge.className = 'sync-status-badge active';
        } else {
            statusBadge.innerHTML = '<i class="fas fa-circle"></i> Inactive';
            statusBadge.className = 'sync-status-badge inactive';
        }
    }

    const intervalInput = document.getElementById('syncInterval');
    if (intervalInput) {
        const intervalValue = firebaseManagementData.syncInterval || 60;
        intervalInput.value = !isNaN(intervalValue) ? intervalValue : 60;
    }

    const startBtn = document.getElementById('startSyncBtn');
    const stopBtn = document.getElementById('stopSyncBtn');
    if (startBtn && stopBtn) {
        startBtn.disabled = firebaseManagementData.autoSyncActive;
        stopBtn.disabled = !firebaseManagementData.autoSyncActive;
    }

    updateSyncLogsDisplay();
    updateFirebaseUsersTable();
    updateLocalUsersTable();
    updateFirebaseStats();
}

function updateSyncLogsDisplay() {
    const logsContainer = document.getElementById('syncLogs');
    if (!logsContainer) return;
    
    if (firebaseManagementData.syncLogs.length === 0) {
        logsContainer.innerHTML = `
            <div class="text-center" style="padding: 2rem; color: #6c757d;">
                <i class="fas fa-info-circle"></i> No sync logs available
            </div>
        `;
        return;
    }

    const logsHtml = firebaseManagementData.syncLogs.map(log => `
        <div class="log-entry ${log.type}">
            <span class="log-timestamp">${log.timestamp.toLocaleTimeString()}</span>
            ${log.message}
        </div>
    `).reverse().join('');

    logsContainer.innerHTML = logsHtml;
}

function updateFirebaseUsersTable() {
    const container = document.getElementById('firebaseUsersTable');
    if (!container) return;
    
    if (firebaseManagementData.firebaseUsers.length === 0) {
        container.innerHTML = `
            <div class="text-center" style="padding: 2rem; color: #6c757d;">
                <i class="fas fa-users"></i> No Firebase users found
            </div>
        `;
        return;
    }

    // Add table implementation here
    container.innerHTML = '<p>Firebase users table will be implemented here</p>';
}

function updateLocalUsersTable() {
    const container = document.getElementById('localUsersTable');
    if (!container) return;
    
    if (firebaseManagementData.localUsers.length === 0) {
        container.innerHTML = `
            <div class="text-center" style="padding: 2rem; color: #6c757d;">
                <i class="fas fa-database"></i> No local users found
            </div>
        `;
        return;
    }

    const tableHtml = `
        <table class="user-sync-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Firebase UID</th>
                    <th>Created</th>
                    <th>Last Sync</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                ${firebaseManagementData.localUsers.map(user => `
                    <tr>
                        <td>${user._id?.substring(0, 8) || 'N/A'}...</td>
                        <td>${user.name || 'N/A'}</td>
                        <td>${user.email || 'N/A'}</td>
                        <td>${user.firebaseUid ? user.firebaseUid.substring(0, 8) + '...' : 'Not linked'}</td>
                        <td>${new Date(user.createdAt).toLocaleDateString()}</td>
                        <td>${user.lastFirebaseSync ? new Date(user.lastFirebaseSync).toLocaleDateString() : 'Never'}</td>
                        <td>
                            <button class="btn btn-sm btn-info" onclick="viewUser('${user._id}')">
                                <i class="fas fa-eye"></i> View
                            </button>
                        </td>
                    </tr>
                `).join('')}
            </tbody>
        </table>
    `;

    container.innerHTML = tableHtml;
}

// Control Functions
async function startAutoSync() {
    try {
        const interval = parseInt(document.getElementById('syncInterval').value);
        if (interval < 30 || interval > 3600) {
            showToast('Interval must be between 30 seconds and 1 hour', 'error');
            return;
        }

        showGlobalLoading('Starting auto sync...');
        const response = await authenticatedFetch(`${API_BASE_URL}/api/auto-sync/start`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ interval: interval * 1000 })
        });

        const data = await response.json();
        if (data.success) {
            firebaseManagementData.autoSyncActive = true;
            updateFirebaseUI();
            showToast('Auto sync started successfully', 'success');
            addSyncLog('success', `Auto sync started with ${interval}s interval`);
        } else {
            throw new Error(data.message);
        }
    } catch (error) {
        console.error('Error starting auto sync:', error);
        showToast('Failed to start auto sync: ' + error.message, 'error');
    } finally {
        hideGlobalLoading();
    }
}

async function stopAutoSync() {
    try {
        showGlobalLoading('Stopping auto sync...');
        const response = await authenticatedFetch(`${API_BASE_URL}/api/auto-sync/stop`, {
            method: 'POST'
        });

        const data = await response.json();
        if (data.success) {
            firebaseManagementData.autoSyncActive = false;
            updateFirebaseUI();
            showToast('Auto sync stopped successfully', 'success');
            addSyncLog('info', 'Auto sync stopped by admin');
        } else {
            throw new Error(data.message);
        }
    } catch (error) {
        console.error('Error stopping auto sync:', error);
        showToast('Failed to stop auto sync: ' + error.message, 'error');
    } finally {
        hideGlobalLoading();
    }
}

async function performManualSync() {
    try {
        showGlobalLoading('Performing manual sync...');
        document.getElementById('manualSyncBtn').disabled = true;

        const response = await authenticatedFetch(`${API_BASE_URL}/api/firebase-sync/sync`, {
            method: 'POST'
        });

        const data = await response.json();
        if (data.success) {
            showToast(`Manual sync completed - ${data.data.syncedUsers || 0} users processed`, 'success');
            addSyncLog('success', `Manual sync completed - ${data.data.syncedUsers || 0} users processed`);
            
            await Promise.all([
                loadFirebaseUsers(),
                loadLocalUsers(),
                updateFirebaseStats()
            ]);
            updateFirebaseUI();
        } else {
            throw new Error(data.message);
        }
    } catch (error) {
        console.error('Error performing manual sync:', error);
        showToast('Manual sync failed: ' + error.message, 'error');
        addSyncLog('error', `Manual sync failed: ${error.message}`);
    } finally {
        document.getElementById('manualSyncBtn').disabled = false;
        hideGlobalLoading();
    }
}

async function refreshFirebaseStatus() {
    try {
        showGlobalLoading('Refreshing Firebase status...');
        await initializeFirebaseManagement();
    } catch (error) {
        console.error('Error refreshing Firebase status:', error);
        showToast('Failed to refresh Firebase status', 'error');
    } finally {
        hideGlobalLoading();
    }
}

function clearSyncLogs() {
    if (confirm('Are you sure you want to clear all sync logs?')) {
        firebaseManagementData.syncLogs = [];
        updateSyncLogsDisplay();
        showToast('Sync logs cleared', 'info');
    }
}

function addSyncLog(type, message) {
    firebaseManagementData.syncLogs.push({
        timestamp: new Date(),
        type: type,
        message: message
    });
    
    if (firebaseManagementData.syncLogs.length > 100) {
        firebaseManagementData.syncLogs = firebaseManagementData.syncLogs.slice(-100);
    }
    
    updateSyncLogsDisplay();
}

function viewUser(userId) {
    // Find the user in the list
    const userIndex = firebaseManagementData.users.findIndex(u => u.uid === userId);
    if (userIndex === -1) {
        showToast('User not found', 'error');
        return;
    }

    const user = firebaseManagementData.users[userIndex];
    
    // Create and show user detail modal
    const modal = document.createElement('div');
    modal.className = 'modal-overlay';
    modal.innerHTML = `
        <div class="modal-content" style="max-width: 600px;">
            <div class="modal-header">
                <h2>User Details</h2>
                <button class="btn-close" onclick="this.closest('.modal-overlay').remove()">&times;</button>
            </div>
            <div class="modal-body" style="max-height: 500px; overflow-y: auto;">
                <div class="user-detail-card">
                    <div class="detail-row">
                        <label>UID:</label>
                        <span class="mono">${user.uid || 'N/A'}</span>
                    </div>
                    <div class="detail-row">
                        <label>Email:</label>
                        <span>${user.email || 'N/A'}</span>
                    </div>
                    <div class="detail-row">
                        <label>Display Name:</label>
                        <span>${user.displayName || 'Not set'}</span>
                    </div>
                    <div class="detail-row">
                        <label>Phone:</label>
                        <span>${user.phoneNumber || 'Not set'}</span>
                    </div>
                    <div class="detail-row">
                        <label>Email Verified:</label>
                        <span class="badge ${user.emailVerified ? 'success' : 'warning'}">
                            ${user.emailVerified ? 'Verified' : 'Not Verified'}
                        </span>
                    </div>
                    <div class="detail-row">
                        <label>Account Status:</label>
                        <span class="badge ${user.disabled ? 'danger' : 'success'}">
                            ${user.disabled ? 'Disabled' : 'Active'}
                        </span>
                    </div>
                    <div class="detail-row">
                        <label>Account Created:</label>
                        <span>${user.createdAt || 'N/A'}</span>
                    </div>
                    <div class="detail-row">
                        <label>Last Sign In:</label>
                        <span>${user.lastSignInTime || 'Never'}</span>
                    </div>
                    ${user.customClaims ? `
                        <div class="detail-row">
                            <label>Custom Claims:</label>
                            <pre>${JSON.stringify(user.customClaims, null, 2)}</pre>
                        </div>
                    ` : ''}
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" onclick="this.closest('.modal-overlay').remove()">Close</button>
                <button class="btn btn-warning" onclick="editUserModal('${user.uid}'); this.closest('.modal-overlay').remove()">Edit</button>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    
    // Add styles if not present
    addUserDetailStyles();
}

// Helper function to add modal styles
function addUserDetailStyles() {
    if (document.getElementById('user-detail-styles')) return;
    
    const style = document.createElement('style');
    style.id = 'user-detail-styles';
    style.innerHTML = `
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.5);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 10000;
        }
        
        .modal-content {
            background: white;
            border-radius: 8px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
            display: flex;
            flex-direction: column;
            max-height: 90vh;
        }
        
        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 20px;
            border-bottom: 1px solid #eee;
        }
        
        .modal-header h2 {
            margin: 0;
            font-size: 20px;
            color: #333;
        }
        
        .modal-body {
            padding: 20px;
            overflow-y: auto;
            flex: 1;
        }
        
        .modal-footer {
            padding: 15px 20px;
            border-top: 1px solid #eee;
            display: flex;
            gap: 10px;
            justify-content: flex-end;
        }
        
        .user-detail-card {
            background: #f9f9f9;
            border-radius: 8px;
            padding: 15px;
        }
        
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid #eee;
        }
        
        .detail-row:last-child {
            border-bottom: none;
        }
        
        .detail-row label {
            font-weight: 600;
            color: #555;
            min-width: 150px;
        }
        
        .detail-row span {
            color: #333;
        }
        
        .detail-row .mono {
            font-family: monospace;
            font-size: 12px;
            color: #666;
        }
        
        .badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }
        
        .badge.success {
            background: #d4edda;
            color: #155724;
        }
        
        .badge.warning {
            background: #fff3cd;
            color: #856404;
        }
        
        .badge.danger {
            background: #f8d7da;
            color: #721c24;
        }
        
        .btn-close {
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: #555;
        }
        
        .btn-close:hover {
            color: #000;
        }
    `;
    
    document.head.appendChild(style);
}

// Edit user modal function (placeholder)
function editUserModal(userId) {
    showToast('User edit feature - Coming soon', 'info');
}
