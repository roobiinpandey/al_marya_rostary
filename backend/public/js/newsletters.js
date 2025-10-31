/**
 * Newsletters Management Module
 * Handles newsletter subscriber management and campaign creation
 */

const newslettersManager = {
    subscribers: [],
    currentTab: 'subscribers',
    
    async init() {
        await this.loadNewsletterStats();
        await this.loadSubscribers();
    },

    async loadNewsletterStats() {
        showLoading();
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/newsletters/stats`);
            const data = await response.json();
            
            if (data.success) {
                this.renderStats(data.data);
            }
        } catch (error) {
            console.error('Error loading newsletter stats:', error);
            showError('Failed to load newsletter statistics');
        } finally {
            hideLoading();
        }
    },

    renderStats(stats) {
        const statsHtml = `
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
                        <i class="fas fa-users"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">${stats.totalSubscribers || 0}</div>
                        <div class="stat-label">Total Subscribers</div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);">
                        <i class="fas fa-check-circle"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">${stats.activeSubscribers || 0}</div>
                        <div class="stat-label">Active Subscribers</div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);">
                        <i class="fas fa-envelope"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">${stats.campaignsSent || 0}</div>
                        <div class="stat-label">Campaigns Sent</div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #30cfd0 0%, #330867 100%);">
                        <i class="fas fa-chart-line"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">${stats.avgOpenRate || 0}%</div>
                        <div class="stat-label">Avg Open Rate</div>
                    </div>
                </div>
            </div>
        `;
        
        document.getElementById('newsletterStats').innerHTML = statsHtml;
    },

    async loadSubscribers() {
        showLoading();
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/newsletters/subscribers`);
            const data = await response.json();
            
            if (data.success) {
                this.subscribers = data.data;
                this.renderSubscribersTable(this.subscribers);
            }
        } catch (error) {
            console.error('Error loading subscribers:', error);
            showError('Failed to load subscribers');
        } finally {
            hideLoading();
        }
    },

    renderSubscribersTable(subscribers) {
        if (!subscribers || subscribers.length === 0) {
            document.getElementById('subscribersTable').innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-envelope-open"></i>
                    <h3>No Subscribers Yet</h3>
                    <p>No newsletter subscribers found.</p>
                </div>
            `;
            return;
        }

        const tableHtml = `
            <div class="table-container">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Email</th>
                            <th>Name</th>
                            <th>Status</th>
                            <th>Subscribed Date</th>
                            <th>Source</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${subscribers.map(subscriber => this.renderSubscriberRow(subscriber)).join('')}
                    </tbody>
                </table>
            </div>
        `;
        
        document.getElementById('subscribersTable').innerHTML = tableHtml;
    },

    renderSubscriberRow(subscriber) {
        const statusBadge = subscriber.isActive 
            ? '<span class="badge badge-success">Active</span>'
            : '<span class="badge badge-secondary">Unsubscribed</span>';
        
        return `
            <tr data-subscriber-id="${subscriber._id}">
                <td><strong>${subscriber.email}</strong></td>
                <td>${subscriber.name || 'N/A'}</td>
                <td>${statusBadge}</td>
                <td>${new Date(subscriber.subscribedAt || subscriber.createdAt).toLocaleDateString()}</td>
                <td><span class="badge badge-info">${subscriber.source || 'Website'}</span></td>
                <td>
                    ${subscriber.isActive ? `
                        <button class="btn btn-sm btn-warning" onclick="newslettersManager.unsubscribeUser('${subscriber._id}')">
                            <i class="fas fa-ban"></i> Unsubscribe
                        </button>
                    ` : `
                        <button class="btn btn-sm btn-success" onclick="newslettersManager.resubscribeUser('${subscriber._id}')">
                            <i class="fas fa-check"></i> Resubscribe
                        </button>
                    `}
                    <button class="btn btn-sm btn-danger" onclick="newslettersManager.deleteSubscriber('${subscriber._id}')">
                        <i class="fas fa-trash"></i>
                    </button>
                </td>
            </tr>
        `;
    },

    async unsubscribeUser(subscriberId) {
        if (!confirm('Are you sure you want to unsubscribe this user?')) return;
        
        showLoading();
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/newsletters/subscribers/${subscriberId}/unsubscribe`, {
                method: 'POST'
            });
            
            const data = await response.json();
            
            if (data.success) {
                showSuccess('User unsubscribed successfully');
                await this.loadSubscribers();
                await this.loadNewsletterStats();
            } else {
                showError(data.message || 'Failed to unsubscribe user');
            }
        } catch (error) {
            console.error('Error unsubscribing user:', error);
            showError('Failed to unsubscribe user');
        } finally {
            hideLoading();
        }
    },

    async resubscribeUser(subscriberId) {
        showLoading();
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/newsletters/subscribers/${subscriberId}/resubscribe`, {
                method: 'POST'
            });
            
            const data = await response.json();
            
            if (data.success) {
                showSuccess('User resubscribed successfully');
                await this.loadSubscribers();
                await this.loadNewsletterStats();
            } else {
                showError(data.message || 'Failed to resubscribe user');
            }
        } catch (error) {
            console.error('Error resubscribing user:', error);
            showError('Failed to resubscribe user');
        } finally {
            hideLoading();
        }
    },

    async deleteSubscriber(subscriberId) {
        if (!confirm('Are you sure you want to permanently delete this subscriber?')) return;
        
        showLoading();
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/newsletters/subscribers/${subscriberId}`, {
                method: 'DELETE'
            });
            
            const data = await response.json();
            
            if (data.success) {
                showSuccess('Subscriber deleted successfully');
                await this.loadSubscribers();
                await this.loadNewsletterStats();
            } else {
                showError(data.message || 'Failed to delete subscriber');
            }
        } catch (error) {
            console.error('Error deleting subscriber:', error);
            showError('Failed to delete subscriber');
        } finally {
            hideLoading();
        }
    },

    showAddSubscriberModal() {
        const modalHtml = `
            <div class="modal-overlay" onclick="newslettersManager.closeModal()">
                <div class="modal-content" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h2><i class="fas fa-user-plus"></i> Add New Subscriber</h2>
                        <button class="close-btn" onclick="newslettersManager.closeModal()">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>
                    
                    <div class="modal-body">
                        <div class="form-group">
                            <label for="subscriberEmail">Email Address *</label>
                            <input type="email" id="subscriberEmail" class="form-control" required>
                        </div>
                        
                        <div class="form-group">
                            <label for="subscriberName">Name (Optional)</label>
                            <input type="text" id="subscriberName" class="form-control">
                        </div>
                        
                        <div class="form-group">
                            <label for="subscriberSource">Source</label>
                            <select id="subscriberSource" class="form-control">
                                <option value="admin">Admin Added</option>
                                <option value="website">Website</option>
                                <option value="app">Mobile App</option>
                                <option value="import">Import</option>
                            </select>
                        </div>
                    </div>
                    
                    <div class="modal-footer">
                        <button class="btn btn-secondary" onclick="newslettersManager.closeModal()">
                            Cancel
                        </button>
                        <button class="btn btn-primary" onclick="newslettersManager.addSubscriber()">
                            <i class="fas fa-plus"></i> Add Subscriber
                        </button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', modalHtml);
    },

    async addSubscriber() {
        const email = document.getElementById('subscriberEmail').value.trim();
        const name = document.getElementById('subscriberName').value.trim();
        const source = document.getElementById('subscriberSource').value;
        
        if (!email) {
            showError('Email is required');
            return;
        }
        
        showLoading();
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/newsletters/subscribe`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, name, source })
            });
            
            const data = await response.json();
            
            if (data.success) {
                showSuccess('Subscriber added successfully');
                this.closeModal();
                await this.loadSubscribers();
                await this.loadNewsletterStats();
            } else {
                showError(data.message || 'Failed to add subscriber');
            }
        } catch (error) {
            console.error('Error adding subscriber:', error);
            showError('Failed to add subscriber');
        } finally {
            hideLoading();
        }
    },

    async exportSubscribers() {
        showLoading();
        try {
            const subscribers = this.subscribers.filter(s => s.isActive);
            const csvData = this.convertToCSV(subscribers);
            this.downloadCSV(csvData, `newsletter-subscribers-${Date.now()}.csv`);
            showSuccess('Subscribers exported successfully');
        } catch (error) {
            console.error('Error exporting subscribers:', error);
            showError('Failed to export subscribers');
        } finally {
            hideLoading();
        }
    },

    convertToCSV(subscribers) {
        const headers = ['Email', 'Name', 'Status', 'Subscribed Date', 'Source'];
        const rows = subscribers.map(sub => [
            sub.email,
            sub.name || 'N/A',
            sub.isActive ? 'Active' : 'Unsubscribed',
            new Date(sub.subscribedAt || sub.createdAt).toLocaleDateString(),
            sub.source || 'Website'
        ]);
        
        return [headers, ...rows]
            .map(row => row.map(field => `"${(field || '').toString().replace(/"/g, '""')}"`).join(','))
            .join('\n');
    },

    downloadCSV(csvData, filename) {
        const blob = new Blob([csvData], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        
        if (link.download !== undefined) {
            const url = URL.createObjectURL(blob);
            link.setAttribute('href', url);
            link.setAttribute('download', filename);
            link.style.visibility = 'hidden';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    },

    closeModal() {
        const modal = document.querySelector('.modal-overlay');
        if (modal) {
            modal.remove();
        }
    }
};

// Initialize when section is shown
if (typeof window.showSection !== 'undefined') {
    const originalShowSection = window.showSection;
    window.showSection = function(section) {
        originalShowSection(section);
        if (section === 'newsletters') {
            newslettersManager.init();
        }
    };
}
