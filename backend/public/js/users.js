/* Users Management Module */

async function loadUsers() {
    try {
        showLoading('usersTable');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/users`);
        const data = await response.json();

        if (data.success) {
            renderUsersTable(data.data);
        }
    } catch (error) {
        console.error('Error loading users:', error);
        showErrorById('usersTable', 'Failed to load users');
    }
}

function renderUsersTable(users) {
    if (!users || users.length === 0) {
        document.getElementById('usersTable').innerHTML = '<p class="text-center">No users found.</p>';
        return;
    }

    const tableHTML = `
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
