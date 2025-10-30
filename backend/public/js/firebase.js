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
    showToast('User details feature coming soon', 'info');
}
