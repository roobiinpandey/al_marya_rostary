/* Products Management Module */

async function loadProducts() {
    try {
        showLoading('productsTable');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/coffees`);
        const data = await response.json();

        if (data.success) {
            renderProductsTable(data.data);
        }
    } catch (error) {
        console.error('Error loading products:', error);
        showErrorById('productsTable', 'Failed to load products');
    }
}

function renderProductsTable(products) {
    if (!products || products.length === 0) {
        document.getElementById('productsTable').innerHTML = '<p class="text-center">No products found.</p>';
        return;
    }

    const tableHTML = `
        <table class="data-table">
            <thead>
                <tr>
                    <th>Image</th>
                    <th>Name</th>
                    <th>Origin & Roast</th>
                    <th>Size Variants & Prices</th>
                    <th>Status</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                ${products.map(product => {
                    const formatVariants = (variants) => {
                        if (!variants || variants.length === 0) {
                            return `<span class="price-badge">AED ${(product.price || 0).toFixed(2)}</span>`;
                        }
                        
                        return variants.filter(v => v.isActive).map(variant => `
                            <div class="variant-display">
                                <span class="variant-size">${variant.size}</span>
                                <span class="variant-price">AED ${variant.price.toFixed(2)}</span>
                                <span class="variant-stock">(${variant.stock || 0} in stock)</span>
                            </div>
                        `).join('');
                    };

                    return `
                    <tr>
                        <td>
                            <img src="${product.image || '/assets/images/default-coffee.jpg'}" 
                                 alt="${product.name?.en || 'Product'}" 
                                 style="width: 60px; height: 60px; border-radius: 8px; object-fit: cover; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                        </td>
                        <td>
                            <div class="product-name">
                                <strong>${product.name?.en || product.localizedName || 'N/A'}</strong>
                                ${product.name?.ar ? `<br><small style="color: #666; direction: rtl;">${product.name.ar}</small>` : ''}
                                ${product.isFeatured ? '<br><span class="featured-badge">⭐ Featured</span>' : ''}
                            </div>
                        </td>
                        <td>
                            <div class="product-details">
                                <strong>${product.origin || 'N/A'}</strong>
                                <br><small>${product.roastLevel || 'Medium'} Roast</small>
                                ${product.categories && product.categories.length > 0 ? 
                                    `<br><span class="category-tag">${product.categories[0]}</span>` : ''}
                            </div>
                        </td>
                        <td>
                            <div class="variants-display">
                                ${formatVariants(product.variants)}
                            </div>
                        </td>
                        <td>
                            <span class="status-badge ${product.isActive ? 'status-active' : 'status-inactive'}">
                                ${product.isActive ? 'Active' : 'Inactive'}
                            </span>
                        </td>
                        <td>
                            <button class="btn btn-info btn-sm" onclick="viewProduct('${product._id}')" title="View Details">
                                <i class="fas fa-eye"></i>
                            </button>
                            <button class="btn btn-warning btn-sm" onclick="editProduct('${product._id}')" title="Edit Product">
                                <i class="fas fa-edit"></i>
                            </button>
                            <button class="btn btn-danger btn-sm" onclick="deleteProduct('${product._id}')" title="Delete Product">
                                <i class="fas fa-trash"></i>
                            </button>
                        </td>
                    </tr>
                    `;
                }).join('')}
            </tbody>
        </table>
    `;
    document.getElementById('productsTable').innerHTML = tableHTML;
}

async function editProduct(productId) {
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/coffees/${productId}`);
        const data = await response.json();
        
        if (data.success) {
            showEditProductModal(data.data);
        } else {
            alert('Failed to load product details');
        }
    } catch (error) {
        console.error('Error loading product:', error);
        alert('Failed to load product details');
    }
}

async function viewProduct(productId) {
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/coffees/${productId}`);
        const data = await response.json();
        
        if (data.success) {
            const product = data.data;
            
            const productInfo = `
                Product: ${product.name?.en || 'N/A'}
                Arabic: ${product.name?.ar || 'N/A'}
                Origin: ${product.origin || 'N/A'}
                Roast: ${product.roastLevel || 'N/A'}
                
                Size Variants:
                ${product.variants ? product.variants.map(v => `${v.size}: AED ${v.price}`).join(', ') : 'No variants'}
            `;
            
            alert(productInfo);
        } else {
            alert('Failed to load product details');
        }
    } catch (error) {
        console.error('Error loading product:', error);
        alert('Failed to load product details');
    }
}

async function deleteProduct(productId) {
    if (!confirm('Are you sure you want to delete this product? This action cannot be undone.')) {
        return;
    }

    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/coffees/${productId}`, {
            method: 'DELETE'
        });
            
        const data = await response.json();
        if (data.success) {
            alert('Product deleted successfully');
            loadProducts();
        } else {
            alert('Failed to delete product: ' + data.message);
        }
    } catch (error) {
        console.error('Error deleting product:', error);
        alert('Failed to delete product');
    }
}

function showEditProductModal(product) {
    const newName = prompt('Product Name (English):', product.name?.en || product.name);
    const newPrice = prompt('Product Price (AED):', product.price);
    
    if (newName && newPrice) {
        updateProduct(product._id || product.id, {
            name: newName,
            nameEn: newName,
            price: parseFloat(newPrice)
        });
    }
}

async function updateProduct(productId, updates) {
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/coffees/${productId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(updates)
        });
        
        const data = await response.json();
        if (data.success) {
            alert('Product updated successfully');
            loadProducts();
        } else {
            alert('Failed to update product: ' + data.message);
        }
    } catch (error) {
        console.error('Error updating product:', error);
        alert('Failed to update product');
    }
}

function showAddProductModal() {
    document.getElementById('productModal').style.display = 'flex';
    document.getElementById('productCreationForm').reset();
    document.getElementById('productImagePreview').style.display = 'none';
    document.getElementById('modalTitle').textContent = '☕ Create New Product';
    document.getElementById('createProductBtn').innerHTML = '<i class="fas fa-plus"></i> Create Product';
    
    resetProductVariants();
}

function closeProductModal() {
    document.getElementById('productModal').style.display = 'none';
}

function resetProductVariants() {
    document.querySelector('input[name="variant_250gm_price"]').value = '45.00';
    document.querySelector('input[name="variant_500gm_price"]').value = '80.00';
    document.querySelector('input[name="variant_1kg_price"]').value = '150.00';
    
    document.querySelector('input[name="variant_250gm_stock"]').value = '100';
    document.querySelector('input[name="variant_500gm_stock"]').value = '100';
    document.querySelector('input[name="variant_1kg_stock"]').value = '50';
    
    document.querySelector('input[name="variant_250gm_desc_en"]').value = 'Perfect for trying new flavors';
    document.querySelector('input[name="variant_250gm_desc_ar"]').value = 'مثالية لتجربة النكهات الجديدة';
    
    document.querySelector('input[name="variant_500gm_desc_en"]').value = 'Perfect for regular consumption';
    document.querySelector('input[name="variant_500gm_desc_ar"]').value = 'مثالية للاستهلاك المنتظم';
    
    document.querySelector('input[name="variant_1kg_desc_en"]').value = 'Perfect for bulk purchase and sharing';
    document.querySelector('input[name="variant_1kg_desc_ar"]').value = 'مثالية للشراء بالجملة والمشاركة';
}
