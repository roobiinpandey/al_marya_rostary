/* Dashboard Functions Module */

async function loadDashboardData() {
    try {
        showLoading('dashboardStats');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/analytics/admin/dashboard`);
        const data = await handleApiResponse(response);

        if (data.success) {
            renderDashboardStats();
            renderRevenueChart(data.data.revenueData);
            renderRecentOrders(data.data.recentOrders);
        }
    } catch (error) {
        console.warn('Dashboard data not available:', error.message);
        renderDashboardStats();
        
        if (error.message.includes('Authentication required')) {
            showErrorById('dashboardStats', 'Please login to view dashboard data');
        } else {
            showErrorById('dashboardStats', 'Dashboard data unavailable - Backend service starting up');
        }
    }
}

async function renderDashboardStats() {
    try {
        showGlobalLoading('Loading dashboard statistics...');
        
        const [productsRes, ordersRes, usersRes] = await Promise.all([
            authenticatedFetch(`${API_BASE_URL}/api/coffees`),
            authenticatedFetch(`${API_BASE_URL}/api/admin/orders`),
            authenticatedFetch(`${API_BASE_URL}/api/admin/users`)
        ]);
        
        const productsData = await productsRes.json();
        const ordersData = await ordersRes.json();
        const usersData = await usersRes.json();
        
        const products = productsData.success ? (productsData.data || []) : [];
        const orders = ordersData.success ? (ordersData.data || []) : [];
        const users = usersData.success ? (usersData.data || []) : [];
        
        const ordersArray = Array.isArray(orders) ? orders : [];
        const totalRevenue = ordersArray.reduce((sum, order) => sum + (order.total || 0), 0);
        const completedOrders = ordersArray.filter(o => o.status === 'completed').length;
    
        document.getElementById('dashboardStats').innerHTML = `
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon">💰</div>
                    <div class="stat-info">
                        <h3>AED ${totalRevenue}</h3>
                        <p>Total Revenue</p>
                    </div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon">📦</div>
                    <div class="stat-info">
                        <h3>${ordersArray.length}</h3>
                        <p>Total Orders</p>
                    </div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon">👥</div>
                    <div class="stat-info">
                        <h3>${users.length}</h3>
                        <p>Total Users</p>
                    </div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon">☕</div>
                    <div class="stat-info">
                        <h3>${products.length}</h3>
                        <p>Products</p>
                    </div>
                </div>
            </div>
        `;
        
        // Hide global loading after successful render
        hideGlobalLoading();
        
    } catch (error) {
        console.error('Error loading dashboard statistics:', error);
        showToast('Failed to load dashboard statistics', 'error');
        
        // Hide global loading even on error
        hideGlobalLoading();
        
        document.getElementById('dashboardStats').innerHTML = `
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon">❌</div>
                    <div class="stat-info">
                        <h3>Error</h3>
                        <p>Failed to load statistics</p>
                    </div>
                </div>
            </div>
        `;
    }
}

function renderRevenueChart(revenueData) {
    const ctx = document.getElementById('revenueChart').getContext('2d');
    
    if (charts.revenue) {
        charts.revenue.destroy();
    }

    charts.revenue = new Chart(ctx, {
        type: 'line',
        data: {
            labels: revenueData?.labels || ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
            datasets: [{
                label: 'Revenue (AED)',
                data: revenueData?.values || [1000, 1500, 2000, 1800, 2200, 2500],
                borderColor: '#A89A6A',
                backgroundColor: 'rgba(139, 69, 19, 0.1)',
                borderWidth: 3,
                fill: true
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                title: {
                    display: true,
                    text: 'Monthly Revenue Trend'
                }
            },
            scales: {
                y: {
                    beginAtZero: true
                }
            }
        }
    });
}

function renderRecentOrders(orders) {
    if (!orders || orders.length === 0) {
        document.querySelector('#recentOrdersTable').innerHTML = '<p class="text-center">No recent orders found.</p>';
        return;
    }

    const tableHTML = `
        <table class="data-table">
            <thead>
                <tr>
                    <th>Order ID</th>
                    <th>Customer</th>
                    <th>Amount</th>
                    <th>Status</th>
                    <th>Date</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                ${orders.map(order => `
                    <tr>
                        <td>#${order._id?.slice(-8) || 'N/A'}</td>
                        <td>${order.user?.name || 'Unknown'}</td>
                        <td>AED ${order.totalAmount?.toFixed(2) || '0.00'}</td>
                        <td><span class="status-badge status-${order.status || 'pending'}">${order.status || 'Pending'}</span></td>
                        <td>${new Date(order.createdAt).toLocaleDateString()}</td>
                        <td>
                            <button class="btn btn-info btn-sm" onclick="viewOrder('${order._id}')">
                                <i class="fas fa-eye"></i>
                            </button>
                        </td>
                    </tr>
                `).join('')}
            </tbody>
        </table>
    `;
    document.querySelector('#recentOrdersTable').innerHTML = tableHTML;
}
