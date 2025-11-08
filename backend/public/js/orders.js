/* Orders Management Module */

async function loadOrders() {
    try {
        showLoading('ordersTable');
        
        const status = document.getElementById('orderStatusFilter')?.value || '';
        const url = status ? `${API_BASE_URL}/api/admin/orders?status=${status}` : `${API_BASE_URL}/api/admin/orders`;
        
        const response = await authenticatedFetch(url);
        const data = await response.json();

        if (data.success) {
            // Handle different response structures
            const ordersData = data.data?.orders || data.data || [];
            const ordersArray = Array.isArray(ordersData) ? ordersData : [];
            
            renderOrdersTable(ordersArray);
            
            if (data.stats) {
                updateOrderStats(data.stats);
            }
        }
    } catch (error) {
        const logger = window.adminUtils?.logger || console;
        logger.error('Error loading orders:', error);
        showErrorById('ordersTable', 'Failed to load orders. Please try again.');
    }
}

function renderOrdersTable(orders) {
    // Ensure orders is an array
    const ordersArray = Array.isArray(orders) ? orders : [];
    
    if (ordersArray.length === 0) {
        document.getElementById('ordersTable').innerHTML = `
            <div class="empty-state">
                <i class="fas fa-shopping-cart"></i>
                <h3>No Orders Yet</h3>
                <p>Orders will appear here when customers place them</p>
            </div>
        `;
        return;
    }

    const tableHTML = `
        <table class="data-table">
            <thead>
                <tr>
                    <th>Order ID</th>
                    <th>Customer</th>
                    <th>Items</th>
                    <th>Total</th>
                    <th>Status</th>
                    <th>Date</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                ${ordersArray.map(order => `
                    <tr>
                        <td>#${order._id?.slice(-8) || 'N/A'}</td>
                        <td>
                            <strong>${order.user?.name || 'Unknown'}</strong><br>
                            <small>${order.user?.email || ''}</small>
                        </td>
                        <td>${order.items?.length || 0} items</td>
                        <td>AED ${order.totalAmount?.toFixed(2) || '0.00'}</td>
                        <td>
                            <select class="form-control" onchange="updateOrderStatus('${order._id}', this.value)" style="width: auto; font-size: 0.8rem;">
                                <option value="pending" ${order.status === 'pending' ? 'selected' : ''}>Pending</option>
                                <option value="confirmed" ${order.status === 'confirmed' ? 'selected' : ''}>Confirmed</option>
                                <option value="preparing" ${order.status === 'preparing' ? 'selected' : ''}>Preparing</option>
                                <option value="ready" ${order.status === 'ready' ? 'selected' : ''}>Ready</option>
                                <option value="delivered" ${order.status === 'delivered' ? 'selected' : ''}>Delivered</option>
                                <option value="cancelled" ${order.status === 'cancelled' ? 'selected' : ''}>Cancelled</option>
                            </select>
                        </td>
                        <td>${new Date(order.createdAt).toLocaleDateString()}</td>
                        <td>
                            <button class="btn btn-info btn-sm" onclick="viewOrderDetails('${order._id}')">
                                <i class="fas fa-eye"></i>
                            </button>
                        </td>
                    </tr>
                `).join('')}
            </tbody>
        </table>
    `;
    document.getElementById('ordersTable').innerHTML = tableHTML;
}

function updateOrderStats(stats) {
    document.getElementById('pendingOrders').textContent = stats?.pending || '0';
    document.getElementById('preparingOrders').textContent = stats?.preparing || '0';
    document.getElementById('completedOrders').textContent = stats?.completed || '0';
    document.getElementById('todayRevenue').textContent = `AED ${stats?.todayRevenue?.toFixed(2) || '0.00'}`;
}

async function updateOrderStatus(orderId, newStatus) {
    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/orders/${orderId}/status`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ status: newStatus })
        });

        const data = await response.json();
        if (data.success) {
            showToast('Order status updated successfully', 'success');
            loadOrders();
        } else {
            alert('Failed to update order status');
        }
    } catch (error) {
        console.error('Error updating order status:', error);
        alert('Failed to update order status');
    }
}

async function viewOrder(orderId) {
    await viewOrderDetails(orderId);
}

async function viewOrderDetails(orderId) {
    try {
        showLoading('ordersTable');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/orders/${orderId}`);
        const data = await response.json();

        if (data.success) {
            const order = data.data;
            renderOrderDetailsModal(order);
        } else {
            showToast('Failed to load order details', 'error');
            loadOrders();
        }
    } catch (error) {
        console.error('Error loading order details:', error);
        showToast('Failed to load order details', 'error');
        loadOrders();
    }
}

function renderOrderDetailsModal(order) {
    const modalHTML = `
        <div class="modal-overlay" id="orderDetailsModal" onclick="closeOrderDetails(event)">
            <div class="modal-container" onclick="event.stopPropagation()">
                <div class="modal-header">
                    <h2><i class="fas fa-receipt"></i> Order Details - #${order._id?.slice(-8)}</h2>
                    <button class="close-btn" onclick="closeOrderDetails()">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
                
                <div class="modal-body" style="max-height: 70vh; overflow-y: auto;">
                    <!-- Order Status -->
                    <div class="order-section">
                        <h3>Order Status</h3>
                        <div class="status-badge status-${order.status}">
                            ${order.status.toUpperCase()}
                        </div>
                        <p><strong>Order Date:</strong> ${new Date(order.createdAt).toLocaleString()}</p>
                        ${order.updatedAt !== order.createdAt ? `<p><strong>Last Updated:</strong> ${new Date(order.updatedAt).toLocaleString()}</p>` : ''}
                    </div>

                    <!-- Customer Information -->
                    <div class="order-section">
                        <h3><i class="fas fa-user"></i> Customer Information</h3>
                        <p><strong>Name:</strong> ${order.user?.name || order.customerName || 'N/A'}</p>
                        <p><strong>Email:</strong> ${order.user?.email || order.customerEmail || 'N/A'}</p>
                        <p><strong>Phone:</strong> ${order.user?.phone || order.customerPhone || 'N/A'}</p>
                    </div>

                    <!-- Delivery Information -->
                    ${order.deliveryAddress ? `
                    <div class="order-section">
                        <h3><i class="fas fa-map-marker-alt"></i> Delivery Address</h3>
                        <p>${order.deliveryAddress.street || ''}</p>
                        <p>${order.deliveryAddress.city || ''}, ${order.deliveryAddress.state || ''} ${order.deliveryAddress.zipCode || ''}</p>
                        <p>${order.deliveryAddress.country || 'UAE'}</p>
                        ${order.deliveryAddress.deliveryInstructions ? `<p><strong>Instructions:</strong> ${order.deliveryAddress.deliveryInstructions}</p>` : ''}
                    </div>
                    ` : ''}

                    <!-- Order Items -->
                    <div class="order-section">
                        <h3><i class="fas fa-shopping-bag"></i> Order Items</h3>
                        <table class="items-table">
                            <thead>
                                <tr>
                                    <th>Product</th>
                                    <th>Quantity</th>
                                    <th>Price</th>
                                    <th>Subtotal</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${order.items?.map(item => `
                                    <tr>
                                        <td>
                                            <strong>${item.product?.name || item.productName || 'Unknown Product'}</strong>
                                            ${item.variant ? `<br><small>Variant: ${item.variant}</small>` : ''}
                                            ${item.grindType ? `<br><small>Grind: ${item.grindType}</small>` : ''}
                                        </td>
                                        <td>${item.quantity || 1}</td>
                                        <td>AED ${(item.price || 0).toFixed(2)}</td>
                                        <td>AED ${((item.price || 0) * (item.quantity || 1)).toFixed(2)}</td>
                                    </tr>
                                `).join('') || '<tr><td colspan="4">No items</td></tr>'}
                            </tbody>
                        </table>
                    </div>

                    <!-- Payment Summary -->
                    <div class="order-section">
                        <h3><i class="fas fa-credit-card"></i> Payment Summary</h3>
                        <table class="summary-table">
                            <tr>
                                <td>Subtotal:</td>
                                <td>AED ${(order.subtotal || 0).toFixed(2)}</td>
                            </tr>
                            ${order.discount ? `
                            <tr>
                                <td>Discount:</td>
                                <td>-AED ${(order.discount || 0).toFixed(2)}</td>
                            </tr>
                            ` : ''}
                            ${order.deliveryFee ? `
                            <tr>
                                <td>Delivery Fee:</td>
                                <td>AED ${(order.deliveryFee || 0).toFixed(2)}</td>
                            </tr>
                            ` : ''}
                            ${order.taxAmount ? `
                            <tr>
                                <td>Tax (${order.taxRate || 5}%):</td>
                                <td>AED ${(order.taxAmount || 0).toFixed(2)}</td>
                            </tr>
                            ` : ''}
                            <tr class="total-row">
                                <td><strong>Total:</strong></td>
                                <td><strong>AED ${(order.totalAmount || 0).toFixed(2)}</strong></td>
                            </tr>
                        </table>
                        <p><strong>Payment Method:</strong> ${order.paymentMethod || 'N/A'}</p>
                        <p><strong>Payment Status:</strong> <span class="status-badge status-${order.paymentStatus || 'pending'}">${(order.paymentStatus || 'pending').toUpperCase()}</span></p>
                    </div>

                    <!-- Order Notes -->
                    ${order.notes ? `
                    <div class="order-section">
                        <h3><i class="fas fa-sticky-note"></i> Order Notes</h3>
                        <p>${order.notes}</p>
                    </div>
                    ` : ''}

                    <!-- Driver Information -->
                    ${order.driver ? `
                    <div class="order-section">
                        <h3><i class="fas fa-truck"></i> Driver Information</h3>
                        <p><strong>Name:</strong> ${order.driver.name || 'N/A'}</p>
                        <p><strong>Phone:</strong> ${order.driver.phone || 'N/A'}</p>
                    </div>
                    ` : ''}
                </div>

                <div class="modal-footer">
                    <button class="btn btn-secondary" onclick="closeOrderDetails()">Close</button>
                    <button class="btn btn-primary" onclick="printOrder('${order._id}')">
                        <i class="fas fa-print"></i> Print
                    </button>
                </div>
            </div>
        </div>

        <style>
            .modal-overlay {
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(0, 0, 0, 0.7);
                display: flex;
                align-items: center;
                justify-content: center;
                z-index: 9999;
            }
            .modal-container {
                background: white;
                border-radius: 8px;
                width: 90%;
                max-width: 800px;
                max-height: 90vh;
                display: flex;
                flex-direction: column;
            }
            .modal-header {
                padding: 20px;
                border-bottom: 1px solid #e0e0e0;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }
            .modal-header h2 {
                margin: 0;
                font-size: 1.5rem;
                color: #333;
            }
            .close-btn {
                background: none;
                border: none;
                font-size: 1.5rem;
                cursor: pointer;
                color: #666;
            }
            .close-btn:hover {
                color: #333;
            }
            .modal-body {
                padding: 20px;
                overflow-y: auto;
            }
            .modal-footer {
                padding: 20px;
                border-top: 1px solid #e0e0e0;
                display: flex;
                justify-content: flex-end;
                gap: 10px;
            }
            .order-section {
                margin-bottom: 25px;
                padding-bottom: 20px;
                border-bottom: 1px solid #f0f0f0;
            }
            .order-section:last-child {
                border-bottom: none;
            }
            .order-section h3 {
                color: #333;
                margin-bottom: 15px;
                font-size: 1.1rem;
            }
            .order-section p {
                margin: 8px 0;
                color: #666;
            }
            .status-badge {
                display: inline-block;
                padding: 6px 12px;
                border-radius: 4px;
                font-size: 0.85rem;
                font-weight: bold;
                margin: 10px 0;
            }
            .status-pending { background: #fff3cd; color: #856404; }
            .status-confirmed { background: #cfe2ff; color: #084298; }
            .status-preparing { background: #cff4fc; color: #055160; }
            .status-ready { background: #d1e7dd; color: #0f5132; }
            .status-delivered { background: #d1e7dd; color: #0f5132; }
            .status-cancelled { background: #f8d7da; color: #842029; }
            .status-paid { background: #d1e7dd; color: #0f5132; }
            .status-failed { background: #f8d7da; color: #842029; }
            .items-table {
                width: 100%;
                border-collapse: collapse;
                margin-top: 10px;
            }
            .items-table th,
            .items-table td {
                padding: 12px;
                text-align: left;
                border-bottom: 1px solid #e0e0e0;
            }
            .items-table th {
                background: #f8f9fa;
                font-weight: 600;
                color: #333;
            }
            .items-table tbody tr:hover {
                background: #f8f9fa;
            }
            .summary-table {
                width: 100%;
                margin-top: 10px;
            }
            .summary-table td {
                padding: 8px 0;
            }
            .summary-table td:last-child {
                text-align: right;
            }
            .summary-table .total-row {
                border-top: 2px solid #333;
                padding-top: 12px;
            }
            .summary-table .total-row td {
                padding-top: 12px;
                font-size: 1.1rem;
            }
        </style>
    `;

    // Remove any existing modal
    const existingModal = document.getElementById('orderDetailsModal');
    if (existingModal) {
        existingModal.remove();
    }

    // Add modal to body
    document.body.insertAdjacentHTML('beforeend', modalHTML);
}

function closeOrderDetails(event) {
    if (event && event.target !== event.currentTarget) return;
    
    const modal = document.getElementById('orderDetailsModal');
    if (modal) {
        modal.remove();
    }
    
    // Reload orders table
    loadOrders();
}

function printOrder(orderId) {
    showToast('Print functionality coming soon', 'info');
}
