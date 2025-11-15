/**
 * Feedback Management Module
 * Handles customer feedback viewing and management
 */

const feedbackManager = {
    feedbackList: [],
    currentFilter: 'all',
    
    async init() {
        await this.loadFeedbackStats();
        await this.loadFeedback();
    },

    async loadFeedbackStats() {
        showGlobalLoading();
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/feedback/stats`);
            const data = await response.json();
            
            if (data.success) {
                this.renderStats(data.data);
            }
        } catch (error) {
            console.error('Error loading feedback stats:', error);
            showError('Failed to load feedback statistics');
        } finally {
            hideGlobalLoading();
        }
    },

    renderStats(stats) {
        const statsHtml = `
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
                        <i class="fas fa-star"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">${stats.totalFeedback || 0}</div>
                        <div class="stat-label">Total Reviews</div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #fbc531 0%, #f79f1f 100%);">
                        <i class="fas fa-star-half-alt"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">${stats.avgRating ? stats.avgRating.toFixed(1) : '0.0'}</div>
                        <div class="stat-label">Avg Rating</div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);">
                        <i class="fas fa-thumbs-up"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">${stats.positiveFeedback || 0}</div>
                        <div class="stat-label">Positive (4-5★)</div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #ee5a6f 0%, #f29263 100%);">
                        <i class="fas fa-exclamation-circle"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">${stats.needsAttention || 0}</div>
                        <div class="stat-label">Needs Attention (1-2★)</div>
                    </div>
                </div>
            </div>
        `;
        
        document.getElementById('feedbackStats').innerHTML = statsHtml;
    },

    async loadFeedback(filter = 'all') {
        showGlobalLoading();
        this.currentFilter = filter;
        
        // Update filter button active states
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        
        try {
            // Fix: Use 'status' parameter instead of 'type' to match backend expectations
            const queryParam = filter !== 'all' ? `?status=${filter}` : '';
            const response = await authenticatedFetch(`${API_BASE_URL}/api/feedback/admin/all${queryParam}`);
            const data = await response.json();
            
            if (data.success) {
                // Fix: The backend returns feedback array nested in data.feedback
                this.feedbackList = data.data.feedback || [];
                this.renderFeedbackTable(this.feedbackList);
                
                // Set active filter button
                const activeButton = document.querySelector(`[onclick="feedbackManager.loadFeedback('${filter}')"]`);
                if (activeButton) {
                    activeButton.classList.add('active');
                }
            } else {
                console.error('API returned error:', data.message);
                showError(data.message || 'Failed to load feedback');
                this.feedbackList = [];
                this.renderFeedbackTable(this.feedbackList);
            }
        } catch (error) {
            console.error('Error loading feedback:', error);
            showError('Failed to load feedback');
            this.feedbackList = [];
            this.renderFeedbackTable(this.feedbackList);
        } finally {
            hideGlobalLoading();
        }
    },

    renderFeedbackTable(feedbackList) {
        // Enhanced safety check: ensure feedbackList is an array
        if (!Array.isArray(feedbackList) || feedbackList.length === 0) {
            document.getElementById('feedbackTable').innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-star"></i>
                    <h3>No Reviews Yet</h3>
                    <p>No product reviews found for the selected filter.</p>
                </div>
            `;
            return;
        }

        const tableHtml = `
            <div class="table-container">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>User</th>
                            <th>Product</th>
                            <th>Rating</th>
                            <th>Review</th>
                            <th>Status</th>
                            <th>Date</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${feedbackList.map(feedback => this.renderFeedbackRow(feedback)).join('')}
                    </tbody>
                </table>
            </div>
        `;
        
        document.getElementById('feedbackTable').innerHTML = tableHtml;
    },

    renderFeedbackRow(feedback) {
        const statusBadge = this.getStatusBadge(feedback);
        const ratingStars = this.getRatingStars(feedback.rating);
        const userName = feedback.user?.name || 'Anonymous';
        const userEmail = feedback.user?.email || '';
        const productName = feedback.product?.name || 'Unknown Product';
        
        return `
            <tr data-feedback-id="${feedback._id}">
                <td>
                    <div class="user-info">
                        <strong>${userName}</strong>
                        ${userEmail ? `<small>${userEmail}</small>` : ''}
                    </div>
                </td>
                <td>
                    <div class="product-info">
                        <strong>${productName}</strong>
                        ${feedback.isVerifiedPurchase ? '<span class="badge badge-success">Verified</span>' : ''}
                    </div>
                </td>
                <td>${ratingStars}</td>
                <td>
                    <div class="feedback-subject">
                        <strong>${feedback.title}</strong>
                        <small>${feedback.comment?.substring(0, 50)}${feedback.comment?.length > 50 ? '...' : ''}</small>
                    </div>
                </td>
                <td>${statusBadge}</td>
                <td>${new Date(feedback.createdAt).toLocaleDateString()}</td>
                <td>
                    <button class="btn btn-sm btn-primary" onclick="feedbackManager.viewFeedback('${feedback._id}')">
                        <i class="fas fa-eye"></i> View
                    </button>
                </td>
            </tr>
        `;
    },

    getStatusBadge(feedback) {
        if (feedback.isHidden) {
            return '<span class="badge badge-danger">Hidden</span>';
        } else if (feedback.isApproved === false) {
            return '<span class="badge badge-warning">Pending</span>';
        } else if (feedback.isApproved === true) {
            return '<span class="badge badge-success">Approved</span>';
        }
        return '<span class="badge badge-secondary">Unknown</span>';
    },

    getRatingStars(rating) {
        if (!rating) return '<span class="text-muted">No rating</span>';
        
        let stars = '';
        for (let i = 1; i <= 5; i++) {
            if (i <= rating) {
                stars += '<i class="fas fa-star" style="color: #fbc531;"></i>';
            } else {
                stars += '<i class="far fa-star" style="color: #dfe4ea;"></i>';
            }
        }
        return `<span class="rating-stars">${stars} (${rating}/5)</span>`;
    },

    async viewFeedback(feedbackId) {
        showGlobalLoading();
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/feedback/${feedbackId}`);
            const data = await response.json();
            
            if (data.success) {
                this.showFeedbackModal(data.data);
            }
        } catch (error) {
            console.error('Error loading feedback:', error);
            showError('Failed to load feedback details');
        } finally {
            hideGlobalLoading();
        }
    },

    showFeedbackModal(feedback) {
        const modalHtml = `
            <div class="modal-overlay" onclick="feedbackManager.closeModal()">
                <div class="modal-content large" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h2>
                            <i class="fas fa-comments"></i> 
                            Feedback Details
                        </h2>
                        <button class="close-btn" onclick="feedbackManager.closeModal()">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>
                    
                    <div class="modal-body">
                        <div class="feedback-details">
                            <div class="feedback-header-info">
                                <div class="info-group">
                                    <label>Type:</label>
                                    ${this.getTypeBadge(feedback.type)}
                                </div>
                                <div class="info-group">
                                    <label>Status:</label>
                                    ${this.getStatusBadge(feedback.status)}
                                </div>
                                <div class="info-group">
                                    <label>Rating:</label>
                                    ${this.getRatingStars(feedback.rating)}
                                </div>
                            </div>
                            
                            <div class="feedback-user-info">
                                <h4>User Information</h4>
                                <p><strong>Name:</strong> ${feedback.userName || 'Anonymous'}</p>
                                <p><strong>Email:</strong> ${feedback.userEmail || 'N/A'}</p>
                                <p><strong>Submitted:</strong> ${new Date(feedback.createdAt).toLocaleString()}</p>
                            </div>
                            
                            ${feedback.subject ? `
                                <div class="feedback-subject-detail">
                                    <h4>Subject</h4>
                                    <p>${feedback.subject}</p>
                                </div>
                            ` : ''}
                            
                            <div class="feedback-message">
                                <h4>Message</h4>
                                <div class="message-content">${feedback.message || 'No message provided'}</div>
                            </div>
                            
                            ${feedback.productId ? `
                                <div class="feedback-product">
                                    <h4>Related Product</h4>
                                    <p><strong>Product ID:</strong> ${feedback.productId}</p>
                                    ${feedback.productName ? `<p><strong>Name:</strong> ${feedback.productName}</p>` : ''}
                                </div>
                            ` : ''}
                            
                            ${feedback.notes ? `
                                <div class="feedback-notes">
                                    <h4>Admin Notes</h4>
                                    <p>${feedback.notes}</p>
                                </div>
                            ` : ''}
                            
                            <div class="feedback-notes-form">
                                <h4>Add/Update Admin Notes</h4>
                                <textarea id="feedbackNotes" class="form-control" rows="3" 
                                    placeholder="Add internal notes about this feedback...">${feedback.notes || ''}</textarea>
                            </div>
                        </div>
                    </div>
                    
                    <div class="modal-footer">
                        <div class="status-actions">
                            <label>Update Status:</label>
                            <select id="feedbackStatus" class="form-control" style="width: auto; display: inline-block;">
                                <option value="new" ${feedback.status === 'new' ? 'selected' : ''}>New</option>
                                <option value="reviewed" ${feedback.status === 'reviewed' ? 'selected' : ''}>Reviewed</option>
                                <option value="resolved" ${feedback.status === 'resolved' ? 'selected' : ''}>Resolved</option>
                                <option value="archived" ${feedback.status === 'archived' ? 'selected' : ''}>Archived</option>
                            </select>
                            <button class="btn btn-success" onclick="feedbackManager.updateFeedback('${feedback._id}')">
                                <i class="fas fa-save"></i> Save Changes
                            </button>
                        </div>
                        <button class="btn btn-danger" onclick="feedbackManager.deleteFeedback('${feedback._id}')">
                            <i class="fas fa-trash"></i> Delete
                        </button>
                        <button class="btn btn-secondary" onclick="feedbackManager.closeModal()">
                            Close
                        </button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', modalHtml);
    },

    async updateFeedback(feedbackId) {
        const status = document.getElementById('feedbackStatus').value;
        const notes = document.getElementById('feedbackNotes').value.trim();
        
        showGlobalLoading();
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/feedback/${feedbackId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ status, notes })
            });
            
            const data = await response.json();
            
            if (data.success) {
                showSuccess('Feedback updated successfully');
                this.closeModal();
                await this.loadFeedback(this.currentFilter);
                await this.loadFeedbackStats();
            } else {
                showError(data.message || 'Failed to update feedback');
            }
        } catch (error) {
            console.error('Error updating feedback:', error);
            showError('Failed to update feedback');
        } finally {
            hideGlobalLoading();
        }
    },

    async deleteFeedback(feedbackId) {
        if (!confirm('Are you sure you want to delete this feedback?')) return;
        
        showGlobalLoading();
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/feedback/${feedbackId}`, {
                method: 'DELETE'
            });
            
            const data = await response.json();
            
            if (data.success) {
                showSuccess('Feedback deleted successfully');
                this.closeModal();
                await this.loadFeedback(this.currentFilter);
                await this.loadFeedbackStats();
            } else {
                showError(data.message || 'Failed to delete feedback');
            }
        } catch (error) {
            console.error('Error deleting feedback:', error);
            showError('Failed to delete feedback');
        } finally {
            hideGlobalLoading();
        }
    },

    async exportFeedback() {
        showGlobalLoading();
        try {
            const feedbackList = this.feedbackList;
            const csvData = this.convertToCSV(feedbackList);
            this.downloadCSV(csvData, `feedback-${Date.now()}.csv`);
            showSuccess('Feedback exported successfully');
        } catch (error) {
            console.error('Error exporting feedback:', error);
            showError('Failed to export feedback');
        } finally {
            hideGlobalLoading();
        }
    },

    convertToCSV(feedbackList) {
        const headers = ['Date', 'User', 'Email', 'Product', 'Rating', 'Title', 'Comment', 'Status', 'Verified Purchase'];
        const rows = feedbackList.map(feedback => [
            new Date(feedback.createdAt).toLocaleDateString(),
            feedback.user?.name || 'Anonymous',
            feedback.user?.email || 'N/A',
            feedback.product?.name || 'Unknown Product',
            feedback.rating || 'N/A',
            feedback.title || 'N/A',
            feedback.comment || 'N/A',
            feedback.isHidden ? 'Hidden' : (feedback.isApproved ? 'Approved' : 'Pending'),
            feedback.isVerifiedPurchase ? 'Yes' : 'No'
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
        if (section === 'feedback') {
            feedbackManager.init();
        }
    };
}
