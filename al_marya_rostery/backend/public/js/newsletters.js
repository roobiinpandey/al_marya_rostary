/**
 * Newsletters Management Module
 * Handles newsletter subscriber management and campaign creation
 */

const newslettersManager = {
    subscribers: [],
    newsletters: [],
    currentTab: 'campaigns',
    currentNewsletter: null,
    
    async init() {
        await this.loadNewsletterStats();
        await this.loadNewsletters();
        this.switchTab('campaigns');
    },

    async loadNewsletterStats() {
        showGlobalLoading();
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
            hideGlobalLoading();
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

    // Tab Management
    switchTab(tab) {
        this.currentTab = tab;
        
        // Update tab buttons
        document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
        event?.target?.classList.add('active');
        
        // Update tab content
        if (tab === 'campaigns') {
            document.getElementById('campaignsTab').style.display = 'block';
            document.getElementById('subscribersTab').style.display = 'none';
            if (this.newsletters.length === 0) {
                this.loadNewsletters();
            }
        } else {
            document.getElementById('campaignsTab').style.display = 'none';
            document.getElementById('subscribersTab').style.display = 'block';
            if (this.subscribers.length === 0) {
                this.loadSubscribers();
            }
        }
    },

    // Newsletter/Campaign Management
    async loadNewsletters(status = 'all') {
        showGlobalLoading();
        try {
            let url = `${API_BASE_URL}/api/newsletters`;
            if (status !== 'all') {
                url += `?status=${status}`;
            }
            
            const response = await authenticatedFetch(url);
            const data = await response.json();
            
            if (data.success) {
                this.newsletters = data.data;
                this.renderNewsletters(this.newsletters);
            }
        } catch (error) {
            console.error('Error loading newsletters:', error);
            showError('Failed to load campaigns');
        } finally {
            hideGlobalLoading();
        }
    },

    renderNewsletters(newsletters) {
        const grid = document.getElementById('campaignsGrid');
        
        if (!newsletters || newsletters.length === 0) {
            grid.innerHTML = `
                <div class="campaigns-empty" style="grid-column: 1 / -1;">
                    <i class="fas fa-paper-plane"></i>
                    <h3>No Campaigns Yet</h3>
                    <p>Create your first newsletter campaign to get started!</p>
                    <button class="btn btn-primary" onclick="newslettersManager.showCreateNewsletterModal()">
                        <i class="fas fa-plus"></i> Create Campaign
                    </button>
                </div>
            `;
            return;
        }

        grid.innerHTML = newsletters.map(newsletter => `
            <div class="campaign-card" data-id="${newsletter._id}">
                <div class="campaign-card-header">
                    <div>
                        <div class="campaign-card-title">${newsletter.title}</div>
                        <div class="campaign-card-subject">${newsletter.subject}</div>
                    </div>
                    <span class="campaign-status-badge ${newsletter.status}">${newsletter.status.toUpperCase()}</span>
                </div>
                
                ${newsletter.deliveryStats ? `
                    <div class="campaign-card-stats">
                        <div class="campaign-stat">
                            <i class="fas fa-paper-plane"></i>
                            <span>${newsletter.deliveryStats.totalSent || 0} sent</span>
                        </div>
                        <div class="campaign-stat">
                            <i class="fas fa-check"></i>
                            <span>${newsletter.deliveryStats.successCount || 0} delivered</span>
                        </div>
                        ${newsletter.deliveryStats.totalOpened ? `
                            <div class="campaign-stat">
                                <i class="fas fa-eye"></i>
                                <span>${newsletter.deliveryStats.totalOpened} opened</span>
                            </div>
                        ` : ''}
                    </div>
                ` : ''}
                
                ${newsletter.scheduledDate && newsletter.status === 'scheduled' ? `
                    <div style="margin-top: 12px; font-size: 12px; color: #666;">
                        <i class="fas fa-clock"></i> Scheduled: ${new Date(newsletter.scheduledDate).toLocaleString()}
                    </div>
                ` : ''}
                
                <div class="campaign-card-actions">
                    ${newsletter.status === 'draft' || newsletter.status === 'scheduled' ? `
                        <button class="btn btn-sm btn-primary" onclick="newslettersManager.editNewsletter('${newsletter._id}')">
                            <i class="fas fa-edit"></i> Edit
                        </button>
                        <button class="btn btn-sm btn-success" onclick="newslettersManager.sendNewsletterById('${newsletter._id}')">
                            <i class="fas fa-paper-plane"></i> Send
                        </button>
                    ` : ''}
                    ${newsletter.status === 'sent' ? `
                        <button class="btn btn-sm btn-info" onclick="newslettersManager.viewNewsletter('${newsletter._id}')">
                            <i class="fas fa-eye"></i> View
                        </button>
                    ` : ''}
                    <button class="btn btn-sm btn-danger" onclick="newslettersManager.deleteNewsletter('${newsletter._id}')">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </div>
        `).join('');
    },

    showCreateNewsletterModal() {
        this.currentNewsletter = null;
        document.getElementById('newsletterModalTitle').innerHTML = '<i class="fas fa-envelope"></i> Create Newsletter';
        document.getElementById('newsletterForm').reset();
        document.getElementById('newsletterId').value = '';
        document.getElementById('newsletterModal').style.display = 'flex';
    },

    async editNewsletter(id) {
        showGlobalLoading();
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/newsletters/${id}`);
            const data = await response.json();
            
            if (data.success) {
                this.currentNewsletter = data.data;
                this.populateNewsletterForm(data.data);
                document.getElementById('newsletterModal').style.display = 'flex';
            }
        } catch (error) {
            console.error('Error loading newsletter:', error);
            showError('Failed to load newsletter');
        } finally {
            hideGlobalLoading();
        }
    },

    populateNewsletterForm(newsletter) {
        document.getElementById('newsletterModalTitle').innerHTML = '<i class="fas fa-edit"></i> Edit Newsletter';
        document.getElementById('newsletterId').value = newsletter._id;
        document.getElementById('newsletterTitle').value = newsletter.title;
        document.getElementById('newsletterSubject').value = newsletter.subject;
        document.getElementById('newsletterHtmlContent').value = newsletter.content.html;
        document.getElementById('newsletterTextContent').value = newsletter.content.text || '';
        document.getElementById('campaignType').value = newsletter.metadata?.campaignType || 'newsletter';
        document.getElementById('priority').value = newsletter.metadata?.priority || 'normal';
        
        // Set target audience
        const audience = newsletter.targetAudience?.[0] || 'all';
        document.querySelector(`input[name="targetAudience"][value="${audience}"]`)?.click();
        
        if (audience === 'specific-emails' && newsletter.recipientEmails) {
            document.getElementById('recipientEmails').value = newsletter.recipientEmails.join(', ');
        }
        
        if (newsletter.scheduledDate) {
            const date = new Date(newsletter.scheduledDate);
            document.getElementById('scheduledDate').value = date.toISOString().slice(0, 16);
        }
    },

    async saveNewsletter(event) {
        event.preventDefault();
        
        const newsletterId = document.getElementById('newsletterId').value;
        const formData = this.getNewsletterFormData();
        
        showGlobalLoading();
        try {
            const url = newsletterId 
                ? `${API_BASE_URL}/api/newsletters/${newsletterId}`
                : `${API_BASE_URL}/api/newsletters`;
            
            const method = newsletterId ? 'PUT' : 'POST';
            
            const response = await authenticatedFetch(url, {
                method,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });
            
            const data = await response.json();
            
            if (data.success) {
                showSuccess(`Newsletter ${newsletterId ? 'updated' : 'created'} successfully`);
                this.closeNewsletterModal();
                await this.loadNewsletters();
                await this.loadNewsletterStats();
            } else {
                showError(data.message || 'Failed to save newsletter');
            }
        } catch (error) {
            console.error('Error saving newsletter:', error);
            showError('Failed to save newsletter');
        } finally {
            hideGlobalLoading();
        }
    },

    getNewsletterFormData() {
        const targetAudience = document.querySelector('input[name="targetAudience"]:checked').value;
        const recipientEmails = targetAudience === 'specific-emails' 
            ? document.getElementById('recipientEmails').value.split(',').map(e => e.trim()).filter(Boolean)
            : [];
        
        return {
            title: document.getElementById('newsletterTitle').value.trim(),
            subject: document.getElementById('newsletterSubject').value.trim(),
            htmlContent: document.getElementById('newsletterHtmlContent').value.trim(),
            textContent: document.getElementById('newsletterTextContent').value.trim(),
            targetAudience: [targetAudience],
            recipientEmails,
            scheduledDate: document.getElementById('scheduledDate').value || null,
            campaignType: document.getElementById('campaignType').value,
            priority: document.getElementById('priority').value
        };
    },

    async sendNewsletterNow() {
        if (!confirm('Are you sure you want to send this newsletter immediately?')) return;
        
        const newsletterId = document.getElementById('newsletterId').value;
        
        if (!newsletterId) {
            // Save first, then send
            await this.saveNewsletter(new Event('submit'));
            return;
        }
        
        await this.sendNewsletterById(newsletterId);
    },

    async sendNewsletterById(id) {
        if (!confirm('Are you sure you want to send this newsletter?')) return;
        
        showGlobalLoading('Sending newsletter...');
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/newsletters/${id}/send`, {
                method: 'POST'
            });
            
            const data = await response.json();
            
            if (data.success) {
                showSuccess('Newsletter sent successfully!');
                this.closeNewsletterModal();
                await this.loadNewsletters();
                await this.loadNewsletterStats();
            } else {
                showError(data.message || 'Failed to send newsletter');
            }
        } catch (error) {
            console.error('Error sending newsletter:', error);
            showError('Failed to send newsletter');
        } finally {
            hideGlobalLoading();
        }
    },

    async sendTestNewsletter() {
        const testEmail = prompt('Enter email address for test:');
        if (!testEmail) return;
        
        const newsletterId = document.getElementById('newsletterId').value;
        if (!newsletterId) {
            showError('Please save the newsletter first');
            return;
        }
        
        showGlobalLoading('Sending test email...');
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/newsletters/${newsletterId}/test`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ testEmails: [testEmail] })
            });
            
            const data = await response.json();
            
            if (data.success) {
                showSuccess(`Test email sent to ${testEmail}`);
            } else {
                showError(data.message || 'Failed to send test email');
            }
        } catch (error) {
            console.error('Error sending test email:', error);
            showError('Failed to send test email');
        } finally {
            hideGlobalLoading();
        }
    },

    async deleteNewsletter(id) {
        if (!confirm('Are you sure you want to delete this newsletter?')) return;
        
        showGlobalLoading();
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/newsletters/${id}`, {
                method: 'DELETE'
            });
            
            const data = await response.json();
            
            if (data.success) {
                showSuccess('Newsletter deleted successfully');
                await this.loadNewsletters();
                await this.loadNewsletterStats();
            } else {
                showError(data.message || 'Failed to delete newsletter');
            }
        } catch (error) {
            console.error('Error deleting newsletter:', error);
            showError('Failed to delete newsletter');
        } finally {
            hideGlobalLoading();
        }
    },

    viewNewsletter(id) {
        const newsletter = this.newsletters.find(n => n._id === id);
        if (!newsletter) return;
        
        // Create preview modal
        const previewHtml = `
            <div class="modal-overlay" onclick="newslettersManager.closePreviewModal()">
                <div class="modal-content" style="max-width: 800px;" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h3><i class="fas fa-eye"></i> ${newsletter.title}</h3>
                        <span class="close" onclick="newslettersManager.closePreviewModal()">&times;</span>
                    </div>
                    <div class="modal-body">
                        <div style="margin-bottom: 20px;">
                            <strong>Subject:</strong> ${newsletter.subject}<br>
                            <strong>Status:</strong> <span class="campaign-status-badge ${newsletter.status}">${newsletter.status}</span><br>
                            ${newsletter.deliveryStats ? `
                                <strong>Sent:</strong> ${newsletter.deliveryStats.totalSent || 0} | 
                                <strong>Delivered:</strong> ${newsletter.deliveryStats.successCount || 0}
                            ` : ''}
                        </div>
                        <hr>
                        <div style="border: 1px solid #ddd; padding: 20px; border-radius: 8px; background: white;">
                            ${newsletter.content.html}
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', previewHtml);
    },

    closePreviewModal() {
        const modal = document.querySelector('.modal-overlay');
        if (modal) modal.remove();
    },

    updateAudienceSelection() {
        const audience = document.querySelector('input[name="targetAudience"]:checked').value;
        const specificEmailsGroup = document.getElementById('specificEmailsGroup');
        
        if (audience === 'specific-emails') {
            specificEmailsGroup.style.display = 'block';
        } else {
            specificEmailsGroup.style.display = 'none';
        }
    },

    useTemplate(type) {
        const templates = {
            welcome: `
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background: #f8f9fa;">
    <div style="background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
        <div style="text-align: center; margin-bottom: 30px;">
            <h1 style="color: #A89A6A; margin: 0;">Welcome to Al Marya Rostery!</h1>
        </div>
        <p style="font-size: 16px; line-height: 1.6; color: #333;">
            Dear Valued Customer,
        </p>
        <p style="font-size: 16px; line-height: 1.6; color: #333;">
            Thank you for subscribing to our newsletter! We're excited to have you as part of our coffee-loving community.
        </p>
        <p style="font-size: 16px; line-height: 1.6; color: #333;">
            Stay tuned for exclusive offers, new product launches, and coffee brewing tips!
        </p>
        <div style="text-align: center; margin: 30px 0;">
            <a href="#" style="background: #A89A6A; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">Shop Now</a>
        </div>
        <p style="font-size: 14px; color: #666; text-align: center;">
            Al Marya Rostery - Premium Coffee Since 2024
        </p>
    </div>
</div>`,
            promotion: `
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background: #f8f9fa;">
    <div style="background: linear-gradient(135deg, #A89A6A 0%, #8d7d55 100%); padding: 40px; border-radius: 10px; color: white; text-align: center;">
        <h1 style="margin: 0 0 10px 0; font-size: 32px;">Special Offer!</h1>
        <p style="font-size: 24px; margin: 0;">Get 20% OFF</p>
        <p style="font-size: 18px; margin: 10px 0;">On All Coffee Products</p>
        <div style="margin: 30px 0;">
            <a href="#" style="background: white; color: #A89A6A; padding: 15px 40px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">Shop Now</a>
        </div>
        <p style="font-size: 14px; opacity: 0.9;">Use code: COFFEE20 at checkout</p>
    </div>
    <div style="background: white; padding: 20px; border-radius: 10px; margin-top: 20px;">
        <p style="font-size: 14px; color: #666; text-align: center;">
            Offer valid until [DATE]. Terms and conditions apply.
        </p>
    </div>
</div>`,
            announcement: `
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background: #f8f9fa;">
    <div style="background: white; padding: 30px; border-radius: 10px;">
        <div style="border-left: 4px solid #A89A6A; padding-left: 20px; margin-bottom: 20px;">
            <h2 style="color: #A89A6A; margin: 0;">📢 Important Announcement</h2>
        </div>
        <p style="font-size: 16px; line-height: 1.6; color: #333;">
            Dear Customers,
        </p>
        <p style="font-size: 16px; line-height: 1.6; color: #333;">
            We're excited to announce [YOUR ANNOUNCEMENT HERE]!
        </p>
        <p style="font-size: 16px; line-height: 1.6; color: #333;">
            [Add more details about your announcement]
        </p>
        <div style="background: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0;">
            <p style="margin: 0; color: #666;">
                <strong>What this means for you:</strong><br>
                • [Benefit 1]<br>
                • [Benefit 2]<br>
                • [Benefit 3]
            </p>
        </div>
        <p style="font-size: 14px; color: #666; text-align: center; margin-top: 30px;">
            Best regards,<br>Al Marya Rostery Team
        </p>
    </div>
</div>`
        };
        
        document.getElementById('newsletterHtmlContent').value = templates[type];
        showSuccess(`${type.charAt(0).toUpperCase() + type.slice(1)} template loaded`);
    },

    closeNewsletterModal() {
        document.getElementById('newsletterModal').style.display = 'none';
        document.getElementById('newsletterForm').reset();
        this.currentNewsletter = null;
    },

    async loadSubscribers() {
        showGlobalLoading();
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
            hideGlobalLoading();
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
        
        showGlobalLoading();
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
            hideGlobalLoading();
        }
    },

    async resubscribeUser(subscriberId) {
        showGlobalLoading();
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
            hideGlobalLoading();
        }
    },

    async deleteSubscriber(subscriberId) {
        if (!confirm('Are you sure you want to permanently delete this subscriber?')) return;
        
        showGlobalLoading();
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
            hideGlobalLoading();
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
        
        showGlobalLoading();
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
            hideGlobalLoading();
        }
    },

    async exportSubscribers() {
        showGlobalLoading();
        try {
            const subscribers = this.subscribers.filter(s => s.isActive);
            const csvData = this.convertToCSV(subscribers);
            this.downloadCSV(csvData, `newsletter-subscribers-${Date.now()}.csv`);
            showSuccess('Subscribers exported successfully');
        } catch (error) {
            console.error('Error exporting subscribers:', error);
            showError('Failed to export subscribers');
        } finally {
            hideGlobalLoading();
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

// Expose to global scope
window.newslettersManager = newslettersManager;

// Initialize when section is shown
if (typeof window.showSection !== 'undefined') {
    const originalShowSection = window.showSection;
    window.showSection = function(section) {
        originalShowSection(section);
        if (section === 'newsletters') {
            setTimeout(() => newslettersManager.init(), 100);
        }
    };
}

// Make sure modal closes with ESC key (wait for DOM)
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
        document.addEventListener('keydown', handleEscapeKey);
    });
} else {
    document.addEventListener('keydown', handleEscapeKey);
}

function handleEscapeKey(e) {
    if (e.key === 'Escape') {
        const modal = document.getElementById('newsletterModal');
        if (modal && modal.style.display === 'flex') {
            newslettersManager.closeNewsletterModal();
        }
    }
}
