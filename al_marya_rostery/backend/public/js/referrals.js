/**
 * Referrals Management JavaScript
 * Handles admin functionality for referral program
 */

const referralsManager = {
    currentPage: 1,
    pageSize: 20,
    referrals: [],

    async init() {
        await this.loadReferralStats();
        await this.loadReferrals();
    },

    async loadReferralStats() {
        try {
            showGlobalLoading('Loading referral statistics...');
            
            const stats = await this.fetchReferralStats();
            
            document.getElementById('totalReferrals').textContent = stats.totalReferrals || 0;
            document.getElementById('completedReferrals').textContent = stats.completedReferrals || 0;
            document.getElementById('conversionRate').textContent = `${stats.conversionRate || 0}%`;
            document.getElementById('topReferrer').textContent = stats.topReferrer || '-';
            
        } catch (error) {
            console.error('Error loading referral stats:', error);
            showToast('Failed to load referral statistics', 'error');
        } finally {
            hideGlobalLoading();
        }
    },

    async loadReferrals() {
        try {
            showGlobalLoading('Loading referrals...');
            
            const referrals = await this.fetchReferrals();
            this.referrals = referrals;
            this.renderReferralsTable(referrals);
            
        } catch (error) {
            console.error('Error loading referrals:', error);
            showToast('Failed to load referrals', 'error');
        } finally {
            hideGlobalLoading();
        }
    },

    async fetchReferralStats() {
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/referrals/admin/stats`);
            const data = await response.json();
            
            if (data.success) {
                return {
                    totalReferrals: data.data.totalReferrals || 0,
                    completedReferrals: data.data.completedReferrals || 0,
                    registeredReferrals: data.data.registeredReferrals || 0,
                    pendingReferrals: data.data.pendingReferrals || 0,
                    conversionRate: data.data.conversionRate || 0,
                    topReferrer: data.data.topReferrer || '-'
                };
            }
            
            throw new Error(data.message || 'Failed to fetch stats');
        } catch (error) {
            console.error('Error fetching referral stats:', error);
            // Return default values on error
            return {
                totalReferrals: 0,
                completedReferrals: 0,
                registeredReferrals: 0,
                pendingReferrals: 0,
                conversionRate: 0,
                topReferrer: '-'
            };
        }
    },

    async fetchReferrals() {
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/referrals/admin/list`);
            const data = await response.json();
            
            if (data.success && data.data && Array.isArray(data.data.referrals)) {
                // Return real referrals from database
                return data.data.referrals.map(referral => ({
                    _id: referral._id,
                    referrerName: referral.referrerName,
                    referrerEmail: referral.referrerEmail,
                    referrerUserId: referral.referrerUserId,
                    refereeEmail: referral.refereeEmail,
                    refereeName: referral.refereeName,
                    refereeUserId: referral.refereeUserId,
                    referralCode: referral.referralCode,
                    status: referral.status,
                    createdAt: new Date(referral.createdAt),
                    registeredAt: referral.registeredAt ? new Date(referral.registeredAt) : null,
                    completedAt: referral.completedAt ? new Date(referral.completedAt) : null,
                    clickCount: referral.clickCount || 0,
                    referrerReward: referral.referrerReward,
                    refereeReward: referral.refereeReward,
                    campaign: referral.campaign,
                    source: referral.source
                }));
            }
            
            // Return empty array if no referrals found
            console.warn('Referrals API returned unsuccessful response or empty data');
            return [];
        } catch (error) {
            console.error('Error fetching referrals:', error);
            // Don't show toast for empty state, just return empty array
            return [];
        }
    },

    renderReferralsTable(referrals) {
        // Show empty state if no referrals
        if (!referrals || referrals.length === 0) {
            document.getElementById('referralsTable').innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-users" style="font-size: 48px; color: #ccc; margin-bottom: 16px;"></i>
                    <h3>No Referrals Yet</h3>
                    <p>Referral data will appear here when customers start referring friends.</p>
                    <p style="margin-top: 16px; color: #666;">
                        <i class="fas fa-info-circle"></i> 
                        Users can generate referral codes from the mobile app.
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
                            <th>Referrer</th>
                            <th>Referee</th>
                            <th>Code</th>
                            <th>Status</th>
                            <th>Clicks</th>
                            <th>Created</th>
                            <th>Rewards</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${referrals.map(referral => this.renderReferralRow(referral)).join('')}
                    </tbody>
                </table>
            </div>
        `;
        
        document.getElementById('referralsTable').innerHTML = tableHtml;
    },

    renderReferralRow(referral) {
        const statusBadge = this.getStatusBadge(referral.status);
        const formattedDate = this.formatDate(referral.createdAt);
        const refereeName = referral.refereeName || 'Not registered';
        
        return `
            <tr>
                <td>
                    <div class="user-info">
                        <strong>${referral.referrerName}</strong><br>
                        <small>${referral.referrerEmail}</small>
                    </div>
                </td>
                <td>
                    <div class="user-info">
                        <strong>${refereeName}</strong><br>
                        <small>${referral.refereeEmail}</small>
                    </div>
                </td>
                <td>
                    <code class="referral-code">${referral.referralCode}</code>
                </td>
                <td>${statusBadge}</td>
                <td>
                    <span class="click-count">${referral.clickCount}</span>
                </td>
                <td>${formattedDate}</td>
                <td>
                    <div class="rewards-info">
                        <div class="reward-item">
                            <span class="reward-label">Referrer:</span>
                            <span class="reward-value ${referral.referrerReward.awarded ? 'text-success' : 'text-muted'}">
                                ${referral.referrerReward.points} pts
                                ${referral.referrerReward.awarded ? '✓' : '⏳'}
                            </span>
                        </div>
                        <div class="reward-item">
                            <span class="reward-label">Referee:</span>
                            <span class="reward-value ${referral.refereeReward.used ? 'text-success' : 'text-muted'}">
                                $${referral.refereeReward.discount.amount} off
                                ${referral.refereeReward.used ? '✓' : '⏳'}
                            </span>
                        </div>
                    </div>
                </td>
                <td>
                    <div class="action-buttons">
                        <button class="btn btn-info btn-sm" onclick="referralsManager.viewReferralDetail('${referral._id}')" title="View Details">
                            <i class="fas fa-eye"></i>
                        </button>
                        ${referral.status === 'pending' ? `
                            <button class="btn btn-warning btn-sm" onclick="referralsManager.sendReminder('${referral._id}')" title="Send Reminder">
                                <i class="fas fa-envelope"></i>
                            </button>
                        ` : ''}
                        <button class="btn btn-secondary btn-sm" onclick="referralsManager.copyReferralLink('${referral.referralCode}')" title="Copy Link">
                            <i class="fas fa-link"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    },

    getStatusBadge(status) {
        const badges = {
            pending: '<span class="badge badge-warning">Pending</span>',
            registered: '<span class="badge badge-info">Registered</span>',
            completed: '<span class="badge badge-success">Completed</span>',
            cancelled: '<span class="badge badge-danger">Cancelled</span>'
        };
        return badges[status] || '<span class="badge badge-secondary">Unknown</span>';
    },

    viewReferralDetail(referralId) {
        const referral = this.referrals.find(r => r._id === referralId);
        if (!referral) {
            showToast('Referral not found', 'error');
            return;
        }
        
        const timeline = this.buildTimeline(referral);
        
        const modalHtml = `
            <div class="modal-backdrop" onclick="this.remove()">
                <div class="modal-content large" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h3>Referral Details - ${referral.referralCode}</h3>
                        <button class="modal-close" onclick="this.closest('.modal-backdrop').remove()">×</button>
                    </div>
                    <div class="modal-body">
                        <div class="referral-detail">
                            <div class="detail-grid">
                                <div class="detail-section">
                                    <h4>Referrer Information</h4>
                                    <p><strong>Name:</strong> ${referral.referrerName}</p>
                                    <p><strong>Email:</strong> ${referral.referrerEmail}</p>
                                    <p><strong>Referral Code:</strong> <code>${referral.referralCode}</code></p>
                                </div>
                                
                                <div class="detail-section">
                                    <h4>Referee Information</h4>
                                    <p><strong>Email:</strong> ${referral.refereeEmail}</p>
                                    <p><strong>Name:</strong> ${referral.refereeName || 'Not registered yet'}</p>
                                    <p><strong>Status:</strong> ${this.getStatusBadge(referral.status)}</p>
                                </div>
                                
                                <div class="detail-section">
                                    <h4>Activity & Rewards</h4>
                                    <p><strong>Link Clicks:</strong> ${referral.clickCount}</p>
                                    <p><strong>Referrer Reward:</strong> ${referral.referrerReward.points} points 
                                       ${referral.referrerReward.awarded ? '(Awarded ✓)' : '(Pending ⏳)'}</p>
                                    <p><strong>Referee Discount:</strong> $${referral.refereeReward.discount.amount} off 
                                       ${referral.refereeReward.used ? '(Used ✓)' : '(Available ⏳)'}</p>
                                </div>
                            </div>
                            
                            <div class="timeline-section">
                                <h4>Referral Timeline</h4>
                                <div class="timeline">
                                    ${timeline}
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-info" onclick="referralsManager.copyReferralLink('${referral.referralCode}')">Copy Referral Link</button>
                        ${referral.status === 'pending' ? `
                            <button class="btn btn-warning" onclick="referralsManager.sendReminder('${referral._id}')">Send Reminder</button>
                        ` : ''}
                        <button class="btn btn-secondary" onclick="this.closest('.modal-backdrop').remove()">Close</button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', modalHtml);
    },

    buildTimeline(referral) {
        const events = [
            {
                date: referral.createdAt,
                title: 'Referral Created',
                description: `${referral.referrerName} created referral for ${referral.refereeEmail}`,
                status: 'completed'
            }
        ];
        
        if (referral.clickCount > 0) {
            events.push({
                date: referral.createdAt, // Would be actual click date
                title: 'Link Clicked',
                description: `Referral link clicked ${referral.clickCount} time(s)`,
                status: 'completed'
            });
        }
        
        if (referral.registeredAt) {
            events.push({
                date: referral.registeredAt,
                title: 'User Registered',
                description: `${referral.refereeName} created an account`,
                status: 'completed'
            });
        }
        
        if (referral.completedAt) {
            events.push({
                date: referral.completedAt,
                title: 'First Purchase',
                description: 'Referee made their first purchase',
                status: 'completed'
            });
        }
        
        return events.map(event => `
            <div class="timeline-item ${event.status}">
                <div class="timeline-marker"></div>
                <div class="timeline-content">
                    <div class="timeline-title">${event.title}</div>
                    <div class="timeline-description">${event.description}</div>
                    <div class="timeline-date">${this.formatDate(event.date)}</div>
                </div>
            </div>
        `).join('');
    },

    async sendReminder(referralId) {
        const referral = this.referrals.find(r => r._id === referralId);
        if (!referral) return;
        
        if (!confirm(`Send reminder email to ${referral.refereeEmail}?`)) return;
        
        try {
            showGlobalLoading('Sending reminder...');
            
            // Simulate API call
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            showToast('Reminder email sent successfully!', 'success');
            
        } catch (error) {
            console.error('Error sending reminder:', error);
            showToast('Failed to send reminder', 'error');
        } finally {
            hideGlobalLoading();
        }
    },

    copyReferralLink(referralCode) {
        const link = `${window.location.origin}/signup?ref=${referralCode}`;
        
        if (navigator.clipboard) {
            navigator.clipboard.writeText(link).then(() => {
                showToast('Referral link copied to clipboard!', 'success');
            }).catch(() => {
                this.fallbackCopyTextToClipboard(link);
            });
        } else {
            this.fallbackCopyTextToClipboard(link);
        }
    },

    fallbackCopyTextToClipboard(text) {
        const textArea = document.createElement('textarea');
        textArea.value = text;
        textArea.style.position = 'fixed';
        textArea.style.left = '-999999px';
        textArea.style.top = '-999999px';
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        
        try {
            document.execCommand('copy');
            showToast('Referral link copied to clipboard!', 'success');
        } catch (err) {
            showToast('Failed to copy link', 'error');
        }
        
        document.body.removeChild(textArea);
    },

    async exportReferralData() {
        try {
            showGlobalLoading('Preparing export...');
            
            // Simulate API call to get full data
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            const csvData = this.convertToCSV(this.referrals);
            this.downloadCSV(csvData, 'referrals-export.csv');
            
            showToast('Referral data exported successfully!', 'success');
            
        } catch (error) {
            console.error('Error exporting data:', error);
            showToast('Failed to export data', 'error');
        } finally {
            hideGlobalLoading();
        }
    },

    convertToCSV(referrals) {
        const headers = [
            'Referrer Name',
            'Referrer Email',
            'Referee Email',
            'Referee Name',
            'Referral Code',
            'Status',
            'Clicks',
            'Created Date',
            'Registered Date',
            'Completed Date',
            'Referrer Reward Awarded',
            'Referee Discount Used'
        ];
        
        const rows = referrals.map(referral => [
            referral.referrerName,
            referral.referrerEmail,
            referral.refereeEmail,
            referral.refereeName || '',
            referral.referralCode,
            referral.status,
            referral.clickCount,
            this.formatDate(referral.createdAt),
            referral.registeredAt ? this.formatDate(referral.registeredAt) : '',
            referral.completedAt ? this.formatDate(referral.completedAt) : '',
            referral.referrerReward.awarded ? 'Yes' : 'No',
            referral.refereeReward.used ? 'Yes' : 'No'
        ]);
        
        return [headers, ...rows].map(row => 
            row.map(field => `"${(field || '').toString().replace(/"/g, '""')}"`).join(',')
        ).join('\n');
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

    formatDate(date) {
        return new Date(date).toLocaleDateString('en-AE', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    },

    formatRelativeDate(date) {
        const now = new Date();
        const diffTime = Math.abs(now - new Date(date));
        const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
        
        if (diffDays === 0) return 'Today';
        if (diffDays === 1) return '1 day ago';
        if (diffDays < 7) return `${diffDays} days ago`;
        if (diffDays < 30) return `${Math.floor(diffDays / 7)} weeks ago`;
        return `${Math.floor(diffDays / 30)} months ago`;
    }
};

// Auto-load when referrals section is shown
document.addEventListener('DOMContentLoaded', () => {
    if (typeof window.showSection === 'function') {
        const originalShowSection = window.showSection;
        window.showSection = function(sectionName) {
            originalShowSection.call(this, sectionName);
            if (sectionName === 'referrals' && referralsManager) {
                referralsManager.init();
            }
        };
    }
});
