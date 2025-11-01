/* Products Management Module */

// ============================================================================
// IMAGE URL HELPER FUNCTION
// ============================================================================

/**
 * Get proper image URL - handles both local and Cloudinary URLs
 * @param {string} imagePath - The image path from database
 * @returns {string} - Properly formatted image URL
 */
function getImageUrl(imagePath) {
    if (!imagePath) {
        return '/assets/images/default-coffee.jpg';
    }
    
    // If it's already a full URL (Cloudinary or external), return as-is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return imagePath;
    }
    
    // If it's a relative path starting with /, it's a local upload
    // Convert to full URL using BASE_URL
    if (imagePath.startsWith('/')) {
        return `${API_BASE_URL}${imagePath}`;
    }
    
    // Otherwise, assume it's a relative path and prepend API_BASE_URL
    return `${API_BASE_URL}/${imagePath}`;
}

// ============================================================================
// DYNAMIC ATTRIBUTE LOADING FUNCTIONS
// ============================================================================

/**
 * Load origin countries dynamically from API
 */
async function loadOriginOptions() {
    try {
        console.log('🔄 Loading origin countries from API...');
        const url = `${API_BASE_URL}/api/attributes/origin_countries/values?hierarchical=true&active=true`;
        console.log('API URL:', url);
        
        const response = await fetch(url);
        console.log('Response status:', response.status);
        
        const data = await response.json();
        console.log('Response data:', data);
        
        if (!data.success) {
            console.error('❌ Failed to load origins:', data.message);
            return;
        }
        
        const select = document.getElementById('productOrigin');
        if (!select) {
            console.error('❌ productOrigin select element not found! Will retry after 500ms');
            // Retry once after a short delay — sometimes modal markup is injected after JS runs
            setTimeout(() => {
                const retrySelect = document.getElementById('productOrigin');
                if (!retrySelect) {
                    console.error('❌ Retry: productOrigin still not found. Aborting population.');
                    return;
                }

                // Clear existing options except placeholder
                retrySelect.innerHTML = '<option value="">Select origin...</option>';

                data.data.forEach(region => {
                    if (region.children && region.children.length > 0) {
                        const optgroup = document.createElement('optgroup');
                        optgroup.label = region.localizedName || (region.name && region.name.en) || region.value;

                        region.children.forEach(country => {
                            const option = document.createElement('option');
                            option.value = country.value;
                            const countryName = country.localizedName || (country.name && country.name.en) || country.value;
                            option.textContent = `${country.icon || ''} ${countryName}`.trim();
                            optgroup.appendChild(option);
                        });

                        retrySelect.appendChild(optgroup);
                    }
                });

                console.log(`✅ Retry: Loaded ${data.count || 0} origin regions with countries`);
            }, 500);
            return;
        }
        
        console.log('✅ Found select element, clearing and populating...');
        
        // Clear existing options except placeholder
        select.innerHTML = '<option value="">Select origin...</option>';
        
        // Group by parent (regions)
        data.data.forEach(region => {
            if (region.children && region.children.length > 0) {
                const optgroup = document.createElement('optgroup');
                optgroup.label = region.localizedName || (region.name && region.name.en) || region.value;
                
                region.children.forEach(country => {
                    const option = document.createElement('option');
                    option.value = country.value;
                    const countryName = country.localizedName || (country.name && country.name.en) || country.value;
                    option.textContent = `${country.icon || ''} ${countryName}`.trim();
                    optgroup.appendChild(option);
                });
                
                select.appendChild(optgroup);
            }
        });
        
        console.log(`✅ Loaded ${data.count || 0} origin regions with countries`);
    } catch (error) {
        console.error('❌ Error loading origin countries:', error);
    }
}

/**
 * Load roast levels dynamically from API
 */
async function loadRoastLevels() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/attributes/roast_levels/values?active=true`);
        const data = await response.json();
        
        if (!data.success) {
            console.error('Failed to load roast levels:', data.message);
            return;
        }
        
        const select = document.getElementById('productRoastLevel');
        if (!select) return;
        
        // Clear existing options except placeholder
        select.innerHTML = '<option value="">Select roast level...</option>';
        
        // Sort by display order
        const sortedValues = data.data.sort((a, b) => a.displayOrder - b.displayOrder);
        
        sortedValues.forEach(roast => {
            const option = document.createElement('option');
            option.value = roast.value;
            const roastName = roast.localizedName || (roast.name && roast.name.en) || roast.value;
            option.textContent = `${roast.icon || ''} ${roastName}`.trim();
            const description = roast.localizedDescription || (roast.description && roast.description.en);
            if (description) {
                option.title = description;
            }
            select.appendChild(option);
        });
        
        console.log('✅ Roast levels loaded dynamically');
    } catch (error) {
        console.error('Error loading roast levels:', error);
    }
}

/**
 * Load processing methods dynamically from API
 */
async function loadProcessingMethods() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/attributes/processing_methods/values?active=true`);
        const data = await response.json();
        
        if (!data.success) {
            console.error('Failed to load processing methods:', data.message);
            return;
        }
        
        const select = document.getElementById('productProcessing');
        if (!select) return;
        
        // Clear existing options except placeholder
        select.innerHTML = '<option value="">Select processing...</option>';
        
        // Sort by display order
        const sortedValues = data.data.sort((a, b) => a.displayOrder - b.displayOrder);
        
        sortedValues.forEach(method => {
            const option = document.createElement('option');
            option.value = method.value;
            const methodName = method.localizedName || (method.name && method.name.en) || method.value;
            option.textContent = methodName;
            const description = method.localizedDescription || (method.description && method.description.en);
            if (description) {
                option.title = description;
            }
            select.appendChild(option);
        });
        
        console.log('✅ Processing methods loaded dynamically');
    } catch (error) {
        console.error('Error loading processing methods:', error);
    }
}

/**
 * Load flavor profiles dynamically from API
 */
async function loadFlavorProfiles() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/attributes/flavor_profiles/values?active=true`);
        const data = await response.json();
        
        if (!data.success) {
            console.error('Failed to load flavor profiles:', data.message);
            return;
        }
        
        const container = document.querySelector('.flavor-grid');
        if (!container) return;
        
        // Clear existing checkboxes
        container.innerHTML = '';
        
        // Sort by display order
        const sortedValues = data.data.sort((a, b) => a.displayOrder - b.displayOrder);
        
        sortedValues.forEach(flavor => {
            const label = document.createElement('label');
            label.className = 'flavor-checkbox';
            label.style.color = flavor.color || '#333';
            const flavorName = flavor.localizedName || (flavor.name && flavor.name.en) || flavor.value;
            label.innerHTML = `
                <input type="checkbox" name="flavorProfile" value="${flavor.value}">
                <span class="flavor-label">
                    ${flavor.icon || ''} ${flavorName}
                </span>
            `;
            const description = flavor.localizedDescription || (flavor.description && flavor.description.en);
            if (description) {
                label.title = description;
            }
            container.appendChild(label);
        });
        
        console.log('✅ Flavor profiles loaded dynamically');
    } catch (error) {
        console.error('Error loading flavor profiles:', error);
    }
}

/**
 * Initialize all dynamic attributes
 * Call this when modal opens or page loads
 */
async function initializeDynamicAttributes() {
    console.log('� Initializing dynamic attributes...');
    console.log('API_BASE_URL:', typeof API_BASE_URL !== 'undefined' ? API_BASE_URL : 'UNDEFINED!');
    
    try {
        await Promise.all([
            loadOriginOptions(),
            loadRoastLevels(),
            loadProcessingMethods(),
            loadFlavorProfiles()
        ]);
        console.log('✅ All dynamic attributes loaded successfully');
    } catch (error) {
        console.error('❌ Error initializing dynamic attributes:', error);
    }
}

// ============================================================================
// PRODUCT MANAGEMENT FUNCTIONS
// ============================================================================

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
                            <img src="${getImageUrl(product.image)}" 
                                 alt="${product.name?.en || 'Product'}" 
                                 style="width: 60px; height: 60px; border-radius: 8px; object-fit: cover; box-shadow: 0 2px 4px rgba(0,0,0,0.1);"
                                 onerror="this.src='/assets/images/default-coffee.jpg'">
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
        showGlobalLoading('Loading product details...');
        const response = await authenticatedFetch(`${API_BASE_URL}/api/coffees/${productId}`);
        const data = await response.json();
        
        if (data.success) {
            showEditProductModal(data.data);
        } else {
            showToast('Failed to load product details', 'error');
        }
        hideGlobalLoading();
    } catch (error) {
        console.error('Error loading product:', error);
        showToast('Failed to load product details', 'error');
        hideGlobalLoading();
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

async function showEditProductModal(product) {
    // Store the product ID for later use
    window.currentEditProductId = product._id || product.id;
    
    // Load dynamic attributes first
    await initializeDynamicAttributes();
    
    // Helper functions
    const normalizeRoastLevel = (level) => {
        if (!level) return 'Medium';
        const normalized = level.toLowerCase();
        const mapping = {
            'light': 'Light',
            'medium-light': 'Medium-Light',
            'medium': 'Medium',
            'medium-dark': 'Medium-Dark',
            'dark': 'Dark'
        };
        return mapping[normalized] || 'Medium';
    };
    
    const setValue = (id, value) => {
        const element = document.getElementById(id);
        if (element) element.value = value || '';
    };
    
    const setChecked = (id, checked) => {
        const element = document.getElementById(id);
        if (element) element.checked = checked || false;
    };
    
    // Reset form first
    uploadedImages = [];
    selectedCategories = [];
    
    // Fill basic information (Tab 1)
    setValue('productName', product.name?.en || product.name || '');
    setValue('productNameAr', product.name?.ar || '');
    setValue('productDescription', product.description?.en || product.description || '');
    setValue('productDescriptionAr', product.description?.ar || '');
    setValue('productSlug', product.slug || '');
    setValue('productTags', Array.isArray(product.tags) ? product.tags.join(', ') : '');
    
    // Fill coffee attributes (Tab 3)
    setValue('productOrigin', product.origin || '');
    setValue('productRoastLevel', normalizeRoastLevel(product.roastLevel));
    setValue('productProcessing', product.processingMethod || '');
    setValue('productAltitude', product.altitude || '');
    setValue('productVariety', product.variety || '');
    setValue('productHarvest', product.harvestYear || '');
    setValue('productCuppingNotes', product.cuppingNotes || '');
    
    // Set flavor profiles
    if (Array.isArray(product.flavorProfile)) {
        document.querySelectorAll('input[name="flavorProfile"]').forEach(checkbox => {
            checkbox.checked = product.flavorProfile.includes(checkbox.value);
        });
    }
    
    // Set status checkboxes (Tab 4)
    setChecked('productIsActive', product.isActive !== false);
    setChecked('productIsFeatured', product.isFeatured || false);
    setChecked('productIsPremium', product.isPremium || false);
    
    // Handle categories - need to load them first then select
    if (product.categories && product.categories.length > 0) {
        // If categories are objects with names
        if (typeof product.categories[0] === 'object') {
            product.categories.forEach(cat => {
                selectedCategories.push({
                    id: cat._id || cat.id,
                    name: cat.name?.en || cat.localizedName || cat
                });
            });
        } else {
            // If categories are just IDs, we'll need to fetch category names
            // For now, store IDs
            product.categories.forEach(catId => {
                selectedCategories.push({
                    id: catId,
                    name: catId // Will be updated when categories load
                });
            });
        }
        updateSelectedCategoriesDisplay();
    }
    
    // Fill variants (Tab 2)
    if (product.variants && product.variants.length > 0) {
        product.variants.forEach(variant => {
            const sizeKey = variant.size.toLowerCase().replace('gm', 'gm');
            
            // Set values with both ID selectors
            setValue(`variant_${sizeKey}_price`, variant.price || 0);
            setValue(`variant_${sizeKey}_stock`, variant.stock || 0);
            setValue(`variant_${sizeKey}_desc_en`, variant.description?.en || '');
            setValue(`variant_${sizeKey}_desc_ar`, variant.description?.ar || '');
            setValue(`variant_${sizeKey}_sku`, variant.sku || '');
            
            // Make sure variant is active
            setChecked(`variant_${sizeKey}_active`, variant.isActive !== false);
        });
    }
    
    // Auto-generate SKUs
    autoGenerateSKU();
    
    // Show existing image if available (enhanced form uses multiple images)
    if (product.image) {
        const imagesPreview = document.getElementById('productImagesPreview');
        if (imagesPreview) {
            const imageItem = document.createElement('div');
            imageItem.className = 'preview-image-item main';
            const imageUrl = getImageUrl(product.image);
            imageItem.innerHTML = `
                <img src="${imageUrl}" alt="Product image" onerror="this.src='/assets/images/default-coffee.jpg'">
                <span class="main-badge">Main</span>
            `;
            imagesPreview.appendChild(imageItem);
            
            // Add to uploadedImages array (as URL reference for preview)
            uploadedImages.push({
                file: null,
                url: product.image,
                isMain: true,
                existing: true
            });
        }
    }
    
    // Change modal title and button text
    const modalTitle = document.getElementById('modalTitle');
    const createBtn = document.getElementById('createProductBtn');
    if (modalTitle) modalTitle.textContent = '✏️ Edit Product';
    if (createBtn) createBtn.innerHTML = '<i class="fas fa-save"></i> Update Product';
    
    // Show the modal and switch to basic tab
    document.getElementById('productModal').style.display = 'flex';
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

async function showAddProductModal() {
    // Clear any edit product ID
    window.currentEditProductId = null;
    
    // Reset enhanced form state
    uploadedImages = [];
    selectedCategories = [];
    
    // Load dynamic attributes first
    await initializeDynamicAttributes();
    
    // Open modal
    const modal = document.getElementById('productModal');
    if (modal) {
        modal.style.display = 'flex';
    }
    
    // Reset form
    const form = document.getElementById('productCreationForm');
    if (form) {
        form.reset();
    }
    
    // Clear image preview
    const imagesPreview = document.getElementById('productImagesPreview');
    if (imagesPreview) {
        imagesPreview.innerHTML = '';
    }
    
    // Update modal title
    const modalTitle = document.getElementById('modalTitle');
    if (modalTitle) {
        modalTitle.textContent = '☕ Create New Product';
    }
    
    // Update button text
    const createBtn = document.getElementById('createProductBtn');
    if (createBtn) {
        createBtn.innerHTML = '<i class="fas fa-check"></i> Publish Product';
    }
    
    // Switch to first tab
    switchProductTab('basic');
    
    // Reset product variants
    resetProductVariants();
    
    // Initialize pricing validation
    setTimeout(() => {
        validatePricing();
    }, 100);
}

function closeProductModal() {
    document.getElementById('productModal').style.display = 'none';
}

function resetProductVariants() {
    // Helper function to safely set value
    const setValueSafe = (selector, value) => {
        const element = document.querySelector(selector);
        if (element) {
            element.value = value;
        }
    };
    
    // Reset prices
    setValueSafe('input[name="variant_250gm_price"]', '45.00');
    setValueSafe('#variant_250gm_price', '45.00');
    setValueSafe('input[name="variant_500gm_price"]', '85.00');
    setValueSafe('#variant_500gm_price', '85.00');
    setValueSafe('input[name="variant_1kg_price"]', '155.00');
    setValueSafe('#variant_1kg_price', '155.00');
    
    // Reset stock
    setValueSafe('input[name="variant_250gm_stock"]', '100');
    setValueSafe('#variant_250gm_stock', '100');
    setValueSafe('input[name="variant_500gm_stock"]', '100');
    setValueSafe('#variant_500gm_stock', '100');
    setValueSafe('input[name="variant_1kg_stock"]', '50');
    setValueSafe('#variant_1kg_stock', '50');
    
    // Reset descriptions
    setValueSafe('input[name="variant_250gm_desc_en"]', 'Perfect for trying new flavors');
    setValueSafe('#variant_250gm_desc_en', 'Perfect for trying new flavors');
    setValueSafe('input[name="variant_250gm_desc_ar"]', 'مثالية لتجربة النكهات الجديدة');
    setValueSafe('#variant_250gm_desc_ar', 'مثالية لتجربة النكهات الجديدة');
    
    setValueSafe('input[name="variant_500gm_desc_en"]', 'Perfect for regular consumption');
    setValueSafe('#variant_500gm_desc_en', 'Perfect for regular consumption');
    setValueSafe('input[name="variant_500gm_desc_ar"]', 'مثالية للاستهلاك المنتظم');
    setValueSafe('#variant_500gm_desc_ar', 'مثالية للاستهلاك المنتظم');
    
    setValueSafe('input[name="variant_1kg_desc_en"]', 'Best value for coffee enthusiasts');
    setValueSafe('#variant_1kg_desc_en', 'Best value for coffee enthusiasts');
    setValueSafe('input[name="variant_1kg_desc_ar"]', 'أفضل قيمة لعشاق القهوة');
    setValueSafe('#variant_1kg_desc_ar', 'أفضل قيمة لعشاق القهوة');
    
    // Enable all variants by default
    const variant250Active = document.getElementById('variant_250gm_active');
    const variant500Active = document.getElementById('variant_500gm_active');
    const variant1kgActive = document.getElementById('variant_1kg_active');
    
    if (variant250Active) variant250Active.checked = true;
    if (variant500Active) variant500Active.checked = true;
    if (variant1kgActive) variant1kgActive.checked = true;
    
    // Show all variant contents
    ['250gm', '500gm', '1kg'].forEach(size => {
        const content = document.getElementById(`variant_${size}_content`);
        if (content) {
            content.style.display = 'block';
        }
        const card = document.querySelector(`#variant_${size}_content`)?.closest('.variant-card');
        if (card) {
            card.classList.remove('inactive');
        }
    });
}

// Preview product image before upload
function previewProductImage(event) {
    const file = event.target.files[0];
    const preview = document.getElementById('productImagePreview');
    
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

// Handle product form submission
async function handleProductSubmit(event) {
    event.preventDefault();
    
    const form = event.target;
    const isEditing = window.currentEditProductId ? true : false;
    const productId = window.currentEditProductId;
    
    // Get form values with fallbacks
    const getName = (id) => document.getElementById(id)?.value || '';
    const getChecked = (id) => document.getElementById(id)?.checked || false;
    
    // Auto-generate slug if empty (prevents "required field not focusable" error)
    const slugField = document.getElementById('productSlug');
    if (!slugField.value || slugField.value.trim() === '') {
        autoGenerateSlug();
    }
    
    // Get basic product data from enhanced form
    const productData = {
        name: getName('productName'),
        nameAr: getName('productNameAr') || getName('productName'),
        description: getName('productDescription'),
        descriptionAr: getName('productDescriptionAr') || getName('productDescription'),
        origin: getName('productOrigin') || 'Unknown',
        roastLevel: getName('productRoastLevel') || 'Medium',
        isActive: getChecked('productIsActive'),
        isFeatured: getChecked('productIsFeatured'),
        isPremium: getChecked('productIsPremium') || false,
        
        // Get selected categories from enhanced form
        categories: selectedCategories.map(cat => cat.id),
        
        // Additional coffee attributes
        processingMethod: getName('productProcessing'),
        altitude: parseInt(getName('productAltitude')) || null,
        variety: getName('productVariety'),
        harvestYear: parseInt(getName('productHarvest')) || null,
        cuppingNotes: getName('productCuppingNotes'),
        
        // Flavor profiles
        flavorProfile: Array.from(document.querySelectorAll('input[name="flavorProfile"]:checked'))
            .map(cb => cb.value),
        
        // SEO fields
        slug: getName('productSlug'),
        tags: getName('productTags').split(',').map(tag => tag.trim()).filter(tag => tag),
        
        // Build variants array (only include active variants)
        variants: [],
        
        // Set default price from first active variant
        price: 0,
        stock: 0
    };
    
    // Build variants based on active toggles
    ['250gm', '500gm', '1kg'].forEach(size => {
        const isActive = document.getElementById(`variant_${size}_active`)?.checked;
        if (isActive) {
            const variant = {
                size: size,
                sku: getName(`variant_${size}_sku`),
                price: parseFloat(getName(`variant_${size}_price`)) || 0,
                stock: parseInt(getName(`variant_${size}_stock`)) || 0,
                description: {
                    en: getName(`variant_${size}_desc_en`),
                    ar: getName(`variant_${size}_desc_ar`)
                },
                isActive: true
            };
            productData.variants.push(variant);
            
            // Set default price from first variant
            if (productData.price === 0) {
                productData.price = variant.price;
                productData.stock = variant.stock;
            }
        }
    });
    
    try {
        // Validate required fields
        if (!productData.name || !productData.description) {
            showToast('Please fill in required fields (Product Name and Description)', 'error');
            // Switch to Basic Info tab to show missing fields
            switchProductTab('basic');
            // Focus on the first empty required field
            if (!productData.name) {
                document.getElementById('productName')?.focus();
            } else if (!productData.description) {
                document.getElementById('productDescription')?.focus();
            }
            return;
        }
        
        if (productData.variants.length === 0) {
            showToast('Please enable at least one variant', 'error');
            // Switch to Pricing tab to enable variants
            switchProductTab('pricing');
            return;
        }
        
        // Create FormData to send both images and product data
        const formData = new FormData();
        
        // Add multiple images if provided (from enhanced form)
        if (uploadedImages && uploadedImages.length > 0) {
            uploadedImages.forEach((imgData, index) => {
                formData.append('images', imgData.file);
                if (index === 0) {
                    // First image is main image
                    formData.append('image', imgData.file);
                }
            });
        } else {
            // Fallback to old single image input
            const imageFile = document.getElementById('productImage')?.files[0];
            if (imageFile) {
                formData.append('image', imageFile);
            }
        }
        
        // Add all product data as form fields
        // Backend expects 'nameEn' and 'descriptionEn'
        formData.append('nameEn', productData.name);
        formData.append('nameAr', productData.nameAr);
        formData.append('descriptionEn', productData.description);
        formData.append('descriptionAr', productData.descriptionAr);
        formData.append('origin', productData.origin);
        formData.append('roastLevel', productData.roastLevel);
        formData.append('isActive', productData.isActive);
        formData.append('isFeatured', productData.isFeatured);
        formData.append('isPremium', productData.isPremium);
        formData.append('price', productData.price);
        formData.append('stock', productData.stock);
        
        // Add optional coffee attributes
        if (productData.processingMethod) {
            formData.append('processingMethod', productData.processingMethod);
        }
        if (productData.altitude) {
            formData.append('altitude', productData.altitude);
        }
        if (productData.variety) {
            formData.append('variety', productData.variety);
        }
        if (productData.harvestYear) {
            formData.append('harvestYear', productData.harvestYear);
        }
        if (productData.cuppingNotes) {
            formData.append('cuppingNotes', productData.cuppingNotes);
        }
        if (productData.slug) {
            formData.append('slug', productData.slug);
        }
        
        // Add arrays as JSON strings
        if (productData.categories && productData.categories.length > 0) {
            formData.append('categories', JSON.stringify(productData.categories));
        }
        
        if (productData.flavorProfile && productData.flavorProfile.length > 0) {
            formData.append('flavorProfile', JSON.stringify(productData.flavorProfile));
        }
        
        if (productData.tags && productData.tags.length > 0) {
            formData.append('tags', JSON.stringify(productData.tags));
        }
        
        // Add variants as JSON string
        formData.append('variants', JSON.stringify(productData.variants));
        
        // Log the data being sent
        console.log('=== Submitting Product ===');
        console.log('Mode:', isEditing ? 'EDIT' : 'CREATE');
        console.log('Product ID:', productId);
        console.log('Product Data:', productData);
        console.log('FormData entries:');
        for (let pair of formData.entries()) {
            console.log(`  ${pair[0]}: ${pair[1]}`);
        }
        console.log('========================');
        
        // Create or update the product with image in a single request
        const url = isEditing 
            ? `${API_BASE_URL}/api/coffees/${productId}` 
            : `${API_BASE_URL}/api/coffees`;
        
        const method = isEditing ? 'PUT' : 'POST';
        
        const response = await authenticatedFetch(url, {
            method: method,
            body: formData
            // Note: Don't set Content-Type header, browser will set it with boundary for multipart/form-data
        });
        
        const data = await response.json();
        
        if (data.success) {
            showToast(isEditing ? 'Product updated successfully!' : 'Product created successfully!', 'success');
            closeProductModal();
            loadProducts();
            // Clear the edit product ID
            window.currentEditProductId = null;
        } else {
            console.error('Server error response:', data);
            console.error('Validation errors:', data.errors);
            const errorMsg = data.errors 
                ? data.errors.map(e => `${e.path || e.param}: ${e.msg || e.message}`).join(', ')
                : data.message || 'Unknown error';
            showToast(`Failed to ${isEditing ? 'update' : 'create'} product: ${errorMsg}`, 'error');
        }
    } catch (error) {
        console.error(`Error ${isEditing ? 'updating' : 'creating'} product:`, error);
        showToast(`Error ${isEditing ? 'updating' : 'creating'} product. Please try again.`, 'error');
    }
}

/* ===== ENHANCED PRODUCT FORM FUNCTIONS ===== */

// Global variables for enhanced form
let uploadedImages = [];
let selectedCategories = [];
let allCategories = [];

// Tab switching function
function switchProductTab(tabName) {
    // Hide all tab contents
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Remove active class from all tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    
    // Show selected tab content
    const selectedTab = document.getElementById(`tab-${tabName}`);
    if (selectedTab) {
        selectedTab.classList.add('active');
    }
    
    // Add active class to clicked tab button
    const activeBtn = Array.from(document.querySelectorAll('.tab-btn')).find(btn => 
        btn.textContent.toLowerCase().includes(tabName)
    );
    if (activeBtn) {
        activeBtn.classList.add('active');
    }
    
    // If switching to preview tab, generate preview
    if (tabName === 'preview') {
        generateProductPreview();
    }
    
    // If switching to categories tab, load categories
    if (tabName === 'categories' && allCategories.length === 0) {
        loadCategoriesForSelection();
    }
}

// Multiple images preview
function previewProductImages(event) {
    const files = Array.from(event.target.files);
    const previewContainer = document.getElementById('productImagesPreview');
    
    files.forEach((file, index) => {
        const reader = new FileReader();
        reader.onload = function(e) {
            const imageData = {
                file: file,
                url: e.target.result,
                isMain: uploadedImages.length === 0 && index === 0
            };
            uploadedImages.push(imageData);
            
            const imageItem = document.createElement('div');
            imageItem.className = `preview-image-item ${imageData.isMain ? 'main' : ''}`;
            imageItem.innerHTML = `
                <img src="${e.target.result}" alt="Product image">
                <button type="button" class="remove-btn" onclick="removeProductImage(${uploadedImages.length - 1})">×</button>
                ${imageData.isMain ? '<span class="main-badge">Main</span>' : ''}
            `;
            previewContainer.appendChild(imageItem);
        };
        reader.readAsDataURL(file);
    });
}

// Remove uploaded image
function removeProductImage(index) {
    uploadedImages.splice(index, 1);
    
    // Re-render images
    const previewContainer = document.getElementById('productImagesPreview');
    previewContainer.innerHTML = '';
    
    uploadedImages.forEach((img, i) => {
        img.isMain = i === 0; // First image is always main
        const imageItem = document.createElement('div');
        imageItem.className = `preview-image-item ${img.isMain ? 'main' : ''}`;
        const imageUrl = getImageUrl(img.url);
        imageItem.innerHTML = `
            <img src="${imageUrl}" alt="Product image" onerror="this.src='/assets/images/default-coffee.jpg'">
            <button type="button" class="remove-btn" onclick="removeProductImage(${i})">×</button>
            ${img.isMain ? '<span class="main-badge">Main</span>' : ''}
        `;
        previewContainer.appendChild(imageItem);
    });
}

// Auto-generate SEO slug
function autoGenerateSlug() {
    const productName = document.getElementById('productName').value;
    const slugField = document.getElementById('productSlug');
    
    if (productName && slugField) {
        const slug = productName
            .toLowerCase()
            .replace(/[^\w\s-]/g, '')
            .replace(/\s+/g, '-')
            .replace(/-+/g, '-')
            .trim();
        slugField.value = slug;
    }
}

// Auto-generate SKU
function autoGenerateSKU() {
    const origin = document.getElementById('productOrigin').value;
    const roast = document.getElementById('productRoastLevel').value;
    const baseSKUField = document.getElementById('productBaseSKU');
    
    if (origin && roast && baseSKUField) {
        const originCode = origin.substring(0, 3).toUpperCase();
        const roastCode = roast.replace('-', '').substring(0, 3).toUpperCase();
        const baseSKU = `COF-${originCode}-${roastCode}`;
        baseSKUField.value = baseSKU;
        
        // Update variant SKUs
        ['250gm', '500gm', '1kg'].forEach(size => {
            const variantSKUField = document.getElementById(`variant_${size}_sku`);
            if (variantSKUField) {
                variantSKUField.value = `${baseSKU}-${size.toUpperCase()}`;
            }
        });
    }
}

// Rich text formatting
function formatText(command) {
    document.execCommand(command, false, null);
}

// Handle tags input
document.addEventListener('DOMContentLoaded', function() {
    const tagsInput = document.getElementById('productTags');
    if (tagsInput) {
        tagsInput.addEventListener('blur', function() {
            updateTagsDisplay();
        });
    }
});

function updateTagsDisplay() {
    const tagsInput = document.getElementById('productTags');
    const tagsDisplay = document.getElementById('tagsDisplay');
    
    if (tagsInput && tagsDisplay) {
        const tags = tagsInput.value.split(',').map(tag => tag.trim()).filter(tag => tag);
        tagsDisplay.innerHTML = tags.map((tag, index) => `
            <span class="tag-item">
                ${tag}
                <span class="remove-tag" onclick="removeTag(${index})">×</span>
            </span>
        `).join('');
    }
}

function removeTag(index) {
    const tagsInput = document.getElementById('productTags');
    if (tagsInput) {
        const tags = tagsInput.value.split(',').map(tag => tag.trim()).filter(tag => tag);
        tags.splice(index, 1);
        tagsInput.value = tags.join(', ');
        updateTagsDisplay();
    }
}

// Toggle variant active state
function toggleVariant(size) {
    const checkbox = document.getElementById(`variant_${size}_active`);
    const content = document.getElementById(`variant_${size}_content`);
    
    if (!checkbox || !content) return;
    
    const card = content.closest('.variant-card');
    
    if (checkbox.checked) {
        content.style.display = 'block';
        if (card) card.classList.remove('inactive');
    } else {
        content.style.display = 'none';
        if (card) card.classList.add('inactive');
    }
    
    validatePricing();
}

// Pricing validation
function validatePricing() {
    const price250 = parseFloat(document.getElementById('variant_250gm_price')?.value || 0);
    const price500 = parseFloat(document.getElementById('variant_500gm_price')?.value || 0);
    const price1kg = parseFloat(document.getElementById('variant_1kg_price')?.value || 0);
    
    const pricingAlert = document.getElementById('pricingAlert');
    const pricingAlertText = document.getElementById('pricingAlertText');
    
    // Only validate if elements exist
    if (!pricingAlert || !pricingAlertText) {
        updatePricingSummary(price250, price500, price1kg);
        return;
    }
    
    // Check if 1kg is cheaper than 2x500g (bulk discount)
    const twoX500g = price500 * 2;
    
    if (price1kg > 0 && price500 > 0) {
        if (price1kg >= twoX500g) {
            pricingAlert.className = 'pricing-validation-alert error';
            pricingAlert.style.display = 'flex';
            pricingAlertText.textContent = `Warning: 1kg price (AED ${price1kg}) should be less than 2x500g (AED ${twoX500g.toFixed(2)}) to offer bulk discount!`;
        } else {
            const savings = twoX500g - price1kg;
            const savingsPercent = ((savings / twoX500g) * 100).toFixed(1);
            pricingAlert.className = 'pricing-validation-alert success';
            pricingAlert.style.display = 'flex';
            pricingAlertText.textContent = `✓ Great! Bulk discount: AED ${savings.toFixed(2)} (${savingsPercent}% savings) on 1kg pack`;
        }
    } else {
        pricingAlert.style.display = 'none';
    }
    
    updatePricingSummary(price250, price500, price1kg);
}

// Low stock warning
function checkLowStock(size) {
    const stockField = document.getElementById(`variant_${size}_stock`);
    const warning = document.getElementById(`stock_warning_${size}`);
    
    if (stockField && warning) {
        const stock = parseInt(stockField.value || 0);
        if (stock < 10) {
            warning.textContent = '⚠️ Low stock alert!';
            warning.classList.add('show');
        } else {
            warning.classList.remove('show');
        }
    }
}

// Update pricing summary
function updatePricingSummary(price250, price500, price1kg) {
    const summary = document.getElementById('pricingSummaryContent');
    if (summary) {
        summary.innerHTML = `
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; font-size: 14px;">
                <div>
                    <strong>250gm:</strong> AED ${price250.toFixed(2)}<br>
                    <small>Per 100g: AED ${(price250/2.5).toFixed(2)}</small>
                </div>
                <div>
                    <strong>500gm:</strong> AED ${price500.toFixed(2)}<br>
                    <small>Per 100g: AED ${(price500/5).toFixed(2)}</small>
                </div>
                <div>
                    <strong>1kg:</strong> AED ${price1kg.toFixed(2)}<br>
                    <small>Per 100g: AED ${(price1kg/10).toFixed(2)}</small>
                </div>
                <div style="background: #f0f0f0; padding: 10px; border-radius: 6px;">
                    <strong>Best Value:</strong><br>
                    ${price1kg/10 < price500/5 && price1kg/10 < price250/2.5 ? '1kg Pack 🏆' : 
                      price500/5 < price250/2.5 ? '500gm Pack 🥈' : '250gm Pack'}
                </div>
            </div>
        `;
    }
}

// Load categories for selection
async function loadCategoriesForSelection() {
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/categories`);
        const data = await response.json();
        
        if (data.success && data.data) {
            allCategories = data.data;
            renderCategorySelectors();
        }
    } catch (error) {
        console.error('Error loading categories:', error);
    }
}

// Render category selectors by type
function renderCategorySelectors() {
    const originContainer = document.getElementById('originCategories');
    const roastContainer = document.getElementById('roastCategories');
    const beanTypeContainer = document.getElementById('beanTypeCategories');
    
    // Categorize by name patterns
    const originCategories = allCategories.filter(cat => 
        ['Asia', 'Africa', 'Latin America', 'Africa', 'Middle East'].includes(cat.name?.en)
    );
    
    const roastCategories = allCategories.filter(cat => 
        cat.name?.en?.includes('Roast')
    );
    
    const beanTypeCategories = allCategories.filter(cat => 
        ['Single Origin', 'Blends', 'Organic', 'Decaf', 'Blend'].includes(cat.name?.en)
    );
    
    // Render each group
    if (originContainer) {
        originContainer.innerHTML = originCategories.map(cat => `
            <label>
                <input type="checkbox" value="${cat._id}" onchange="toggleCategory('${cat._id}', '${cat.name?.en || cat.localizedName}', this.checked)">
                <span>${cat.name?.en || cat.localizedName}</span>
            </label>
        `).join('');
    }
    
    if (roastContainer) {
        roastContainer.innerHTML = roastCategories.map(cat => `
            <label>
                <input type="checkbox" value="${cat._id}" onchange="toggleCategory('${cat._id}', '${cat.name?.en || cat.localizedName}', this.checked)">
                <span>${cat.name?.en || cat.localizedName}</span>
            </label>
        `).join('');
    }
    
    if (beanTypeContainer) {
        beanTypeContainer.innerHTML = beanTypeCategories.map(cat => `
            <label>
                <input type="checkbox" value="${cat._id}" onchange="toggleCategory('${cat._id}', '${cat.name?.en || cat.localizedName}', this.checked)">
                <span>${cat.name?.en || cat.localizedName}</span>
            </label>
        `).join('');
    }
}

// Toggle category selection
function toggleCategory(categoryId, categoryName, isChecked) {
    if (isChecked) {
        if (!selectedCategories.find(c => c.id === categoryId)) {
            selectedCategories.push({ id: categoryId, name: categoryName });
        }
    } else {
        selectedCategories = selectedCategories.filter(c => c.id !== categoryId);
    }
    
    updateSelectedCategoriesDisplay();
}

// Update selected categories display
function updateSelectedCategoriesDisplay() {
    const display = document.getElementById('selectedCategoriesDisplay');
    if (display) {
        if (selectedCategories.length === 0) {
            display.innerHTML = '<span class="no-categories">No categories selected yet</span>';
        } else {
            display.innerHTML = selectedCategories.map(cat => `
                <span class="category-tag">
                    ${cat.name}
                    <span class="remove-category" onclick="removeCategorySelection('${cat.id}')">×</span>
                </span>
            `).join('');
        }
    }
}

// Remove category from selection
function removeCategorySelection(categoryId) {
    selectedCategories = selectedCategories.filter(c => c.id !== categoryId);
    
    // Uncheck the checkbox
    const checkbox = document.querySelector(`input[type="checkbox"][value="${categoryId}"]`);
    if (checkbox) {
        checkbox.checked = false;
    }
    
    updateSelectedCategoriesDisplay();
}

// Generate product preview
function generateProductPreview() {
    const previewContainer = document.getElementById('productPreview');
    if (!previewContainer) return;
    
    const name = document.getElementById('productName')?.value || 'Product Name';
    const description = document.getElementById('productDescription')?.value || 'No description provided';
    const price250 = parseFloat(document.getElementById('variant_250gm_price')?.value || 0);
    const origin = document.getElementById('productOrigin')?.value || 'Unknown';
    const roast = document.getElementById('productRoastLevel')?.value || 'Medium';
    const isPremium = document.getElementById('productIsPremium')?.checked || false;
    const isFeatured = document.getElementById('productIsFeatured')?.checked || false;
    
    // Use placeholder image if no images uploaded - simple data URL
    const placeholderImage = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="400" height="400"%3E%3Crect fill="%23ddd" width="400" height="400"/%3E%3Ctext fill="%23999" font-family="Arial" font-size="40" x="50%25" y="50%25" text-anchor="middle" dy=".3em"%3ECoffee Image%3C/text%3E%3C/svg%3E';
    const mainImage = uploadedImages.length > 0 ? uploadedImages[0].url : placeholderImage;
    
    // Get selected flavor profiles
    const flavorChecks = document.querySelectorAll('input[name="flavorProfile"]:checked');
    const flavors = Array.from(flavorChecks).map(cb => cb.value);
    
    if (previewContainer) {
        previewContainer.innerHTML = `
            <img src="${mainImage}" alt="${name}" class="preview-image-main">
            <h3 class="preview-title">${name}</h3>
            <p class="preview-price">From AED ${price250.toFixed(2)}</p>
            
            <div class="preview-badges">
                ${isPremium ? '<span class="preview-badge premium">✨ Premium</span>' : ''}
                ${isFeatured ? '<span class="preview-badge">⭐ Featured</span>' : ''}
                <span class="preview-badge">${origin}</span>
                <span class="preview-badge">${roast} Roast</span>
                ${flavors.map(f => `<span class="preview-badge">${f}</span>`).join('')}
            </div>
            
            <p class="preview-description">${description}</p>
            
            <div style="margin-top: 20px;">
                <h4>Selected Categories:</h4>
                <div class="preview-badges">
                    ${selectedCategories.map(cat => `<span class="preview-badge">${cat.name}</span>`).join('')}
                </div>
            </div>
            
            <div style="margin-top: 20px; padding: 15px; background: #f9f9f9; border-radius: 8px;">
                <h4>Available Sizes:</h4>
                ${document.getElementById('variant_250gm_active')?.checked ? 
                    `<div style="margin: 10px 0;">📦 250gm - AED ${price250.toFixed(2)}</div>` : ''}
                ${document.getElementById('variant_500gm_active')?.checked ? 
                    `<div style="margin: 10px 0;">📦 500gm - AED ${parseFloat(document.getElementById('variant_500gm_price')?.value || 0).toFixed(2)}</div>` : ''}
                ${document.getElementById('variant_1kg_active')?.checked ? 
                    `<div style="margin: 10px 0;">📦 1kg - AED ${parseFloat(document.getElementById('variant_1kg_price')?.value || 0).toFixed(2)}</div>` : ''}
            </div>
        `;
    }
}

// Save product as draft
function saveProductDraft() {
    showToast('Draft save functionality coming soon!', 'info');
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    // Add event listeners for pricing inputs
    ['250gm', '500gm', '1kg'].forEach(size => {
        const priceInput = document.getElementById(`variant_${size}_price`);
        if (priceInput) {
            priceInput.addEventListener('input', validatePricing);
        }
        
        const stockInput = document.getElementById(`variant_${size}_stock`);
        if (stockInput) {
            stockInput.addEventListener('input', () => checkLowStock(size));
        }
    });
    
    // Add event listener for tags input
    const tagsInput = document.getElementById('productTags');
    if (tagsInput) {
        tagsInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                updateTagsDisplay();
            }
        });
    }

    // Ensure dynamic attributes are initialized on page load so selects are populated
    try {
        console.log('🔁 Calling initializeDynamicAttributes() on DOMContentLoaded');
        initializeDynamicAttributes();
    } catch (err) {
        console.error('Failed to initialize dynamic attributes on load:', err);
    }
});
