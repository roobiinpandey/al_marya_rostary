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
    if (!categories || categories.length === 0) {
        document.getElementById('categoriesTable').innerHTML = '<p class="text-center">No categories found.</p>';
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
    document.getElementById('categoriesTable').innerHTML = tableHTML;
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
    const nameEn = prompt('Category Name (English):');
    const nameAr = prompt('Category Name (Arabic):');
    const descEn = prompt('Description (English):');
    const descAr = prompt('Description (Arabic):');
    const color = prompt('Color (hex code):', '#A89A6A');
    
    if (nameEn && nameAr) {
        createCategory({
            name: nameEn,
            nameEn: nameEn,
            nameAr: nameAr,
            description: descEn || '',
            descriptionEn: descEn || '',
            descriptionAr: descAr || '',
            color: color
        });
    }
}

function showEditCategoryModal(category) {
    const nameEn = prompt('Category Name (English):', category.name?.en || category.name);
    const nameAr = prompt('Category Name (Arabic):', category.name?.ar || '');
    const descEn = prompt('Description (English):', category.description?.en || category.description);
    const descAr = prompt('Description (Arabic):', category.description?.ar || '');
    const color = prompt('Color (hex code):', category.color || '#A89A6A');
    
    if (nameEn) {
        updateCategory(category._id || category.id, {
            name: nameEn,
            nameEn: nameEn,
            nameAr: nameAr || nameEn,
            description: descEn || '',
            descriptionEn: descEn || '',
            descriptionAr: descAr || descEn || '',
            color: color
        });
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
            alert('Category created successfully');
            loadCategories();
        } else {
            alert('Failed to create category: ' + data.message);
        }
    } catch (error) {
        console.error('Error creating category:', error);
        alert('Failed to create category');
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
            alert('Category updated successfully');
            loadCategories();
        } else {
            alert('Failed to update category: ' + data.message);
        }
    } catch (error) {
        console.error('Error updating category:', error);
        alert('Failed to update category');
    }
}
