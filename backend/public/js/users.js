/* Users Management Module */

let currentView = 'local'; // 'local' or 'firebase'

async function loadUsers() {
    try {
        showLoading('usersTable');
        
        // Load users based on current view
        if (currentView === 'firebase') {
            await loadFirebaseUsers();
        } else {
            await loadLocalUsers();
        }
    } catch (error) {
        console.error('Error loading users:', error);
        showErrorById('usersTable', 'Failed to load users');
    }
}

async function loadLocalUsers() {
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/users`);
        const data = await response.json();

        if (data.success) {
            renderLocalUsersTable(data.data);
        }
    } catch (error) {
        console.error('Error loading local users:', error);
        showErrorById('usersTable', 'Failed to load local users');
    }
}

async function loadFirebaseUsers() {
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/firebase-users?limit=100`);
        const data = await response.json();

        if (data.success) {
            renderFirebaseUsersTable(data.data.users);
        } else {
            showErrorById('usersTable', data.message || 'Failed to load Firebase users');
        }
    } catch (error) {
        console.error('Error loading Firebase users:', error);
        showErrorById('usersTable', 'Failed to load Firebase users: ' + error.message);
    }
}

function switchView(view) {
    currentView = view;
    
    // Update button states
    document.querySelectorAll('.view-switch-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');
    
    loadUsers();
}

function renderLocalUsersTable(users) {
    if (!users || users.length === 0) {
        document.getElementById('usersTable').innerHTML = `
            <div style="text-align: center; padding: 40px;">
                <i class="fas fa-users" style="font-size: 64px; color: #ddd; margin-bottom: 20px;"></i>
                <p style="font-size: 18px; color: #666;">No local users found</p>
                <button class="btn btn-primary" onclick="switchView('firebase')">View Firebase Users</button>
            </div>
        `;
        return;
    }

    const tableHTML = `
        <div style="margin-bottom: 20px;">
            <button class="btn view-switch-btn active" onclick="switchView('local')">
                <i class="fas fa-database"></i> Local Users
            </button>
            <button class="btn view-switch-btn" onclick="switchView('firebase')">
                <i class="fab fa-google"></i> Firebase Users
            </button>
        </div>
        <table class="data-table">
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Phone</th>
                    <th>Role</th>
                    <th>Status</th>
                    <th>Firebase</th>
                    <th>Joined</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                ${users.map(user => {
                    const firebaseStatus = user.firebaseUid 
                        ? (user.firebaseSyncStatus === 'synced' ? 'synced' : user.firebaseSyncStatus || 'unknown')
                        : 'not-linked';
                    
                    const firebaseStatusColor = {
                        'synced': 'status-completed',
                        'pending': 'status-warning', 
                        'error': 'status-error',
                        'manual': 'status-inactive',
                        'not-linked': 'status-inactive'
                    };

                    return `
                    <tr>
                        <td>
                            <strong>${user.name || 'N/A'}</strong>
                            ${user.firebaseUid ? '<i class="fas fa-link" style="color: #28a745; margin-left: 5px;" title="Linked to Firebase"></i>' : ''}
                        </td>
                        <td>
                            ${user.email || 'N/A'}
                            ${user.isEmailVerified ? '<i class="fas fa-check-circle" style="color: #28a745; margin-left: 5px;" title="Email Verified"></i>' : ''}
                        </td>
                        <td>${user.phone || 'N/A'}</td>
                        <td>
                            <span class="status-badge ${user.roles?.includes('admin') ? 'status-completed' : 'status-active'}">
                                ${user.roles?.join(', ') || 'Customer'}
                            </span>
                        </td>
                        <td>
                            <span class="status-badge ${user.isActive ? 'status-active' : 'status-inactive'}">
                                ${user.isActive ? 'Active' : 'Inactive'}
                            </span>
                        </td>
                        <td>
                            <span class="status-badge ${firebaseStatusColor[firebaseStatus] || 'status-inactive'}" 
                                  title="${user.firebaseSyncError || 'Firebase sync status'}">
                                ${firebaseStatus === 'not-linked' ? 'Not Linked' : 
                                  firebaseStatus === 'synced' ? '✓ Synced' :
                                  firebaseStatus === 'pending' ? '⏳ Pending' :
                                  firebaseStatus === 'error' ? '❌ Error' :
                                  firebaseStatus === 'manual' ? '👤 Manual' : firebaseStatus}
                            </span>
                        </td>
                        <td>${new Date(user.createdAt).toLocaleDateString()}</td>
                        <td style="white-space: nowrap;">
                            <button class="btn btn-info btn-sm" onclick="editUser('${user._id}')" title="Edit User">
                                <i class="fas fa-edit"></i>
                            </button>
                            <button class="btn btn-warning btn-sm" onclick="toggleUserStatus('${user._id}')" title="Toggle Status">
                                <i class="fas fa-toggle-on"></i>
                            </button>
                            ${user.firebaseUid 
                                ? `<button class="btn btn-secondary btn-sm" onclick="syncUserToFirebase('${user._id}')" title="Resync to Firebase">
                                    <i class="fas fa-sync"></i>
                                  </button>`
                                : `<button class="btn btn-success btn-sm" onclick="syncUserToFirebase('${user._id}')" title="Sync to Firebase">
                                    <i class="fas fa-cloud-upload-alt"></i>
                                  </button>`
                            }
                            <button class="btn btn-danger btn-sm" onclick="deleteUser('${user._id}')" title="Delete User">
                                <i class="fas fa-trash"></i>
                            </button>
                        </td>
                    </tr>
                    `;
                }).join('')}
            </tbody>
        </table>
    `;
    document.getElementById('usersTable').innerHTML = tableHTML;
}

function renderFirebaseUsersTable(users) {
    if (!users || users.length === 0) {
        document.getElementById('usersTable').innerHTML = `
            <div style="text-align: center; padding: 40px;">
                <i class="fab fa-google" style="font-size: 64px; color: #ddd; margin-bottom: 20px;"></i>
                <p style="font-size: 18px; color: #666;">No Firebase users found</p>
                <button class="btn btn-primary" onclick="switchView('local')">View Local Users</button>
            </div>
        `;
        return;
    }

    const tableHTML = `
        <div style="margin-bottom: 20px;">
            <button class="btn view-switch-btn" onclick="switchView('local')">
                <i class="fas fa-database"></i> Local Users
            </button>
            <button class="btn view-switch-btn active" onclick="switchView('firebase')">
                <i class="fab fa-google"></i> Firebase Users (${users.length})
            </button>
            <button class="btn btn-success" onclick="syncAllFirebaseUsers()">
                <i class="fas fa-sync"></i> Sync All to Local
            </button>
        </div>
        <table class="data-table">
            <thead>
                <tr>
                    <th>Display Name</th>
                    <th>Email</th>
                    <th>Phone</th>
                    <th>Provider</th>
                    <th>Status</th>
                    <th>Local Sync</th>
                    <th>Last Sign In</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                ${users.map(user => {
                    const syncStatus = user.syncStatus.syncStatus;
                    const isLinked = user.syncStatus.isLinked;
                    
                    const syncStatusColor = {
                        'synced': 'status-completed',
                        'pending': 'status-warning',
                        'error': 'status-error',
                        'not-synced': 'status-inactive'
                    };

                    const providerNames = user.providerData.map(p => {
                        if (p.providerId === 'password') return 'Email';
                        if (p.providerId === 'google.com') return 'Google';
                        if (p.providerId === 'phone') return 'Phone';
                        return p.providerId;
                    }).join(', ');

                    return `
                    <tr>
                        <td>
                            ${user.photoURL ? `<img src="${user.photoURL}" style="width: 30px; height: 30px; border-radius: 50%; vertical-align: middle; margin-right: 8px;" />` : ''}
                            <strong>${user.displayName || 'N/A'}</strong>
                        </td>
                        <td>
                            ${user.email || 'N/A'}
                            ${user.emailVerified ? '<i class="fas fa-check-circle" style="color: #28a745; margin-left: 5px;" title="Email Verified"></i>' : '<i class="fas fa-times-circle" style="color: #dc3545; margin-left: 5px;" title="Email Not Verified"></i>'}
                        </td>
                        <td>${user.phoneNumber || 'N/A'}</td>
                        <td><span class="status-badge status-info">${providerNames}</span></td>
                        <td>
                            <span class="status-badge ${user.disabled ? 'status-inactive' : 'status-active'}">
                                ${user.disabled ? 'Disabled' : 'Active'}
                            </span>
                        </td>
                        <td>
                            <span class="status-badge ${syncStatusColor[syncStatus] || 'status-inactive'}" 
                                  title="${user.syncStatus.syncError || 'Sync status'}">
                                ${isLinked ? '✓ Linked' : '⚠ Not Synced'}
                            </span>
                        </td>
                        <td>${user.metadata.lastSignInTime ? new Date(user.metadata.lastSignInTime).toLocaleDateString() : 'Never'}</td>
                        <td style="white-space: nowrap;">
                            <button class="btn btn-info btn-sm" onclick="viewFirebaseUser('${user.uid}')" title="View Details">
                                <i class="fas fa-eye"></i>
                            </button>
                            <button class="btn btn-warning btn-sm" onclick="toggleFirebaseUserStatus('${user.uid}', ${user.disabled})" title="${user.disabled ? 'Enable' : 'Disable'} User">
                                <i class="fas fa-toggle-${user.disabled ? 'off' : 'on'}"></i>
                            </button>
                            ${!isLinked 
                                ? `<button class="btn btn-success btn-sm" onclick="syncFirebaseUserToLocal('${user.uid}')" title="Sync to Local">
                                    <i class="fas fa-download"></i>
                                  </button>`
                                : `<button class="btn btn-secondary btn-sm" onclick="syncFirebaseUserToLocal('${user.uid}')" title="Re-sync">
                                    <i class="fas fa-sync"></i>
                                  </button>`
                            }
                            <button class="btn btn-danger btn-sm" onclick="deleteFirebaseUser('${user.uid}')" title="Delete from Firebase">
                                <i class="fas fa-trash"></i>
                            </button>
                        </td>
                    </tr>
                    `;
                }).join('')}
            </tbody>
        </table>
    `;
    document.getElementById('usersTable').innerHTML = tableHTML;
}

async function syncAllFirebaseUsers() {
    try {
        const confirmSync = confirm('This will sync ALL Firebase users to the local database. This may take a few minutes. Continue?');
        if (!confirmSync) return;

        showGlobalLoading('Syncing Firebase users to local database...');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/firebase-sync/bulk-sync-from-firebase`, {
            method: 'POST'
        });
        
        const data = await response.json();
        
        if (data.success) {
            showToast(`Sync completed! ${data.data.synced} users synced, ${data.data.errors} errors`, 'success');
            await loadUsers();
        } else {
            showToast(`Sync failed: ${data.message}`, 'error');
        }
    } catch (error) {
        console.error('Error syncing all Firebase users:', error);
        showToast('Failed to sync Firebase users', 'error');
    } finally {
        hideGlobalLoading();
    }
}

async function syncFirebaseUserToLocal(firebaseUid) {
    try {
        showGlobalLoading('Syncing user to local database...');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/firebase-users/${firebaseUid}/sync-to-local`, {
            method: 'POST'
        });
        
        const data = await response.json();
        
        if (data.success) {
            showToast('User synced successfully!', 'success');
            await loadUsers();
        } else {
            showToast(`Sync failed: ${data.message}`, 'error');
        }
    } catch (error) {
        console.error('Error syncing Firebase user:', error);
        showToast('Failed to sync Firebase user', 'error');
    } finally {
        hideGlobalLoading();
    }
}

async function viewFirebaseUser(firebaseUid) {
    try {
        showGlobalLoading('Loading user details...');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/firebase-users/${firebaseUid}`);
        const data = await response.json();
        
        hideGlobalLoading();
        
        if (data.success) {
            const user = data.data;
            const modalHTML = `
                <div class="modal-overlay" onclick="closeFirebaseUserModal()">
                    <div class="modal-content" onclick="event.stopPropagation()" style="max-width: 800px;">
                        <div class="modal-header">
                            <h2><i class="fab fa-google"></i> Firebase User Details</h2>
                            <button class="close-btn" onclick="closeFirebaseUserModal()">&times;</button>
                        </div>
                        <div class="modal-body">
                            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                                <div>
                                    <h3>Firebase Account</h3>
                                    <p><strong>UID:</strong> ${user.firebase.uid}</p>
                                    <p><strong>Email:</strong> ${user.firebase.email || 'N/A'}</p>
                                    <p><strong>Display Name:</strong> ${user.firebase.displayName || 'N/A'}</p>
                                    <p><strong>Phone:</strong> ${user.firebase.phoneNumber || 'N/A'}</p>
                                    <p><strong>Email Verified:</strong> ${user.firebase.emailVerified ? '✓ Yes' : '✗ No'}</p>
                                    <p><strong>Status:</strong> ${user.firebase.disabled ? 'Disabled' : 'Active'}</p>
                                    <p><strong>Created:</strong> ${new Date(user.firebase.metadata.creationTime).toLocaleString()}</p>
                                    <p><strong>Last Sign In:</strong> ${user.firebase.metadata.lastSignInTime ? new Date(user.firebase.metadata.lastSignInTime).toLocaleString() : 'Never'}</p>
                                    <p><strong>Custom Claims:</strong> ${JSON.stringify(user.firebase.customClaims || {}, null, 2)}</p>
                                </div>
                                <div>
                                    <h3>Local Database</h3>
                                    ${user.local ? `
                                        <p><strong>Linked:</strong> ✓ Yes</p>
                                        <p><strong>Local ID:</strong> ${user.local._id}</p>
                                        <p><strong>Name:</strong> ${user.local.name}</p>
                                        <p><strong>Roles:</strong> ${user.local.roles.join(', ')}</p>
                                        <p><strong>Active:</strong> ${user.local.isActive ? 'Yes' : 'No'}</p>
                                        <p><strong>Sync Status:</strong> ${user.local.firebaseSyncStatus}</p>
                                        <p><strong>Last Sync:</strong> ${user.local.lastFirebaseSync ? new Date(user.local.lastFirebaseSync).toLocaleString() : 'Never'}</p>
                                    ` : `
                                        <p><strong>Linked:</strong> ✗ No</p>
                                        <p style="color: #dc3545;">This Firebase user is not synced to the local database.</p>
                                        <button class="btn btn-primary" onclick="syncFirebaseUserToLocal('${user.firebase.uid}'); closeFirebaseUserModal();">
                                            <i class="fas fa-download"></i> Sync to Local Database
                                        </button>
                                    `}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            `;
            document.body.insertAdjacentHTML('beforeend', modalHTML);
        }
    } catch (error) {
        hideGlobalLoading();
        console.error('Error viewing Firebase user:', error);
        showToast('Failed to load user details', 'error');
    }
}

function closeFirebaseUserModal() {
    const modal = document.querySelector('.modal-overlay');
    if (modal) modal.remove();
}

async function toggleFirebaseUserStatus(firebaseUid, currentlyDisabled) {
    try {
        const action = currentlyDisabled ? 'enable' : 'disable';
        const confirmAction = confirm(`Are you sure you want to ${action} this Firebase user?`);
        if (!confirmAction) return;

        showGlobalLoading(`${action === 'enable' ? 'Enabling' : 'Disabling'} user...`);
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/firebase-users/${firebaseUid}/toggle-active`, {
            method: 'POST'
        });
        
        const data = await response.json();
        
        if (data.success) {
            showToast(`User ${action}d successfully!`, 'success');
            await loadUsers();
        } else {
            showToast(`Failed to ${action} user: ${data.message}`, 'error');
        }
    } catch (error) {
        console.error('Error toggling Firebase user status:', error);
        showToast('Failed to toggle user status', 'error');
    } finally {
        hideGlobalLoading();
    }
}

async function deleteFirebaseUser(firebaseUid) {
    try {
        const confirmDelete = confirm('⚠️ WARNING: This will permanently delete the user from Firebase Authentication!\n\nThe user will be unable to login to the mobile app.\n\nContinue?');
        if (!confirmDelete) return;

        showGlobalLoading('Deleting Firebase user...');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/firebase-users/${firebaseUid}`, {
            method: 'DELETE'
        });
        
        const data = await response.json();
        
        if (data.success) {
            showToast('Firebase user deleted successfully!', 'success');
            await loadUsers();
        } else {
            showToast(`Failed to delete user: ${data.message}`, 'error');
        }
    } catch (error) {
        console.error('Error deleting Firebase user:', error);
        showToast('Failed to delete Firebase user', 'error');
    } finally {
        hideGlobalLoading();
    }
}

function editUser(userId) {
    showToast('Edit user feature coming soon', 'info');
}

function toggleUserStatus(userId) {
    showToast('Toggle user status feature coming soon', 'info');
}

async function syncUserToFirebase(userId) {
    try {
        showGlobalLoading('Syncing user to Firebase...');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/firebase-sync/sync-to-firebase/${userId}`, {
            method: 'POST'
        });
        
        const data = await response.json();
        
        if (data.success) {
            showToast('User synced to Firebase successfully!', 'success');
            await loadUsers();
        } else {
            showToast(`Failed to sync user: ${data.message}`, 'error');
        }
    } catch (error) {
        console.error('Error syncing user:', error);
        showToast('Failed to sync user to Firebase', 'error');
    } finally {
        hideGlobalLoading();
    }
}

async function deleteUser(userId) {
    try {
        const confirmDelete = confirm('Are you sure you want to delete this user? This action cannot be undone and will also remove their Firebase account if linked.');
        if (!confirmDelete) return;

        showGlobalLoading('Deleting user...');

        const userResponse = await authenticatedFetch(`${API_BASE_URL}/api/admin/users/${userId}`);
        const userData = await userResponse.json();
        
        if (userData.success && userData.data.firebaseUid) {
            const firebaseResponse = await authenticatedFetch(`${API_BASE_URL}/api/firebase-sync/firebase-user/${userData.data.firebaseUid}`, {
                method: 'DELETE'
            });
            
            if (!firebaseResponse.ok) {
                const firebaseError = await firebaseResponse.json();
                console.warn('Failed to delete Firebase user:', firebaseError.message);
            }
        }
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/users/${userId}`, {
            method: 'DELETE'
        });
        
        const data = await response.json();
        
        if (data.success) {
            showToast('User deleted successfully', 'success');
            await loadUsers();
        } else {
            showToast('Failed to delete user: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('Error deleting user:', error);
        showToast('Failed to delete user', 'error');
    } finally {
        hideGlobalLoading();
    }
}

function showAddUserModal() {
    showToast('User creation is available through the registration process or API endpoints.', 'info');
}
