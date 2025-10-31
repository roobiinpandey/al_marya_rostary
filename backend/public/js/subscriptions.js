/**
 * Subscriptions Management JavaScript
 * Handles admin functionality for subscription management
 */

const subscriptionsManager = {
    currentPage: 1,
    pageSize: 20,
    subscriptions: [],

    async init() {
        await this.loadSubscriptionStats();
        await this.loadSubscriptions();
    },

    async loadSubscriptionStats() {
        try {
            showLoading('Loading subscription statistics...');
            
            const stats = await this.fetchSubscriptionStats();
            
            document.getElementById('activeSubscriptions').textContent = stats.activeSubscriptions || 0;
            document.getElementById('monthlyRecurringRevenue').textContent = `AED ${this.formatNumber(stats.mrr || 0)}`;
            document.getElementById('pausedSubscriptions').textContent = stats.pausedSubscriptions || 0;
            document.getElementById('retentionRate').textContent = `${stats.retentionRate || 0}%`;
            
        } catch (error) {
            console.error('Error loading subscription stats:', error);
            showToast('Failed to load subscription statistics', 'error');
        } finally {
            hideLoading();
        }
    },

    async loadSubscriptions() {
        try {
            showLoading('Loading subscriptions...');
            
            const filter = document.getElementById('subscriptionStatusFilter').value;
            const subscriptions = await this.fetchSubscriptions(filter);
            this.subscriptions = subscriptions;
            this.renderSubscriptionsTable(subscriptions);
            
        } catch (error) {
            console.error('Error loading subscriptions:', error);
            showToast('Failed to load subscriptions', 'error');
        } finally {
            hideLoading();
        }
    },

    async fetchSubscriptionStats() {
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/subscriptions/admin/stats`);
            const data = await response.json();
            
            if (data.success) {
                return {
                    activeSubscriptions: data.data.activeSubscriptions || 0,
                    mrr: data.data.mrr || 0,
                    pausedSubscriptions: data.data.pausedSubscriptions || 0,
                    cancelledSubscriptions: data.data.cancelledSubscriptions || 0,
                    retentionRate: data.data.retentionRate || 0
                };
            }
            
            throw new Error(data.message || 'Failed to fetch stats');
        } catch (error) {
            console.error('Error fetching subscription stats:', error);
            return {
                activeSubscriptions: 0,
                mrr: 0,
                pausedSubscriptions: 0,
                cancelledSubscriptions: 0,
                retentionRate: 0
            };
        }
    },

    async fetchSubscriptions(filter = '') {
        try {
            const params = new URLSearchParams();
            if (filter) params.append('status', filter);
            params.append('limit', '50');
            
            const response = await authenticatedFetch(`${API_BASE_URL}/api/subscriptions/admin/list?${params}`);
            const data = await response.json();
            
            if (data.success && data.data && Array.isArray(data.data.subscriptions)) {
                return data.data.subscriptions.map(subscription => ({
                    _id: subscription._id,
                    userId: subscription.userId,
                    userName: subscription.userName,
                    userEmail: subscription.userEmail,
                    productId: subscription.productId,
                    productName: subscription.productName,
                    productSize: subscription.productSize,
                    frequency: subscription.frequency,
                    frequencyDisplay: subscription.frequencyDisplay,
                    quantity: subscription.quantity,
                    subscriptionPrice: subscription.subscriptionPrice,
                    status: subscription.status,
                    nextDelivery: subscription.nextDelivery ? new Date(subscription.nextDelivery) : null,
                    startDate: subscription.startDate ? new Date(subscription.startDate) : null,
                    totalDeliveries: subscription.totalDeliveries || 0,
                    totalAmount: subscription.totalAmount || 0,
                    pauseReason: subscription.pauseReason,
                    pausedUntil: subscription.pausedUntil ? new Date(subscription.pausedUntil) : null,
                    cancellationReason: subscription.cancellationReason,
                    cancelledAt: subscription.cancelledAt ? new Date(subscription.cancelledAt) : null,
                    createdAt: subscription.createdAt ? new Date(subscription.createdAt) : null
                }));
            }
            
            // Return empty array if no subscriptions found
            console.log('No subscriptions data available - showing empty state');
            return [];
        } catch (error) {
            console.error('Error fetching subscriptions:', error);
            // Don't show toast for empty state, just return empty array
            return [];
        }
    },

    renderSubscriptionsTable(subscriptions) {
        // Show message if no subscriptions
        if (!subscriptions || subscriptions.length === 0) {
            document.getElementById('subscriptionsTable').innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-calendar-times" style="font-size: 48px; color: #ccc; margin-bottom: 16px;"></i>
                    <h3>No Subscriptions Yet</h3>
                    <p>Subscription orders will appear here once customers create recurring deliveries.</p>
                    <p style="margin-top: 16px; color: #666;">
                        <i class="fas fa-info-circle"></i> 
                        Customers can subscribe to regular coffee deliveries from the mobile app.
                    </p>
                </div>
            `;
            return;
        }
        

        const tableHtml = `
            <div class="table-responsive">
                <table class="admin-table">
                    <thead>
                        <tr>
                            <th>Customer</th>
                            <th>Product</th>
                            <th>Frequency</th>
                            <th>Price</th>
                            <th>Status</th>
                            <th>Next Delivery</th>
                            <th>Total Orders</th>
                            <th>Revenue</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${subscriptions.map(subscription => this.renderSubscriptionRow(subscription)).join('')}
                    </tbody>
                </table>
            </div>
        `;
        
        document.getElementById('subscriptionsTable').innerHTML = tableHtml;
    },

    renderSubscriptionRow(subscription) {
        const statusBadge = this.getStatusBadge(subscription.status);
        const nextDelivery = this.getNextDeliveryDisplay(subscription);
        
        return `
            <tr>
                <td>
                    <div class="user-info">
                        <strong>${subscription.userName}</strong><br>
                        <small>${subscription.userEmail}</small>
                    </div>
                </td>
                <td>
                    <div class="product-info">
                        <strong>${subscription.productName}</strong><br>
                        <small>${subscription.productSize} × ${subscription.quantity}</small>
                    </div>
                </td>
                <td>
                    <span class="frequency-badge">${subscription.frequencyDisplay}</span>
                </td>
                <td>
                    <strong>AED ${subscription.subscriptionPrice}</strong>
                </td>
                <td>${statusBadge}</td>
                <td>${nextDelivery}</td>
                <td>
                    <span class="stat-number">${subscription.totalDeliveries}</span>
                </td>
                <td>
                    <strong>AED ${this.formatNumber(subscription.totalAmount)}</strong>
                </td>
                <td>
                    <div class="action-buttons">
                        <button class="btn btn-info btn-sm" onclick="subscriptionsManager.viewSubscriptionDetail('${subscription._id}')" title="View Details">
                            <i class="fas fa-eye"></i>
                        </button>
                        ${subscription.status === 'active' ? `
                            <button class="btn btn-warning btn-sm" onclick="subscriptionsManager.pauseSubscription('${subscription._id}')" title="Pause">
                                <i class="fas fa-pause"></i>
                            </button>
                        ` : ''}
                        ${subscription.status === 'paused' ? `
                            <button class="btn btn-success btn-sm" onclick="subscriptionsManager.resumeSubscription('${subscription._id}')" title="Resume">
                                <i class="fas fa-play"></i>
                            </button>
                        ` : ''}
                        ${subscription.status !== 'cancelled' ? `
                            <button class="btn btn-danger btn-sm" onclick="subscriptionsManager.cancelSubscription('${subscription._id}')" title="Cancel">
                                <i class="fas fa-times"></i>
                            </button>
                        ` : ''}
                        <button class="btn btn-secondary btn-sm" onclick="subscriptionsManager.viewDeliveryHistory('${subscription._id}')" title="Delivery History">
                            <i class="fas fa-history"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    },

    getStatusBadge(status) {
        const badges = {
            active: '<span class="badge badge-success">Active</span>',
            paused: '<span class="badge badge-warning">Paused</span>',
            cancelled: '<span class="badge badge-danger">Cancelled</span>',
            expired: '<span class="badge badge-secondary">Expired</span>'
        };
        return badges[status] || '<span class="badge badge-secondary">Unknown</span>';
    },

    getNextDeliveryDisplay(subscription) {
        if (subscription.status === 'cancelled') {
            return '<span class="text-muted">Cancelled</span>';
        }
        if (subscription.status === 'paused') {
            if (subscription.pausedUntil) {
                return `<span class="text-warning">Paused until ${this.formatDate(subscription.pausedUntil)}</span>`;
            }
            return '<span class="text-warning">Paused</span>';
        }
        if (subscription.nextDelivery) {
            const daysUntil = Math.ceil((new Date(subscription.nextDelivery) - new Date()) / (1000 * 60 * 60 * 24));
            if (daysUntil < 0) {
                return '<span class="text-danger">Overdue</span>';
            } else if (daysUntil === 0) {
                return '<span class="text-warning">Today</span>';
            } else if (daysUntil === 1) {
                return '<span class="text-info">Tomorrow</span>';
            } else {
                return `<span class="text-info">In ${daysUntil} days</span>`;
            }
        }
        return '<span class="text-muted">Not scheduled</span>';
    },

    viewSubscriptionDetail(subscriptionId) {
        const subscription = this.subscriptions.find(s => s._id === subscriptionId);
        if (!subscription) {
            showToast('Subscription not found', 'error');
            return;
        }
        
        const modalHtml = `
            <div class="modal-backdrop" onclick="this.remove()">
                <div class="modal-content large" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h3>Subscription Details - ${subscription.userName}</h3>
                        <button class="modal-close" onclick="this.closest('.modal-backdrop').remove()">×</button>
                    </div>
                    <div class="modal-body">
                        <div class="subscription-detail">
                            <div class="detail-grid">
                                <div class="detail-section">
                                    <h4>Customer Information</h4>
                                    <p><strong>Name:</strong> ${subscription.userName}</p>
                                    <p><strong>Email:</strong> ${subscription.userEmail}</p>
                                    <p><strong>Customer ID:</strong> ${subscription.userId}</p>
                                </div>
                                
                                <div class="detail-section">
                                    <h4>Subscription Details</h4>
                                    <p><strong>Product:</strong> ${subscription.productName}</p>
                                    <p><strong>Size:</strong> ${subscription.productSize}</p>
                                    <p><strong>Quantity:</strong> ${subscription.quantity}</p>
                                    <p><strong>Frequency:</strong> ${subscription.frequencyDisplay}</p>
                                    <p><strong>Price per delivery:</strong> AED ${subscription.subscriptionPrice}</p>
                                </div>
                                
                                <div class="detail-section">
                                    <h4>Status & Schedule</h4>
                                    <p><strong>Status:</strong> ${this.getStatusBadge(subscription.status)}</p>
                                    <p><strong>Start Date:</strong> ${this.formatDate(subscription.startDate)}</p>
                                    ${subscription.status === 'active' ? `
                                        <p><strong>Next Delivery:</strong> ${this.formatDate(subscription.nextDelivery)}</p>
                                    ` : ''}
                                    ${subscription.status === 'paused' ? `
                                        <p><strong>Pause Reason:</strong> ${subscription.pauseReason || 'Not specified'}</p>
                                        ${subscription.pausedUntil ? `<p><strong>Resume Date:</strong> ${this.formatDate(subscription.pausedUntil)}</p>` : ''}
                                    ` : ''}
                                    ${subscription.status === 'cancelled' ? `
                                        <p><strong>Cancelled Date:</strong> ${this.formatDate(subscription.cancelledAt)}</p>
                                        <p><strong>Cancellation Reason:</strong> ${subscription.cancellationReason || 'Not specified'}</p>
                                    ` : ''}
                                </div>
                                
                                <div class="detail-section">
                                    <h4>Performance</h4>
                                    <p><strong>Total Deliveries:</strong> ${subscription.totalDeliveries}</p>
                                    <p><strong>Total Revenue:</strong> AED ${this.formatNumber(subscription.totalAmount)}</p>
                                    <p><strong>Average per Delivery:</strong> AED ${this.formatNumber(subscription.totalAmount / (subscription.totalDeliveries || 1))}</p>
                                    <p><strong>Subscription Duration:</strong> ${this.calculateDuration(subscription.startDate)}</p>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        ${subscription.status === 'active' ? `
                            <button class="btn btn-warning" onclick="subscriptionsManager.pauseSubscription('${subscription._id}')">Pause Subscription</button>
                        ` : ''}
                        ${subscription.status === 'paused' ? `
                            <button class="btn btn-success" onclick="subscriptionsManager.resumeSubscription('${subscription._id}')">Resume Subscription</button>
                        ` : ''}
                        <button class="btn btn-info" onclick="subscriptionsManager.viewDeliveryHistory('${subscription._id}')">View Delivery History</button>
                        ${subscription.status !== 'cancelled' ? `
                            <button class="btn btn-danger" onclick="subscriptionsManager.cancelSubscription('${subscription._id}')">Cancel Subscription</button>
                        ` : ''}
                        <button class="btn btn-secondary" onclick="this.closest('.modal-backdrop').remove()">Close</button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', modalHtml);
    },

    async pauseSubscription(subscriptionId) {
        const subscription = this.subscriptions.find(s => s._id === subscriptionId);
        if (!subscription) return;
        
        const reason = prompt('Please provide a reason for pausing (optional):');
        if (reason === null) return; // User cancelled
        
        try {
            showLoading('Pausing subscription...');
            
            // Simulate API call
            await new Promise(resolve => setTimeout(resolve, 500));
            
            document.querySelector('.modal-backdrop')?.remove();
            showToast('Subscription paused successfully', 'success');
            
            await this.loadSubscriptions();
            await this.loadSubscriptionStats();
            
        } catch (error) {
            console.error('Error pausing subscription:', error);
            showToast('Failed to pause subscription', 'error');
        } finally {
            hideLoading();
        }
    },

    async resumeSubscription(subscriptionId) {
        if (!confirm('Are you sure you want to resume this subscription?')) return;
        
        try {
            showLoading('Resuming subscription...');
            
            // Simulate API call
            await new Promise(resolve => setTimeout(resolve, 500));
            
            document.querySelector('.modal-backdrop')?.remove();
            showToast('Subscription resumed successfully', 'success');
            
            await this.loadSubscriptions();
            await this.loadSubscriptionStats();
            
        } catch (error) {
            console.error('Error resuming subscription:', error);
            showToast('Failed to resume subscription', 'error');
        } finally {
            hideLoading();
        }
    },

    async cancelSubscription(subscriptionId) {
        const subscription = this.subscriptions.find(s => s._id === subscriptionId);
        if (!subscription) return;
        
        const reason = prompt('Please provide a reason for cancellation:');
        if (!reason) return;
        
        if (!confirm(`Are you sure you want to cancel ${subscription.userName}'s subscription?`)) return;
        
        try {
            showLoading('Cancelling subscription...');
            
            // Simulate API call
            await new Promise(resolve => setTimeout(resolve, 500));
            
            document.querySelector('.modal-backdrop')?.remove();
            showToast('Subscription cancelled successfully', 'success');
            
            await this.loadSubscriptions();
            await this.loadSubscriptionStats();
            
        } catch (error) {
            console.error('Error cancelling subscription:', error);
            showToast('Failed to cancel subscription', 'error');
        } finally {
            hideLoading();
        }
    },

    async viewDeliveryHistory(subscriptionId) {
        try {
            showLoading('Loading delivery history...');
            
            const history = await this.fetchDeliveryHistory(subscriptionId);
            
            const modalHtml = `
                <div class="modal-backdrop" onclick="this.remove()">
                    <div class="modal-content large" onclick="event.stopPropagation()">
                        <div class="modal-header">
                            <h3>Delivery History</h3>
                            <button class="modal-close" onclick="this.closest('.modal-backdrop').remove()">×</button>
                        </div>
                        <div class="modal-body">
                            <div class="delivery-history">
                                ${history.length > 0 ? history.map(delivery => this.renderDeliveryItem(delivery)).join('') : 
                                  '<p class="text-muted">No deliveries yet.</p>'}
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button class="btn btn-secondary" onclick="this.closest('.modal-backdrop').remove()">Close</button>
                        </div>
                    </div>
                </div>
            `;
            
            document.body.insertAdjacentHTML('beforeend', modalHtml);
            
        } catch (error) {
            console.error('Error loading delivery history:', error);
            showToast('Failed to load delivery history', 'error');
        } finally {
            hideLoading();
        }
    },

    async fetchDeliveryHistory(subscriptionId) {
        // Sample data - replace with actual API call
        return [
            {
                orderNumber: 'SUB-2025-001',
                deliveryDate: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000),
                status: 'delivered',
                amount: 24.99,
                trackingNumber: 'TRK123456'
            },
            {
                orderNumber: 'SUB-2025-002',
                deliveryDate: new Date(Date.now() - 28 * 24 * 60 * 60 * 1000),
                status: 'delivered',
                amount: 24.99,
                trackingNumber: 'TRK123457'
            },
            {
                orderNumber: 'SUB-2025-003',
                deliveryDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
                status: 'scheduled',
                amount: 24.99
            }
        ];
    },

    renderDeliveryItem(delivery) {
        const statusBadge = this.getDeliveryStatusBadge(delivery.status);
        
        return `
            <div class="delivery-item">
                <div class="delivery-content">
                    <div class="delivery-header">
                        <strong>${delivery.orderNumber}</strong>
                        ${statusBadge}
                    </div>
                    <div class="delivery-details">
                        <p><strong>Delivery Date:</strong> ${this.formatDate(delivery.deliveryDate)}</p>
                        <p><strong>Amount:</strong> AED ${delivery.amount}</p>
                        ${delivery.trackingNumber ? `<p><strong>Tracking:</strong> ${delivery.trackingNumber}</p>` : ''}
                    </div>
                </div>
            </div>
        `;
    },

    getDeliveryStatusBadge(status) {
        const badges = {
            scheduled: '<span class="badge badge-info">Scheduled</span>',
            preparing: '<span class="badge badge-warning">Preparing</span>',
            shipped: '<span class="badge badge-primary">Shipped</span>',
            delivered: '<span class="badge badge-success">Delivered</span>',
            failed: '<span class="badge badge-danger">Failed</span>'
        };
        return badges[status] || '<span class="badge badge-secondary">Unknown</span>';
    },

    calculateDuration(startDate) {
        const now = new Date();
        const start = new Date(startDate);
        const diffTime = Math.abs(now - start);
        const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
        
        if (diffDays < 30) return `${diffDays} days`;
        if (diffDays < 365) return `${Math.floor(diffDays / 30)} months`;
        return `${Math.floor(diffDays / 365)} years`;
    },

    formatNumber(num) {
        return num.toLocaleString('en-AE', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    },

    formatDate(date) {
        return new Date(date).toLocaleDateString('en-AE', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    }
};

// ===============================================
// Subscription Plans Management
// ===============================================

class SubscriptionPlansManager {
    constructor() {
        this.plans = [];
        this.currentPlan = null;
        this.coffeeProducts = [];
    }

    async init() {
        try {
            await this.loadCoffeeProducts();
            await this.loadPlans();
            await this.loadPlanStats();
        } catch (error) {
            console.error('Plans initialization error:', error);
        }
    }

    async loadCoffeeProducts() {
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/coffee`);
            const data = await response.json();
            
            if (data.success && data.data) {
                this.coffeeProducts = data.data;
                this.populateProductsDropdown();
            }
        } catch (error) {
            console.error('Error loading coffee products:', error);
        }
    }

    populateProductsDropdown() {
        const select = document.getElementById('planProducts');
        if (!select) return;

        select.innerHTML = this.coffeeProducts.map(product => `
            <option value="${product._id}">${product.name} - AED ${product.price}</option>
        `).join('');
    }

    async loadPlans() {
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/subscriptions/plans`);
            const data = await response.json();

            if (data.success && data.data && data.data.plans) {
                this.plans = data.data.plans;
                this.renderPlansTable();
            } else {
                this.plans = [];
                this.renderPlansEmptyState();
            }
        } catch (error) {
            console.error('Error loading plans:', error);
            this.renderPlansEmptyState();
        }
    }

    async loadPlanStats() {
        try {
            const totalPlans = this.plans.length;
            const activePlans = this.plans.filter(p => p.isActive).length;
            const totalSubscribers = this.plans.reduce((sum, p) => sum + (p.subscriberCount || 0), 0);
            const totalRevenue = this.plans.reduce((sum, p) => {
                const price = p.pricing?.find(pr => pr.duration === 'monthly')?.price || 0;
                const discount = (price * (p.discountPercentage || 0)) / 100;
                return sum + ((price - discount) * (p.subscriberCount || 0));
            }, 0);

            document.getElementById('totalPlans').textContent = totalPlans;
            document.getElementById('activePlans').textContent = activePlans;
            document.getElementById('planSubscribers').textContent = totalSubscribers;
            document.getElementById('planRevenue').textContent = `AED ${totalRevenue.toFixed(2)}`;
        } catch (error) {
            console.error('Error loading plan stats:', error);
        }
    }

    renderPlansTable() {
        const container = document.getElementById('plansTable');
        
        if (!this.plans || this.plans.length === 0) {
            this.renderPlansEmptyState();
            return;
        }

        container.innerHTML = `
            <table class="plans-table">
                <thead>
                    <tr>
                        <th>Plan Name</th>
                        <th>Duration</th>
                        <th>Base Price</th>
                        <th>Discount</th>
                        <th>Products</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    ${this.plans.map(plan => this.renderPlanRow(plan)).join('')}
                </tbody>
            </table>
        `;
    }

    renderPlanRow(plan) {
        const pricing = plan.pricing?.[0] || {};
        const finalPrice = pricing.price ? (pricing.price * (1 - (plan.discountPercentage || 0) / 100)).toFixed(2) : 'N/A';
        
        return `
            <tr>
                <td>
                    <strong>${this.escapeHtml(plan.name)}</strong>
                    <div style="font-size: 12px; color: #666; margin-top: 4px;">
                        ${this.escapeHtml(plan.description || '')}
                    </div>
                </td>
                <td>
                    <span class="plan-duration-badge ${pricing.duration || 'monthly'}">
                        ${pricing.duration || 'Monthly'}
                    </span>
                </td>
                <td>
                    <div style="font-size: 14px; font-weight: 600;">AED ${pricing.price || 0}</div>
                    ${plan.discountPercentage ? `<div style="font-size: 12px; color: #28a745;">Final: AED ${finalPrice}</div>` : ''}
                </td>
                <td>
                    ${plan.discountPercentage ? `<span style="color: #28a745; font-weight: 600;">${plan.discountPercentage}%</span>` : '-'}
                </td>
                <td>
                    <div class="plan-products">
                        ${plan.coffeeProducts?.slice(0, 2).map(productId => {
                            const product = this.coffeeProducts.find(p => p._id === productId);
                            return product ? `<span class="product-badge">${product.name}</span>` : '';
                        }).join('') || '-'}
                        ${plan.coffeeProducts?.length > 2 ? `<span class="product-badge">+${plan.coffeeProducts.length - 2}</span>` : ''}
                    </div>
                </td>
                <td>
                    <span class="badge ${plan.isActive ? 'badge-success' : 'badge-secondary'}">
                        ${plan.isActive ? 'Active' : 'Inactive'}
                    </span>
                </td>
                <td>
                    <div class="action-buttons">
                        <button class="btn btn-sm btn-primary" onclick="plansManager.editPlan('${plan._id}')" title="Edit">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-danger" onclick="plansManager.deletePlan('${plan._id}')" title="Delete">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }

    renderPlansEmptyState() {
        const container = document.getElementById('plansTable');
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-clipboard-list"></i>
                <h3>No Subscription Plans Yet</h3>
                <p>Create your first subscription plan to offer recurring deliveries to customers.</p>
                <button class="btn btn-primary" onclick="openPlanModal()">
                    <i class="fas fa-plus"></i> Create First Plan
                </button>
            </div>
        `;
    }

    async editPlan(planId) {
        const plan = this.plans.find(p => p._id === planId);
        if (!plan) return;

        this.currentPlan = plan;
        document.getElementById('planId').value = plan._id;
        document.getElementById('planName').value = plan.name;
        document.getElementById('planDescription').value = plan.description || '';
        
        const pricing = plan.pricing?.[0] || {};
        document.getElementById('planDuration').value = pricing.duration || '';
        document.getElementById('planBasePrice').value = pricing.price || '';
        document.getElementById('planDiscount').value = plan.discountPercentage || '';
        document.getElementById('planIsActive').checked = plan.isActive;

        // Select products
        const select = document.getElementById('planProducts');
        Array.from(select.options).forEach(option => {
            option.selected = plan.coffeeProducts?.includes(option.value);
        });

        // Set benefits
        document.getElementById('planBenefits').value = plan.benefits?.join('\n') || '';

        document.getElementById('planModalTitle').textContent = '✏️ Edit Subscription Plan';
        document.getElementById('planModal').style.display = 'flex';
    }

    async deletePlan(planId) {
        if (!confirm('Are you sure you want to delete this subscription plan?')) return;

        try {
            showLoading('Deleting plan...');
            const response = await authenticatedFetch(`${API_BASE_URL}/api/subscriptions/plans/${planId}`, {
                method: 'DELETE'
            });
            const data = await response.json();

            if (data.success) {
                showToast('Subscription plan deleted successfully', 'success');
                await this.loadPlans();
                await this.loadPlanStats();
            } else {
                showToast(data.message || 'Failed to delete plan', 'error');
            }
        } catch (error) {
            console.error('Error deleting plan:', error);
            showToast('Failed to delete subscription plan', 'error');
        } finally {
            hideLoading();
        }
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text || '';
        return div.innerHTML;
    }
}


// Global Functions (accessible from HTML)


// Tab Switching Function
window.switchSubscriptionTab = function(tabName) {
    // Update tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
    event.target.closest('.tab-btn').classList.add('active');

    // Update tab content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
        content.style.display = 'none';
    });

    if (tabName === 'active-subscriptions') {
        document.getElementById('active-subscriptions-tab').style.display = 'block';
        document.getElementById('active-subscriptions-tab').classList.add('active');
        if (subscriptionsManager) {
            subscriptionsManager.init();
        }
    } else if (tabName === 'subscription-plans') {
        document.getElementById('subscription-plans-tab').style.display = 'block';
        document.getElementById('subscription-plans-tab').classList.add('active');
        if (plansManager) {
            plansManager.init();
        }
    }
};

// Plan Modal Functions
window.openPlanModal = function() {
    if (!plansManager) {
        console.error('Plans manager not initialized');
        return;
    }
    plansManager.currentPlan = null;
    document.getElementById('planForm').reset();
    document.getElementById('planId').value = '';
    document.getElementById('planModalTitle').textContent = '📋 Create Subscription Plan';
    document.getElementById('planModal').style.display = 'flex';
};

window.closePlanModal = function() {
    document.getElementById('planModal').style.display = 'none';
    document.getElementById('planForm').reset();
};

window.handlePlanSubmit = async function(event) {
    event.preventDefault();

    const planId = document.getElementById('planId').value;
    const formData = {
        name: document.getElementById('planName').value,
        description: document.getElementById('planDescription').value,
        pricing: [{
            duration: document.getElementById('planDuration').value,
            price: parseFloat(document.getElementById('planBasePrice').value)
        }],
        discountPercentage: parseInt(document.getElementById('planDiscount').value) || 0,
        coffeeProducts: Array.from(document.getElementById('planProducts').selectedOptions).map(opt => opt.value),
        benefits: document.getElementById('planBenefits').value.split('\n').filter(b => b.trim()),
        isActive: document.getElementById('planIsActive').checked
    };

    try {
        showLoading(planId ? 'Updating plan...' : 'Creating plan...');

        const url = planId 
            ? `${API_BASE_URL}/api/subscriptions/plans/${planId}`
            : `${API_BASE_URL}/api/subscriptions/plans`;

        const response = await authenticatedFetch(url, {
            method: planId ? 'PUT' : 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(formData)
        });

        const data = await response.json();

        if (data.success) {
            showToast(`Subscription plan ${planId ? 'updated' : 'created'} successfully`, 'success');
            window.closePlanModal();
            if (plansManager) {
                await plansManager.loadPlans();
                await plansManager.loadPlanStats();
            }
        } else {
            showToast(data.message || 'Failed to save plan', 'error');
        }
    } catch (error) {
        console.error('Error saving plan:', error);
        showToast('Failed to save subscription plan', 'error');
    } finally {
        hideLoading();
    }
};


// Initialize Managers (Global Access)
const plansManager = new SubscriptionPlansManager();

// Auto-load when subscriptions section is shown
document.addEventListener('DOMContentLoaded', () => {
    // Hook into showSection if it exists
    if (typeof window.showSection === 'function') {
        const originalShowSection = window.showSection;
        window.showSection = function(sectionName) {
            originalShowSection.call(this, sectionName);
            if (sectionName === 'subscriptions' && subscriptionsManager) {
                subscriptionsManager.init();
            }
        };
    }
});
