/* Categories Management Module */

async function loadCategories() {
    try {
        showLoading('categoriesTable');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/categories`);
        const data = await response.json();

        if (data.success) {
            renderCategoriesTable(data.data);
            populateCategoryFilter(data.data);
        }
    } catch (error) {
        console.error('Error loading categories:', error);
        showErrorById('categoriesTable', 'Failed to load categories');
    }
}

function renderCategoriesTable(categories) {
    const tableElement = document.getElementById('categoriesTable');
    
    // Check if element exists before trying to modify it
    if (!tableElement) {
        console.warn('categoriesTable element not found on this page');
        return;
    }
    
    if (!categories || categories.length === 0) {
        tableElement.innerHTML = '<p class="text-center">No categories found.</p>';
        return;
    }

    const tableHTML = `
        <table class="data-table">
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Description</th>
                    <th>Color</th>
                    <th>Order</th>
                    <th>Products</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                ${categories.map(category => `
                    <tr>
                        <td>
                            <strong>${category.name?.en || 'N/A'}</strong><br>
                            <small>${category.name?.ar || ''}</small>
                        </td>
                        <td>
                            <small>${category.description?.en || 'N/A'}</small>
                        </td>
                        <td>
                            <div style="width: 30px; height: 30px; background-color: ${category.color || '#ccc'}; border-radius: 50%;"></div>
                        </td>
                        <td>${category.displayOrder || 0}</td>
                        <td>${category.productCount || 0}</td>
                        <td>
                            <button class="btn btn-info btn-sm" onclick="editCategory('${category._id}')">
                                <i class="fas fa-edit"></i>
                            </button>
                            <button class="btn btn-danger btn-sm" onclick="deleteCategory('${category._id}')">
                                <i class="fas fa-trash"></i>
                            </button>
                        </td>
                    </tr>
                `).join('')}
            </tbody>
        </table>
    `;
    tableElement.innerHTML = tableHTML;
}

function populateCategoryFilter(categories) {
    const select = document.getElementById('productCategoryFilter');
    if (select) {
        select.innerHTML = '<option value="">All Categories</option>' +
            categories.map(cat => `<option value="${cat._id}">${cat.name?.en || 'N/A'}</option>`).join('');
    }
}

async function editCategory(categoryId) {
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/categories/${categoryId}`);
        const data = await response.json();
        
        if (data.success) {
            showEditCategoryModal(data.data);
        } else {
            alert('Failed to load category details');
        }
    } catch (error) {
        console.error('Error loading category:', error);
        alert('Failed to load category details');
    }
}

async function deleteCategory(categoryId) {
    if (confirm('Are you sure you want to delete this category? This action cannot be undone.')) {
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/categories/${categoryId}`, {
                method: 'DELETE'
            });
            
            const data = await response.json();
            if (data.success) {
                alert('Category deleted successfully');
                loadCategories();
            } else {
                alert('Failed to delete category: ' + data.message);
            }
        } catch (error) {
            console.error('Error deleting category:', error);
            alert('Failed to delete category');
        }
    }
}

function showAddCategoryModal() {
    // Open the modal
    document.getElementById('categoryModal').style.display = 'flex';
    document.getElementById('categoryForm').reset();
    document.getElementById('categoryModalTitle').textContent = '📁 Create New Category';
    document.getElementById('submitCategoryBtn').innerHTML = '<i class="fas fa-plus"></i> Create Category';
    
    // Clear the editing category ID
    document.getElementById('categoryForm').dataset.editId = '';
}

function closeCategoryModal() {
    document.getElementById('categoryModal').style.display = 'none';
}

function showEditCategoryModal(category) {
    // Open the modal in edit mode
    document.getElementById('categoryModal').style.display = 'flex';
    document.getElementById('categoryModalTitle').textContent = '✏️ Edit Category';
    document.getElementById('submitCategoryBtn').innerHTML = '<i class="fas fa-save"></i> Update Category';
    
    // Populate the form
    document.getElementById('categoryNameEn').value = category.name?.en || category.name || '';
    document.getElementById('categoryNameAr').value = category.name?.ar || '';
    document.getElementById('categoryDescEn').value = category.description?.en || category.description || '';
    document.getElementById('categoryDescAr').value = category.description?.ar || '';
    document.getElementById('categoryColor').value = category.color || '#A89A6A';
    document.getElementById('categoryOrder').value = category.displayOrder || 0;
    document.getElementById('categoryIsActive').checked = category.isActive !== false;
    
    // Store the category ID for editing
    document.getElementById('categoryForm').dataset.editId = category._id || category.id;
}

// Handle category form submission
async function handleCategorySubmit(event) {
    event.preventDefault();
    
    const form = event.target;
    const editId = form.dataset.editId;
    
    const categoryData = {
        name: form.nameEn.value,
        nameEn: form.nameEn.value,
        nameAr: form.nameAr.value,
        description: form.descriptionEn.value || '',
        descriptionEn: form.descriptionEn.value || '',
        descriptionAr: form.descriptionAr.value || '',
        color: form.color.value,
        displayOrder: parseInt(form.displayOrder.value) || 0,
        isActive: form.isActive.checked
    };
    
    try {
        if (editId) {
            // Update existing category
            await updateCategory(editId, categoryData);
        } else {
            // Create new category
            await createCategory(categoryData);
        }
    } catch (error) {
        console.error('Error submitting category:', error);
        alert('Error saving category. Please try again.');
    }
}

async function createCategory(categoryData) {
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/categories`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(categoryData)
        });
        
        const data = await response.json();
        if (data.success) {
            alert('✅ Category created successfully!');
            closeCategoryModal();
            loadCategories();
        } else {
            alert('❌ Failed to create category: ' + data.message);
        }
    } catch (error) {
        console.error('Error creating category:', error);
        alert('❌ Failed to create category');
    }
}

async function updateCategory(categoryId, updates) {
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/categories/${categoryId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(updates)
        });
        
        const data = await response.json();
        if (data.success) {
            alert('✅ Category updated successfully!');
            closeCategoryModal();
            loadCategories();
        } else {
            alert('❌ Failed to update category: ' + data.message);
        }
    } catch (error) {
        console.error('Error updating category:', error);
        alert('❌ Failed to update category');
    }
}
