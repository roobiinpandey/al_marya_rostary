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
        
        // FIXED: Use the proper analytics dashboard endpoint instead of individual endpoints
        const analyticsRes = await authenticatedFetch(`${API_BASE_URL}/api/analytics/admin/dashboard`);
        const analyticsData = await analyticsRes.json();
        
        if (analyticsData.success) {
            const data = analyticsData.data;
            
            // Use data from analytics endpoint
            const totalUsers = data.totalUsers || 0;
            const totalProducts = data.totalProducts || 0;
            const totalOrders = data.totalOrders || 0;
            const totalRevenue = data.totalRevenue || 0;
            const completedOrders = data.orderStats?.delivered || 0;
            
            document.getElementById('dashboardStats').innerHTML = `
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-icon">☕</div>
                        <div class="stat-info">
                            <h3>${totalProducts}</h3>
                            <p>Total Products</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">📦</div>
                        <div class="stat-info">
                            <h3>${totalOrders}</h3>
                            <p>Total Orders</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">👥</div>
                        <div class="stat-info">
                            <h3>${totalUsers}</h3>
                            <p>Total Users</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">💰</div>
                        <div class="stat-info">
                            <h3>AED ${totalRevenue.toFixed(2)}</h3>
                            <p>Total Revenue</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">✅</div>
                        <div class="stat-info">
                            <h3>${completedOrders}</h3>
                            <p>Delivered Orders</p>
                        </div>
                    </div>
                </div>
            `;
            
            console.log('✅ Dashboard stats updated:', {
                totalUsers, totalProducts, totalOrders, totalRevenue, completedOrders
            });
        } else {
            throw new Error('Analytics API returned error: ' + (analyticsData.message || 'Unknown error'));
        }
        
        hideGlobalLoading();
        
    } catch (error) {
        console.error('Error loading dashboard statistics:', error);
        showToast('Failed to load dashboard statistics', 'error');
        
        // Hide global loading even on error
        hideGlobalLoading();
        
        // Show error in dashboard stats area
        document.getElementById('dashboardStats').innerHTML = `
            <div class="text-center" style="padding: 2rem; color: var(--danger);">
                <i class="fas fa-exclamation-triangle" style="font-size: 2rem; margin-bottom: 1rem;"></i>
                <p>Unable to load dashboard statistics</p>
                <button class="btn btn-primary" onclick="renderDashboardStats()">Try Again</button>
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

/* Reports Functions */
let reportChart = null;

async function loadReportData() {
    try {
        const reportType = document.getElementById('reportType').value;
        const dateRange = document.getElementById('reportDateRange').value;
        const startDate = document.getElementById('reportStartDate').value;
        const endDate = document.getElementById('reportEndDate').value;

        showGlobalLoading('Generating report...');

        let endpoint = `${API_BASE_URL}/api/analytics/admin/dashboard`;
        const analyticsRes = await authenticatedFetch(endpoint);
        const analyticsData = await analyticsRes.json();

        if (analyticsData.success) {
            renderReportSummary(reportType, analyticsData.data);
            renderReportChart(reportType, analyticsData.data);
            renderReportTable(reportType, analyticsData.data);
        } else {
            showToast('Failed to generate report', 'error');
        }

        hideGlobalLoading();
    } catch (error) {
        console.error('Error loading report data:', error);
        showToast('Error generating report: ' + error.message, 'error');
        hideGlobalLoading();
    }
}

function renderReportSummary(reportType, data) {
    const summaryElement = document.getElementById('reportSummary');
    
    let summaryHTML = '';
    
    switch(reportType) {
        case 'sales':
            summaryHTML = `
                <div class="stats-grid" style="grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));">
                    <div class="stat-card">
                        <div class="stat-icon">💰</div>
                        <div class="stat-info">
                            <h3>AED ${(data.totalRevenue || 0).toFixed(2)}</h3>
                            <p>Total Sales</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">📦</div>
                        <div class="stat-info">
                            <h3>${data.totalOrders || 0}</h3>
                            <p>Total Orders</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">📊</div>
                        <div class="stat-info">
                            <h3>AED ${data.totalOrders > 0 ? (data.totalRevenue / data.totalOrders).toFixed(2) : '0.00'}</h3>
                            <p>Average Order Value</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">✅</div>
                        <div class="stat-info">
                            <h3>${data.orderStats?.delivered || 0}</h3>
                            <p>Completed Orders</p>
                        </div>
                    </div>
                </div>
            `;
            break;
        case 'products':
            summaryHTML = `
                <div class="stats-grid" style="grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));">
                    <div class="stat-card">
                        <div class="stat-icon">☕</div>
                        <div class="stat-info">
                            <h3>${data.totalProducts || 0}</h3>
                            <p>Total Products</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">📈</div>
                        <div class="stat-info">
                            <h3>${data.topProducts?.length || 0}</h3>
                            <p>Top Selling Products</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">🏷️</div>
                        <div class="stat-info">
                            <h3>${data.totalCategories || 0}</h3>
                            <p>Product Categories</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">⭐</div>
                        <div class="stat-info">
                            <h3>${(data.averageRating || 0).toFixed(1)}</h3>
                            <p>Average Rating</p>
                        </div>
                    </div>
                </div>
            `;
            break;
        case 'customers':
            summaryHTML = `
                <div class="stats-grid" style="grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));">
                    <div class="stat-card">
                        <div class="stat-icon">👥</div>
                        <div class="stat-info">
                            <h3>${data.totalUsers || 0}</h3>
                            <p>Total Customers</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">🆕</div>
                        <div class="stat-info">
                            <h3>${data.newUsers || 0}</h3>
                            <p>New This Month</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">🔄</div>
                        <div class="stat-info">
                            <h3>${data.returningCustomers || 0}</h3>
                            <p>Returning Customers</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">💎</div>
                        <div class="stat-info">
                            <h3>${data.loyaltyMembers || 0}</h3>
                            <p>Loyalty Members</p>
                        </div>
                    </div>
                </div>
            `;
            break;
        case 'revenue':
            summaryHTML = `
                <div class="stats-grid" style="grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));">
                    <div class="stat-card">
                        <div class="stat-icon">💰</div>
                        <div class="stat-info">
                            <h3>AED ${(data.totalRevenue || 0).toFixed(2)}</h3>
                            <p>Total Revenue</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">📈</div>
                        <div class="stat-info">
                            <h3>AED ${(data.monthlyRevenue || 0).toFixed(2)}</h3>
                            <p>This Month</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">📊</div>
                        <div class="stat-info">
                            <h3>${data.growthRate || 0}%</h3>
                            <p>Growth Rate</p>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon">🎯</div>
                        <div class="stat-info">
                            <h3>AED ${(data.projectedRevenue || 0).toFixed(2)}</h3>
                            <p>Projected (Year)</p>
                        </div>
                    </div>
                </div>
            `;
            break;
    }
    
    summaryElement.innerHTML = summaryHTML;
}

function renderReportChart(reportType, data) {
    const ctx = document.getElementById('reportChart').getContext('2d');
    
    if (reportChart) {
        reportChart.destroy();
    }

    let chartData = {
        labels: [],
        datasets: []
    };

    switch(reportType) {
        case 'sales':
            chartData = {
                labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                datasets: [{
                    label: 'Sales (AED)',
                    data: data.monthlySales || [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                    backgroundColor: 'rgba(168, 154, 106, 0.2)',
                    borderColor: '#A89A6A',
                    borderWidth: 2
                }]
            };
            break;
        case 'products':
            const topProducts = data.topProducts || [];
            chartData = {
                labels: topProducts.map(p => p.name || 'Unknown').slice(0, 10),
                datasets: [{
                    label: 'Units Sold',
                    data: topProducts.map(p => p.soldCount || 0).slice(0, 10),
                    backgroundColor: 'rgba(168, 154, 106, 0.6)',
                    borderColor: '#A89A6A',
                    borderWidth: 1
                }]
            };
            break;
        case 'customers':
            chartData = {
                labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                datasets: [{
                    label: 'New Customers',
                    data: data.monthlyNewUsers || [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                    backgroundColor: 'rgba(75, 192, 192, 0.2)',
                    borderColor: 'rgb(75, 192, 192)',
                    borderWidth: 2
                }]
            };
            break;
        case 'revenue':
            chartData = {
                labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                datasets: [{
                    label: 'Revenue (AED)',
                    data: data.monthlyRevenue || [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                    backgroundColor: 'rgba(139, 69, 19, 0.2)',
                    borderColor: '#8B4513',
                    borderWidth: 2,
                    fill: true
                }]
            };
            break;
    }

    reportChart = new Chart(ctx, {
        type: reportType === 'products' ? 'bar' : 'line',
        data: chartData,
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                title: {
                    display: true,
                    text: getReportTitle(reportType)
                },
                legend: {
                    display: true,
                    position: 'top'
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

function renderReportTable(reportType, data) {
    const tableElement = document.getElementById('reportTable');
    
    let tableHTML = '';
    
    switch(reportType) {
        case 'sales':
            const orders = data.recentOrders || [];
            tableHTML = `
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Order ID</th>
                            <th>Customer</th>
                            <th>Amount</th>
                            <th>Status</th>
                            <th>Date</th>
                            <th>Items</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${orders.length > 0 ? orders.map(order => `
                            <tr>
                                <td>#${order._id?.slice(-8) || 'N/A'}</td>
                                <td>${order.user?.name || 'Unknown'}</td>
                                <td>AED ${(order.totalAmount || 0).toFixed(2)}</td>
                                <td><span class="status-badge status-${order.status}">${order.status || 'pending'}</span></td>
                                <td>${new Date(order.createdAt).toLocaleDateString()}</td>
                                <td>${order.items?.length || 0}</td>
                            </tr>
                        `).join('') : '<tr><td colspan="6" class="text-center">No orders found</td></tr>'}
                    </tbody>
                </table>
            `;
            break;
        case 'products':
            const products = data.topProducts || [];
            tableHTML = `
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Product Name</th>
                            <th>Category</th>
                            <th>Price</th>
                            <th>Units Sold</th>
                            <th>Revenue</th>
                            <th>Rating</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${products.length > 0 ? products.map(product => `
                            <tr>
                                <td>${product.name || 'Unknown'}</td>
                                <td>${product.category || 'N/A'}</td>
                                <td>AED ${(product.price || 0).toFixed(2)}</td>
                                <td>${product.soldCount || 0}</td>
                                <td>AED ${((product.price || 0) * (product.soldCount || 0)).toFixed(2)}</td>
                                <td>⭐ ${(product.rating || 0).toFixed(1)}</td>
                            </tr>
                        `).join('') : '<tr><td colspan="6" class="text-center">No products found</td></tr>'}
                    </tbody>
                </table>
            `;
            break;
        case 'customers':
            tableHTML = `
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Customer Name</th>
                            <th>Email</th>
                            <th>Total Orders</th>
                            <th>Total Spent</th>
                            <th>Join Date</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr><td colspan="6" class="text-center">Customer details report coming soon</td></tr>
                    </tbody>
                </table>
            `;
            break;
        case 'revenue':
            tableHTML = `
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Month</th>
                            <th>Revenue</th>
                            <th>Orders</th>
                            <th>Avg Order Value</th>
                            <th>Growth</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'].map((month, index) => {
                            const revenue = (data.monthlyRevenue && data.monthlyRevenue[index]) || 0;
                            const orders = (data.monthlyOrders && data.monthlyOrders[index]) || 0;
                            const avgValue = orders > 0 ? revenue / orders : 0;
                            return `
                            <tr>
                                <td>${month}</td>
                                <td>AED ${revenue.toFixed(2)}</td>
                                <td>${orders}</td>
                                <td>AED ${avgValue.toFixed(2)}</td>
                                <td>${index > 0 ? '+0%' : '-'}</td>
                            </tr>
                        `}).join('')}
                    </tbody>
                </table>
            `;
            break;
    }
    
    tableElement.innerHTML = tableHTML;
}

function getReportTitle(reportType) {
    const titles = {
        'sales': 'Sales Trend Analysis',
        'products': 'Top Performing Products',
        'customers': 'Customer Growth Trend',
        'revenue': 'Revenue Performance'
    };
    return titles[reportType] || 'Report';
}

function exportReport() {
    const reportType = document.getElementById('reportType').value;
    const dateRange = document.getElementById('reportDateRange').value;
    
    showToast('Exporting report to Excel...', 'info');
    
    // Create a simple CSV export
    const table = document.querySelector('#reportTable table');
    if (!table) {
        showToast('No data to export', 'warning');
        return;
    }
    
    let csv = [];
    const rows = table.querySelectorAll('tr');
    
    rows.forEach(row => {
        const cols = row.querySelectorAll('td, th');
        const rowData = [];
        cols.forEach(col => {
            rowData.push(col.innerText);
        });
        csv.push(rowData.join(','));
    });
    
    const csvContent = csv.join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${reportType}_report_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    
    showToast('Report exported successfully', 'success');
}

function printReport() {
    const reportContent = document.getElementById('reports-tab').innerHTML;
    const printWindow = window.open('', '', 'height=600,width=800');
    
    printWindow.document.write('<html><head><title>Print Report</title>');
    printWindow.document.write('<style>');
    printWindow.document.write('body { font-family: Arial, sans-serif; padding: 20px; }');
    printWindow.document.write('table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
    printWindow.document.write('th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }');
    printWindow.document.write('th { background-color: #A89A6A; color: white; }');
    printWindow.document.write('.stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; margin: 20px 0; }');
    printWindow.document.write('.stat-card { border: 1px solid #ddd; padding: 15px; text-align: center; }');
    printWindow.document.write('.report-filters, button { display: none; }');
    printWindow.document.write('canvas { display: none; }');
    printWindow.document.write('</style></head><body>');
    printWindow.document.write('<h1>Almaryah Rostery - Business Report</h1>');
    printWindow.document.write('<p>Generated: ' + new Date().toLocaleString() + '</p>');
    printWindow.document.write(reportContent);
    printWindow.document.write('</body></html>');
    
    printWindow.document.close();
    printWindow.focus();
    
    setTimeout(() => {
        printWindow.print();
        printWindow.close();
    }, 250);
    
    showToast('Preparing report for printing...', 'info');
}
