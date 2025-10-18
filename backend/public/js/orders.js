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

function viewOrder(orderId) {
    showToast('Order details feature coming soon', 'info');
}

function viewOrderDetails(orderId) {
    showToast('Order details feature coming soon', 'info');
}
