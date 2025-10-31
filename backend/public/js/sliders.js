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
        // Skip sliders without valid IDs
        if (!slider._id) {
            console.warn('Skipping slider without ID:', slider);
            return;
        }
        
        const imageUrl = slider.imageUrl || slider.image || '/uploads/placeholder.jpg';
        const isActive = slider.isActive || slider.status === 'active';
        
        tableHTML += `
            <tr>
                <td>
                    <div data-banner-id="${slider._id}" style="cursor: pointer;" title="Click to preview banner">
                        <img src="${imageUrl}" alt="${slider.title || 'Banner'}" 
                             style="width: 100px; height: 50px; object-fit: cover; border-radius: 4px;">
                    </div>
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
    document.getElementById('sliderModal').style.display = 'flex';
    document.getElementById('sliderForm').reset();
    document.getElementById('sliderId').value = '';
    document.getElementById('sliderImagePreview').style.display = 'none';
    document.getElementById('sliderMobileImagePreview').style.display = 'none';
    document.getElementById('sliderModalTitle').textContent = '🎨 Create New Banner';
    document.getElementById('submitSliderBtn').innerHTML = '<i class="fas fa-plus"></i> Create Banner';
    
    // Make image required for new banner
    document.getElementById('sliderImage').required = true;
}

function closeSliderModal() {
    document.getElementById('sliderModal').style.display = 'none';
}

function previewSliderImage(event, previewId) {
    const file = event.target.files[0];
    const preview = document.getElementById(previewId);
    
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
}

async function handleSliderSubmit(event) {
    event.preventDefault();
    
    const form = event.target;
    const formData = new FormData();
    const sliderId = document.getElementById('sliderId').value;
    
    // Add image files
    const imageFile = document.getElementById('sliderImage').files[0];
    if (imageFile) {
        formData.append('image', imageFile);
    }
    
    const mobileImageFile = document.getElementById('sliderMobileImage').files[0];
    if (mobileImageFile) {
        formData.append('mobileImage', mobileImageFile);
    }
    
    // Add form fields
    formData.append('title', form.title.value);
    formData.append('description', form.description.value || '');
    formData.append('link', form.link.value || '');
    formData.append('linkType', form.linkType.value);
    formData.append('displayOrder', form.displayOrder.value || 0);
    formData.append('isActive', form.isActive.checked);
    
    // Add schedule if provided
    if (form.startDate.value) {
        formData.append('startDate', new Date(form.startDate.value).toISOString());
    }
    if (form.endDate.value) {
        formData.append('endDate', new Date(form.endDate.value).toISOString());
    }
    
    // Add target audience
    const targetAudience = Array.from(form.targetAudience.selectedOptions).map(opt => opt.value);
    formData.append('targetAudience', JSON.stringify(targetAudience));
    
    try {
        const url = sliderId 
            ? `${API_BASE_URL}/api/sliders/${sliderId}`
            : `${API_BASE_URL}/api/sliders`;
        
        const method = sliderId ? 'PUT' : 'POST';
        
        const response = await authenticatedFetch(url, {
            method: method,
            body: formData
            // Don't set Content-Type header - browser will set it with boundary for FormData
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert(sliderId ? 'Banner updated successfully!' : 'Banner created successfully!');
            closeSliderModal();
            loadSliders();
        } else {
            alert('Failed to save banner: ' + data.message);
        }
    } catch (error) {
        console.error('Error saving banner:', error);
        alert('Error saving banner. Please try again.');
    }
}

function editSlider(sliderId) {
    // Find the slider data from the loaded sliders
    // For now, we'll fetch it fresh from the API
    fetchSliderForEdit(sliderId);
}

async function fetchSliderForEdit(sliderId) {
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/sliders/${sliderId}`);
        const data = await response.json();
        
        if (data.success) {
            populateSliderForm(data.data);
        } else {
            alert('Failed to load banner details');
        }
    } catch (error) {
        console.error('Error fetching banner:', error);
        alert('Error loading banner details');
    }
}

function populateSliderForm(slider) {
    // Open modal
    document.getElementById('sliderModal').style.display = 'flex';
    document.getElementById('sliderModalTitle').textContent = '✏️ Edit Banner';
    document.getElementById('submitSliderBtn').innerHTML = '<i class="fas fa-save"></i> Update Banner';
    
    // Make image optional for edit
    document.getElementById('sliderImage').required = false;
    
    // Fill form fields
    document.getElementById('sliderId').value = slider._id;
    document.getElementById('sliderTitle').value = slider.title || '';
    document.getElementById('sliderDescription').value = slider.description || '';
    document.getElementById('sliderLink').value = slider.link || '';
    document.getElementById('sliderLinkType').value = slider.linkType || 'internal';
    document.getElementById('sliderOrder').value = slider.displayOrder || 0;
    document.getElementById('sliderIsActive').checked = slider.isActive !== false;
    
    // Show existing image
    if (slider.image || slider.imageUrl) {
        const preview = document.getElementById('sliderImagePreview');
        preview.src = slider.image || slider.imageUrl;
        preview.style.display = 'block';
    }
    
    if (slider.mobileImage) {
        const preview = document.getElementById('sliderMobileImagePreview');
        preview.src = slider.mobileImage;
        preview.style.display = 'block';
    }
    
    // Set schedule dates
    if (slider.startDate) {
        document.getElementById('sliderStartDate').value = formatDateTimeLocal(slider.startDate);
    }
    if (slider.endDate) {
        document.getElementById('sliderEndDate').value = formatDateTimeLocal(slider.endDate);
    }
    
    // Set target audience
    if (slider.targetAudience && slider.targetAudience.length > 0) {
        const select = document.getElementById('sliderTargetAudience');
        Array.from(select.options).forEach(option => {
            option.selected = slider.targetAudience.includes(option.value);
        });
    }
}

function formatDateTimeLocal(dateString) {
    const date = new Date(dateString);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day}T${hours}:${minutes}`;
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
