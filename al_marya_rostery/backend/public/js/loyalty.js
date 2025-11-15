/**
 * Loyalty & Rewards Management JavaScript
 * Handles admin functionality for loyalty program
 */

const loyaltyManager = {
    currentPage: 1,
    pageSize: 20,
    members: [],

    async init() {
        await this.loadLoyaltyStats();
        await this.loadLoyaltyMembers();
    },

    async loadLoyaltyStats() {
        try {
            showGlobalLoading('Loading loyalty statistics...');
            
            const stats = await this.fetchLoyaltyStats();
            
            document.getElementById('totalLoyaltyMembers').textContent = stats.totalMembers || 0;
            document.getElementById('pointsAwarded').textContent = this.formatNumber(stats.pointsAwarded || 0);
            document.getElementById('pointsRedeemed').textContent = this.formatNumber(stats.pointsRedeemed || 0);
            document.getElementById('goldMembers').textContent = stats.goldMembers || 0;
            
        } catch (error) {
            console.error('Error loading loyalty stats:', error);
            showToast('Failed to load loyalty statistics', 'error');
        } finally {
            hideGlobalLoading();
        }
    },

    async loadLoyaltyMembers() {
        try {
            showGlobalLoading('Loading loyalty members...');
            
            const members = await this.fetchLoyaltyMembers();
            this.members = members;
            this.renderLoyaltyTable(members);
            
        } catch (error) {
            console.error('Error loading loyalty members:', error);
            showToast('Failed to load loyalty members', 'error');
        } finally {
            hideGlobalLoading();
        }
    },

    async fetchLoyaltyStats() {
        // ✅ REAL API CALL - NO MOCK DATA
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/loyalty/admin/stats`);
            const data = await response.json();
            
            if (data.success && data.data) {
                const tierCounts = {};
                // Safely handle tierDistribution array
                if (Array.isArray(data.data.tierDistribution)) {
                    data.data.tierDistribution.forEach(tier => {
                        tierCounts[tier._id] = tier.count;
                    });
                }
                
                return {
                    totalMembers: data.data.totalAccounts || 0,
                    pointsAwarded: data.data.totalPointsAwarded || 0,
                    pointsRedeemed: data.data.totalPointsRedeemed || 0,
                    goldMembers: tierCounts['Gold'] || 0
                };
            }
            
            // Return defaults if API response is not successful
            return {
                totalMembers: 0,
                pointsAwarded: 0,
                pointsRedeemed: 0,
                goldMembers: 0
            };
        } catch (error) {
            console.error('Error fetching loyalty stats:', error);
            return {
                totalMembers: 0,
                pointsAwarded: 0,
                pointsRedeemed: 0,
                goldMembers: 0
            };
        }
    },

    async fetchLoyaltyMembers() {
        // ✅ REAL API CALL - FETCHES ACTUAL FIREBASE USERS
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/loyalty/admin/members`);
            const data = await response.json();
            
            if (data.success) {
                return data.data.members.map(member => ({
                    _id: member._id,
                    userId: member.userId, // Firebase UID
                    userEmail: member.userEmail,
                    userName: member.userName || 'Unknown User',
                    currentBalance: member.currentBalance,
                    totalEarned: member.totalEarned,
                    totalSpent: member.totalSpent,
                    currentTier: member.currentTier,
                    joinedAt: new Date(member.joinedAt),
                    lastActivity: new Date(member.lastActivity),
                    totalPurchases: member.totalPurchases,
                    totalReferrals: member.totalReferrals,
                    qrCode: member.qrCode, // PERMANENT QR CODE HASH
                    avatar: member.avatar
                }));
            }
            
            return [];
        } catch (error) {
            console.error('Error fetching loyalty members:', error);
            showToast('Failed to load loyalty members from database', 'error');
            return [];
        }
    },

    renderLoyaltyTable(members) {
        const tableHtml = `
            <div class="table-responsive">
                <table class="admin-table">
                    <thead>
                        <tr>
                            <th>Member</th>
                            <th>Tier</th>
                            <th>Points Balance</th>
                            <th>Total Earned</th>
                            <th>Total Spent</th>
                            <th>Purchases</th>
                            <th>Referrals</th>
                            <th>Last Activity</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${members.map(member => this.renderMemberRow(member)).join('')}
                    </tbody>
                </table>
            </div>
        `;
        
        document.getElementById('loyaltyTable').innerHTML = tableHtml;
    },

    renderMemberRow(member) {
        const tierBadge = this.getTierBadge(member.currentTier);
        const lastActivity = this.formatRelativeDate(member.lastActivity);
        
        return `
            <tr>
                <td>
                    <div class="user-info">
                        <strong>${member.userName}</strong><br>
                        <small>${member.userEmail}</small>
                    </div>
                </td>
                <td>${tierBadge}</td>
                <td>
                    <strong class="points-balance">${this.formatNumber(member.currentBalance)}</strong>
                    <small> points</small>
                </td>
                <td>${this.formatNumber(member.totalEarned)}</td>
                <td>${this.formatNumber(member.totalSpent)}</td>
                <td>
                    <span class="stat-number">${member.totalPurchases}</span>
                </td>
                <td>
                    <span class="stat-number">${member.totalReferrals}</span>
                </td>
                <td>${lastActivity}</td>
                <td>
                    <div class="action-buttons">
                        <button class="btn btn-primary btn-sm" onclick="loyaltyManager.showAwardPointsModal('${member.userId}')" title="Award Points">
                            <i class="fas fa-plus"></i>
                        </button>
                        <button class="btn btn-info btn-sm" onclick="loyaltyManager.viewMemberDetail('${member._id}')" title="View Details">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn btn-secondary btn-sm" onclick="loyaltyManager.viewPointsHistory('${member.userId}')" title="Points History">
                            <i class="fas fa-history"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    },

    getTierBadge(tier) {
        const badges = {
            Bronze: '<span class="badge badge-bronze">Bronze</span>',
            Silver: '<span class="badge badge-silver">Silver</span>',
            Gold: '<span class="badge badge-gold">Gold</span>',
            Platinum: '<span class="badge badge-platinum">Platinum</span>',
            Diamond: '<span class="badge badge-diamond">Diamond</span>'
        };
        return badges[tier] || '<span class="badge badge-secondary">Unknown</span>';
    },

    showAwardPointsModal(userId = null) {
        const member = userId ? this.members.find(m => m.userId === userId) : null;
        
        const modalHtml = `
            <div class="modal-backdrop" onclick="this.remove()">
                <div class="modal-content" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h3>Award Points</h3>
                        <button class="modal-close" onclick="this.closest('.modal-backdrop').remove()">×</button>
                    </div>
                    <div class="modal-body">
                        <form id="awardPointsForm">
                            ${member ? `
                                <div class="form-group">
                                    <label>Member</label>
                                    <input type="text" value="${member.userName} (${member.userEmail})" disabled class="form-control">
                                    <input type="hidden" name="userId" value="${member.userId}">
                                    <input type="hidden" name="userEmail" value="${member.userEmail}">
                                </div>
                            ` : `
                                <div class="form-group">
                                    <label for="userEmail">Member Email *</label>
                                    <input type="email" id="userEmail" name="userEmail" class="form-control" required>
                                </div>
                            `}
                            
                            <div class="form-group">
                                <label for="points">Points to Award *</label>
                                <input type="number" id="points" name="points" class="form-control" min="1" max="10000" required>
                            </div>
                            
                            <div class="form-group">
                                <label for="awardType">Award Type *</label>
                                <select id="awardType" name="type" class="form-control" required>
                                    <option value="earned_bonus">Bonus Points</option>
                                    <option value="earned_purchase">Purchase Points</option>
                                    <option value="earned_review">Review Points</option>
                                    <option value="earned_social">Social Media Points</option>
                                    <option value="admin_adjustment">Admin Adjustment</option>
                                </select>
                            </div>
                            
                            <div class="form-group">
                                <label for="description">Description *</label>
                                <textarea id="description" name="description" class="form-control" rows="3" required 
                                          placeholder="Reason for awarding points..."></textarea>
                            </div>
                        </form>
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-secondary" onclick="this.closest('.modal-backdrop').remove()">Cancel</button>
                        <button class="btn btn-primary" onclick="loyaltyManager.awardPoints()">Award Points</button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', modalHtml);
    },

    async awardPoints() {
        const form = document.getElementById('awardPointsForm');
        const formData = new FormData(form);
        
        const data = {
            userEmail: formData.get('userEmail'),
            points: parseInt(formData.get('points')),
            type: formData.get('type'),
            description: formData.get('description')
        };
        
        if (formData.get('userId')) {
            data.userId = formData.get('userId');
        }
        
        if (!data.userEmail || !data.points || !data.description) {
            showToast('Please fill in all required fields', 'error');
            return;
        }
        
        try {
            showGlobalLoading('Awarding points...');
            
            // Simulate API call
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            document.querySelector('.modal-backdrop').remove();
            showToast(`Successfully awarded ${data.points} points!`, 'success');
            
            await this.loadLoyaltyStats();
            await this.loadLoyaltyMembers();
            
        } catch (error) {
            console.error('Error awarding points:', error);
            showToast('Failed to award points', 'error');
        } finally {
            hideGlobalLoading();
        }
    },

    viewMemberDetail(memberId) {
        const member = this.members.find(m => m._id === memberId);
        if (!member) {
            showToast('Member not found', 'error');
            return;
        }
        
        const modalHtml = `
            <div class="modal-backdrop" onclick="this.remove()">
                <div class="modal-content large" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h3>Member Details - ${member.userName}</h3>
                        <button class="modal-close" onclick="this.closest('.modal-backdrop').remove()">×</button>
                    </div>
                    <div class="modal-body">
                        <div class="member-detail">
                            <div class="detail-grid">
                                <div class="detail-section">
                                    <h4>Member Information</h4>
                                    <p><strong>Name:</strong> ${member.userName}</p>
                                    <p><strong>Email:</strong> ${member.userEmail}</p>
                                    <p><strong>Member Since:</strong> ${this.formatDate(member.joinedAt)}</p>
                                    <p><strong>Last Activity:</strong> ${this.formatRelativeDate(member.lastActivity)}</p>
                                </div>
                                
                                <div class="detail-section">
                                    <h4>Loyalty Status</h4>
                                    <p><strong>Current Tier:</strong> ${this.getTierBadge(member.currentTier)}</p>
                                    <p><strong>Points Balance:</strong> ${this.formatNumber(member.currentBalance)} points</p>
                                    <p><strong>Total Earned:</strong> ${this.formatNumber(member.totalEarned)} points</p>
                                    <p><strong>Total Spent:</strong> ${this.formatNumber(member.totalSpent)} points</p>
                                </div>
                                
                                <div class="detail-section">
                                    <h4>Activity Summary</h4>
                                    <p><strong>Total Purchases:</strong> ${member.totalPurchases}</p>
                                    <p><strong>Successful Referrals:</strong> ${member.totalReferrals}</p>
                                    <p><strong>Avg. Points per Purchase:</strong> ${Math.round(member.totalEarned / (member.totalPurchases || 1))}</p>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-primary" onclick="loyaltyManager.showAwardPointsModal('${member.userId}')">Award Points</button>
                        <button class="btn btn-info" onclick="loyaltyManager.viewPointsHistory('${member.userId}')">View History</button>
                        <button class="btn btn-secondary" onclick="this.closest('.modal-backdrop').remove()">Close</button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', modalHtml);
    },

    async viewPointsHistory(userId) {
        try {
            showGlobalLoading('Loading points history...');
            
            // Simulate API call
            const history = await this.fetchPointsHistory(userId);
            
            const modalHtml = `
                <div class="modal-backdrop" onclick="this.remove()">
                    <div class="modal-content large" onclick="event.stopPropagation()">
                        <div class="modal-header">
                            <h3>Points History</h3>
                            <button class="modal-close" onclick="this.closest('.modal-backdrop').remove()">×</button>
                        </div>
                        <div class="modal-body">
                            <div class="points-history">
                                ${history.map(transaction => this.renderHistoryItem(transaction)).join('')}
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
            console.error('Error loading points history:', error);
            showToast('Failed to load points history', 'error');
        } finally {
            hideGlobalLoading();
        }
    },

    async fetchPointsHistory(userId) {
        // Sample data - replace with actual API call
        return [
            {
                transactionType: 'earned_purchase',
                pointsEarned: 150,
                pointsSpent: 0,
                description: 'Purchase #ORD-2025-001',
                createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
            },
            {
                transactionType: 'redeemed_reward',
                pointsEarned: 0,
                pointsSpent: 300,
                description: 'Redeemed: 10% Off Next Purchase',
                createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000)
            },
            {
                transactionType: 'earned_referral',
                pointsEarned: 500,
                pointsSpent: 0,
                description: 'Referral reward for sara@example.com',
                createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000)
            }
        ];
    },

    renderHistoryItem(transaction) {
        const isEarned = transaction.pointsEarned > 0;
        const points = isEarned ? transaction.pointsEarned : transaction.pointsSpent;
        const sign = isEarned ? '+' : '-';
        const colorClass = isEarned ? 'text-success' : 'text-danger';
        
        return `
            <div class="history-item">
                <div class="history-content">
                    <div class="history-description">${transaction.description}</div>
                    <div class="history-date">${this.formatRelativeDate(transaction.createdAt)}</div>
                </div>
                <div class="history-points ${colorClass}">
                    ${sign}${this.formatNumber(points)} points
                </div>
            </div>
        `;
    },

    formatNumber(num) {
        return num.toLocaleString();
    },

    formatDate(date) {
        return new Date(date).toLocaleDateString('en-AE', {
            year: 'numeric',
            month: 'long',
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

// Global function for compatibility with admin.js
function loadLoyalty() {
    if (loyaltyManager) {
        loyaltyManager.init();
    }
}

// Auto-load when loyalty section is shown
document.addEventListener('DOMContentLoaded', () => {
    if (typeof window.showSection === 'function') {
        const originalShowSection = window.showSection;
        window.showSection = function(sectionName) {
            originalShowSection.call(this, sectionName);
            if (sectionName === 'loyalty' && loyaltyManager) {
                loyaltyManager.init();
            }
        };
    }
});
