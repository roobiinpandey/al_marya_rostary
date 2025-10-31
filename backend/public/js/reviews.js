/**
 * Reviews Management JavaScript
 * Handles admin functionality for product reviews
 */

const reviewsManager = {
    currentPage: 1,
    pageSize: 20,
    currentFilter: '',
    reviews: [],

    async init() {
        await this.loadReviewStats();
        await this.loadReviews();
    },

    async loadReviewStats() {
        try {
            showLoading('Loading review statistics...');
            
            // Simulate API call - replace with actual API
            const stats = await this.fetchReviewStats();
            
            document.getElementById('pendingReviews').textContent = stats.pending || 0;
            document.getElementById('approvedReviews').textContent = stats.approved || 0;
            document.getElementById('averageRating').textContent = (stats.averageRating || 0).toFixed(1);
            document.getElementById('totalReviews').textContent = stats.total || 0;
            
        } catch (error) {
            console.error('Error loading review stats:', error);
            showToast('Failed to load review statistics', 'error');
        } finally {
            hideLoading();
        }
    },

    async loadReviews() {
        try {
            showLoading('Loading reviews...');
            
            const filter = document.getElementById('reviewStatusFilter').value;
            const reviews = await this.fetchReviews(filter);
            
            this.renderReviewsTable(reviews);
            
        } catch (error) {
            console.error('Error loading reviews:', error);
            showToast('Failed to load reviews', 'error');
        } finally {
            hideLoading();
        }
    },

    async fetchReviewStats() {
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/reviews/admin/stats`);
            const data = await response.json();
            
            if (data.success) {
                return {
                    pending: data.data.pending || 0,
                    approved: data.data.approved || 0,
                    rejected: data.data.rejected || 0,
                    flagged: data.data.flagged || 0,
                    averageRating: data.data.averageRating || 0,
                    total: data.data.total || 0
                };
            }
            
            throw new Error(data.message || 'Failed to fetch stats');
        } catch (error) {
            console.error('Error fetching review stats:', error);
            return {
                pending: 0,
                approved: 0,
                rejected: 0,
                flagged: 0,
                averageRating: 0,
                total: 0
            };
        }
    },

    async fetchReviews(filter = '') {
        try {
            const params = new URLSearchParams();
            if (filter) params.append('status', filter);
            params.append('limit', '50');
            
            const response = await authenticatedFetch(`${API_BASE_URL}/api/reviews/admin/list?${params}`);
            const data = await response.json();
            
            // Check if API call was successful
            if (data.success && data.data) {
                // Return reviews array (could be empty, which is fine)
                if (Array.isArray(data.data.reviews)) {
                    return data.data.reviews.map(review => ({
                        _id: review._id,
                        productId: review.productId,
                        productName: review.productName,
                        userId: review.userId,
                        userName: review.userName,
                        userEmail: review.userEmail,
                        rating: review.rating,
                        title: review.title,
                        comment: review.comment,
                        status: review.status,
                        helpfulCount: review.helpfulCount || 0,
                        isVerifiedPurchase: review.isVerifiedPurchase,
                        orderNumber: review.orderNumber,
                        createdAt: new Date(review.createdAt),
                        updatedAt: review.updatedAt ? new Date(review.updatedAt) : null,
                        moderationNotes: review.moderationNotes,
                        moderatedBy: review.moderatedBy,
                        moderatedAt: review.moderatedAt ? new Date(review.moderatedAt) : null
                    }));
                } else {
                    // No reviews array, return empty
                    return [];
                }
            }
            
            // If API call failed, return empty array (don't throw error for empty state)
            console.warn('Reviews API returned unsuccessful response:', data.message);
            return [];
        } catch (error) {
            console.error('Error fetching reviews:', error);
            // Don't show toast for empty state, just return empty array
            return [];
        }
    },

    renderReviewsTable(reviews) {
        // Show message if no reviews
        if (!reviews || reviews.length === 0) {
            document.getElementById('reviewsTable').innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-star-half-alt" style="font-size: 48px; color: #ccc; margin-bottom: 16px;"></i>
                    <h3>No Reviews Yet</h3>
                    <p>Customer reviews will appear here once they start rating products.</p>
                    <p style="margin-top: 16px; color: #666;">
                        <i class="fas fa-info-circle"></i> 
                        Reviews are submitted through the mobile app after product delivery.
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
                            <th>Product</th>
                            <th>Customer</th>
                            <th>Rating</th>
                            <th>Review</th>
                            <th>Status</th>
                            <th>Date</th>
                            <th>Helpful</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${reviews.map(review => this.renderReviewRow(review)).join('')}
                    </tbody>
                </table>
            </div>
        `;
        
        document.getElementById('reviewsTable').innerHTML = tableHtml;
    },

    renderReviewRow(review) {
        const statusBadge = this.getStatusBadge(review.status);
        const stars = '★'.repeat(review.rating) + '☆'.repeat(5 - review.rating);
        const formattedDate = this.formatDate(review.createdAt);
        
        return `
            <tr>
                <td>
                    <div class="product-info">
                        <strong>${review.productName}</strong>
                    </div>
                </td>
                <td>
                    <div class="user-info">
                        <strong>${review.userName}</strong><br>
                        <small>${review.userEmail}</small>
                    </div>
                </td>
                <td>
                    <div class="rating">
                        <span class="stars" style="color: #ffa500;">${stars}</span>
                        <span class="rating-number">${review.rating}/5</span>
                    </div>
                </td>
                <td>
                    <div class="review-content">
                        <p class="review-text">${this.truncateText(review.comment, 100)}</p>
                        ${review.comment.length > 100 ? `<button class="btn-link" onclick="reviewsManager.showFullReview('${review._id}')">Read more</button>` : ''}
                    </div>
                </td>
                <td>${statusBadge}</td>
                <td>${formattedDate}</td>
                <td>
                    <span class="helpful-count">
                        <i class="fas fa-thumbs-up"></i> ${review.helpfulCount}
                    </span>
                </td>
                <td>
                    <div class="action-buttons">
                        ${review.status === 'pending' ? `
                            <button class="btn btn-success btn-sm" onclick="reviewsManager.approveReview('${review._id}')" title="Approve">
                                <i class="fas fa-check"></i>
                            </button>
                            <button class="btn btn-danger btn-sm" onclick="reviewsManager.rejectReview('${review._id}')" title="Reject">
                                <i class="fas fa-times"></i>
                            </button>
                        ` : ''}
                        <button class="btn btn-info btn-sm" onclick="reviewsManager.viewReviewDetail('${review._id}')" title="View Details">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn btn-warning btn-sm" onclick="reviewsManager.flagReview('${review._id}')" title="Flag">
                            <i class="fas fa-flag"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    },

    getStatusBadge(status) {
        const badges = {
            pending: '<span class="badge badge-warning">Pending</span>',
            approved: '<span class="badge badge-success">Approved</span>',
            rejected: '<span class="badge badge-danger">Rejected</span>',
            flagged: '<span class="badge badge-error">Flagged</span>'
        };
        return badges[status] || '<span class="badge badge-secondary">Unknown</span>';
    },

    async approveReview(reviewId) {
        if (!confirm('Are you sure you want to approve this review?')) return;
        
        try {
            showLoading('Approving review...');
            
            // Simulate API call
            await new Promise(resolve => setTimeout(resolve, 500));
            
            showToast('Review approved successfully', 'success');
            await this.loadReviews();
            await this.loadReviewStats();
            
        } catch (error) {
            console.error('Error approving review:', error);
            showToast('Failed to approve review', 'error');
        } finally {
            hideLoading();
        }
    },

    async rejectReview(reviewId) {
        const reason = prompt('Please provide a reason for rejection (optional):');
        if (reason === null) return; // User cancelled
        
        try {
            showLoading('Rejecting review...');
            
            // Simulate API call
            await new Promise(resolve => setTimeout(resolve, 500));
            
            showToast('Review rejected successfully', 'success');
            await this.loadReviews();
            await this.loadReviewStats();
            
        } catch (error) {
            console.error('Error rejecting review:', error);
            showToast('Failed to reject review', 'error');
        } finally {
            hideLoading();
        }
    },

    async flagReview(reviewId) {
        const reason = prompt('Please provide a reason for flagging:');
        if (!reason) return;
        
        try {
            showLoading('Flagging review...');
            
            // Simulate API call
            await new Promise(resolve => setTimeout(resolve, 500));
            
            showToast('Review flagged successfully', 'success');
            await this.loadReviews();
            
        } catch (error) {
            console.error('Error flagging review:', error);
            showToast('Failed to flag review', 'error');
        } finally {
            hideLoading();
        }
    },

    showFullReview(reviewId) {
        const review = this.reviews.find(r => r._id === reviewId);
        if (!review) return;
        
        alert(`Full Review:\n\n${review.comment}`);
    },

    viewReviewDetail(reviewId) {
        const review = this.reviews.find(r => r._id === reviewId) || 
                      { _id: reviewId, productName: 'Sample Product', userName: 'Sample User' };
        
        const modalHtml = `
            <div class="modal-backdrop" onclick="this.remove()">
                <div class="modal-content" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h3>Review Details</h3>
                        <button class="modal-close" onclick="this.closest('.modal-backdrop').remove()">×</button>
                    </div>
                    <div class="modal-body">
                        <div class="review-detail">
                            <h4>${review.productName}</h4>
                            <div class="reviewer-info">
                                <strong>Reviewer:</strong> ${review.userName}<br>
                                <strong>Email:</strong> ${review.userEmail}<br>
                                <strong>Rating:</strong> ${'★'.repeat(review.rating || 5)} (${review.rating || 5}/5)<br>
                                <strong>Date:</strong> ${this.formatDate(review.createdAt || new Date())}<br>
                                <strong>Status:</strong> ${this.getStatusBadge(review.status || 'pending')}<br>
                                <strong>Helpful Votes:</strong> ${review.helpfulCount || 0}
                            </div>
                            <div class="review-text">
                                <strong>Review:</strong><br>
                                <p>${review.comment || 'Sample review comment...'}</p>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-secondary" onclick="this.closest('.modal-backdrop').remove()">Close</button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', modalHtml);
    },

    truncateText(text, length) {
        if (text.length <= length) return text;
        return text.substring(0, length) + '...';
    },

    formatDate(date) {
        if (!date) return 'Unknown';
        return new Date(date).toLocaleDateString('en-AE', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    }
};

// Auto-load when reviews section is shown
document.addEventListener('DOMContentLoaded', () => {
    // Add event listener for section changes
    if (typeof window.showSection === 'function') {
        const originalShowSection = window.showSection;
        window.showSection = function(sectionName) {
            originalShowSection.call(this, sectionName);
            if (sectionName === 'reviews' && reviewsManager) {
                reviewsManager.init();
            }
        };
    }
});
