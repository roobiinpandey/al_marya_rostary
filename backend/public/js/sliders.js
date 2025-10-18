/* Sliders/Banners Management Module */

async function loadSliders() {
    try {
        showLoading('slidersTable');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/sliders`);
        const data = await handleApiResponse(response);
        
        if (data.success) {
            renderSlidersTable(data.data);
        } else {
            showErrorById('slidersTable', 'Failed to load banners');
        }
    } catch (error) {
        const logger = window.adminUtils?.logger || console;
        logger.error('Error loading banners:', error);
        showErrorById('slidersTable', 'Error loading banners. Please try again.');
    }
}

function renderSlidersTable(sliders) {
    const slidersArray = Array.isArray(sliders) ? sliders : [];
    
    if (slidersArray.length === 0) {
        document.getElementById('slidersTable').innerHTML = `
            <div class="empty-state">
                <i class="fas fa-images"></i>
                <h3>No Banners Yet</h3>
                <p>Create your first banner to display on the app home screen</p>
                <button class="btn btn-primary" onclick="showAddSliderModal()">
                    <i class="fas fa-plus"></i> Add Banner
                </button>
            </div>
        `;
        return;
    }
    
    let tableHTML = `
        <div class="table-actions">
            <button class="btn btn-primary" onclick="showAddSliderModal()">
                <i class="fas fa-plus"></i> Add Banner
            </button>
        </div>
        <table class="data-table">
            <thead>
                <tr>
                    <th>Preview</th>
                    <th>Title</th>
                    <th>Description</th>
                    <th>Order</th>
                    <th>Status</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
    `;
    
    slidersArray.forEach(slider => {
        const imageUrl = slider.imageUrl || slider.image || '/uploads/placeholder.jpg';
        const isActive = slider.isActive || slider.status === 'active';
        
        tableHTML += `
            <tr>
                <td>
                    <img src="${imageUrl}" alt="${slider.title || 'Banner'}" 
                         style="width: 100px; height: 50px; object-fit: cover; border-radius: 4px;">
                </td>
                <td>${slider.title || 'Untitled'}</td>
                <td>${slider.description || '-'}</td>
                <td>${slider.order || 0}</td>
                <td>
                    <span class="badge ${isActive ? 'badge-success' : 'badge-danger'}">
                        ${isActive ? 'Active' : 'Inactive'}
                    </span>
                </td>
                <td class="action-buttons">
                    <button class="btn-icon btn-edit" onclick="editSlider('${slider._id}')" 
                            title="Edit">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn-icon ${isActive ? 'btn-warning' : 'btn-success'}" 
                            onclick="toggleSliderStatus('${slider._id}', ${!isActive})" 
                            title="${isActive ? 'Deactivate' : 'Activate'}">
                        <i class="fas fa-${isActive ? 'eye-slash' : 'eye'}"></i>
                    </button>
                    <button class="btn-icon btn-danger" onclick="deleteSlider('${slider._id}')" 
                            title="Delete">
                        <i class="fas fa-trash"></i>
                    </button>
                </td>
            </tr>
        `;
    });
    
    tableHTML += `
            </tbody>
        </table>
    `;
    
    document.getElementById('slidersTable').innerHTML = tableHTML;
}

function showAddSliderModal() {
    showToast('Feature coming soon', 'info');
}

function editSlider(sliderId) {
    showToast('Edit feature coming soon', 'info');
}

async function toggleSliderStatus(sliderId, newStatus) {
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/sliders/${sliderId}`, {
            method: 'PATCH',
            body: JSON.stringify({ isActive: newStatus })
        });
        
        const data = await handleApiResponse(response);
        
        if (data.success) {
            showToast(`Banner ${newStatus ? 'activated' : 'deactivated'} successfully`, 'success');
            loadSliders();
        } else {
            showToast('Failed to update banner status', 'error');
        }
    } catch (error) {
        const logger = window.adminUtils?.logger || console;
        logger.error('Error toggling banner status:', error);
        showToast('Error updating banner status', 'error');
    }
}

async function deleteSlider(sliderId) {
    if (!confirm('Are you sure you want to delete this banner?')) {
        return;
    }
    
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/sliders/${sliderId}`, {
            method: 'DELETE'
        });
        
        const data = await handleApiResponse(response);
        
        if (data.success) {
            showToast('Banner deleted successfully', 'success');
            loadSliders();
        } else {
            showToast('Failed to delete banner', 'error');
        }
    } catch (error) {
        const logger = window.adminUtils?.logger || console;
        logger.error('Error deleting banner:', error);
        showToast('Error deleting banner', 'error');
    }
}
