// Contact Inquiries Management System
class ContactInquiriesManager {
    constructor() {
        this.inquiries = [];
        this.currentInquiry = null;
        this.filters = {
            status: '',
            type: '',
            priority: '',
            search: ''
        };
    }

    async init() {
        console.log('📧 Initializing Contact Inquiries Manager...');
        await this.loadInquiries();
    }

    async loadInquiries() {
        try {
            showLoader('contactInquiriesTable');
            
            const statusFilter = document.getElementById('inquiryStatusFilter')?.value || '';
            const typeFilter = document.getElementById('inquiryTypeFilter')?.value || '';
            const priorityFilter = document.getElementById('inquiryPriorityFilter')?.value || '';
            
            let url = '/api/contact-inquiries';
            const params = new URLSearchParams();
            
            if (statusFilter) params.append('status', statusFilter);
            if (typeFilter) params.append('type', typeFilter);
            if (priorityFilter) params.append('priority', priorityFilter);
            
            if (params.toString()) {
                url += '?' + params.toString();
            }

            const response = await fetch(url, {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
                }
            });
            const data = await response.json();

            if (data.success) {
                this.inquiries = data.data || [];
                this.renderInquiriesTable();
            } else {
                throw new Error(data.message || 'Failed to load contact inquiries');
            }
        } catch (error) {
            console.error('Error loading contact inquiries:', error);
            showErrorMessage('Failed to load contact inquiries: ' + error.message);
            document.getElementById('contactInquiriesTable').innerHTML = 
                '<p class="error-message">Failed to load contact inquiries. Please try again.</p>';
        } finally {
            hideLoader('contactInquiriesTable');
        }
    }

    async loadOverdueInquiries() {
        try {
            showLoader('contactInquiriesTable');
            
            const response = await fetch('/api/contact-inquiries/overdue', {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
                }
            });
            const data = await response.json();

            if (data.success) {
                this.inquiries = data.data;
                this.renderInquiriesTable();
                showSuccessMessage(`Found ${data.data.length} overdue inquiries`);
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('Error loading overdue inquiries:', error);
            showErrorMessage('Failed to load overdue inquiries');
        }
    }

    renderInquiriesTable() {
        const container = document.getElementById('contactInquiriesTable');
        
        if (!this.inquiries || this.inquiries.length === 0) {
            container.innerHTML = '<p class="no-data">No contact inquiries found.</p>';
            return;
        }

        // Filter out any malformed inquiries
        const validInquiries = this.inquiries.filter(inquiry => {
            return inquiry && inquiry._id && inquiry.contactInfo && inquiry.createdAt;
        });

        if (validInquiries.length === 0) {
            container.innerHTML = '<p class="no-data">No valid contact inquiries found.</p>';
            return;
        }

        const tableHTML = `
            <div class="table-responsive">
                <table class="admin-table">
                    <thead>
                        <tr>
                            <th>Date</th>
                            <th>Contact</th>
                            <th>Type</th>
                            <th>Subject</th>
                            <th>Priority</th>
                            <th>Status</th>
                            <th>Assigned To</th>
                            <th>SLA</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${validInquiries.map(inquiry => this.renderInquiryRow(inquiry)).join('')}
                    </tbody>
                </table>
            </div>
        `;

        container.innerHTML = tableHTML;
    }

    renderInquiryRow(inquiry) {
        const createdDate = new Date(inquiry.createdAt).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });

        const assignedTo = inquiry.assignment?.assignedTo?.name || 'Unassigned';
        const slaStatus = inquiry.slaStatus || 'On Track';
        
        // Safe access to inquiry properties with fallbacks
        const inquiryData = inquiry.inquiry || {};
        const priority = inquiryData.priority || 'medium';
        const type = inquiryData.type || 'general';
        const subject = inquiryData.subject || 'No Subject';
        const message = inquiryData.message || 'No Message';

        return `
            <tr class="inquiry-row ${priority === 'urgent' ? 'urgent-row' : ''}">
                <td>
                    <div class="date-info">
                        <div class="created-date">${createdDate}</div>
                        <div class="time-since">${inquiry.timeSinceCreated || 'Recently'}</div>
                    </div>
                </td>
                <td>
                    <div class="contact-info">
                        <div class="contact-name">${inquiry.contactInfo?.name || 'Unknown'}</div>
                        <div class="contact-email">${inquiry.contactInfo?.email || 'No Email'}</div>
                        ${inquiry.contactInfo?.company ? `<div class="contact-company">${inquiry.contactInfo.company}</div>` : ''}
                    </div>
                </td>
                <td>
                    <span class="badge badge-${this.getTypeBadgeClass(type)}">${type}</span>
                </td>
                <td>
                    <div class="subject-info">
                        <div class="subject">${subject}</div>
                        <div class="message-preview">${this.truncateText(message, 50)}</div>
                    </div>
                </td>
                <td>
                    <span class="badge badge-${this.getPriorityBadgeClass(priority)}">${priority}</span>
                </td>
                <td>
                    <span class="badge badge-${this.getStatusBadgeClass(inquiry.status?.current || 'new')}">${inquiry.status?.current || 'new'}</span>
                </td>
                <td>
                    <div class="assignment-info">
                        <div class="assigned-to">${assignedTo}</div>
                        ${inquiry.assignment?.department ? `<div class="department">${inquiry.assignment.department}</div>` : ''}
                    </div>
                </td>
                <td>
                    <span class="badge badge-${this.getSLABadgeClass(slaStatus)}">${slaStatus}</span>
                </td>
                <td>
                    <div class="action-buttons">
                        <button class="btn btn-sm btn-primary" onclick="contactInquiriesManager.viewInquiry('${inquiry._id}')" title="View Details">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn btn-sm btn-secondary" onclick="contactInquiriesManager.respondToInquiry('${inquiry._id}')" title="Respond">
                            <i class="fas fa-reply"></i>
                        </button>
                        <button class="btn btn-sm btn-info" onclick="contactInquiriesManager.assignInquiry('${inquiry._id}')" title="Assign">
                            <i class="fas fa-user-plus"></i>
                        </button>
                        <button class="btn btn-sm btn-warning" onclick="contactInquiriesManager.updateStatus('${inquiry._id}')" title="Update Status">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-success" onclick="contactInquiriesManager.addNote('${inquiry._id}')" title="Add Note">
                            <i class="fas fa-sticky-note"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }

    getTypeBadgeClass(type) {
        const typeClasses = {
            'general': 'secondary',
            'product-inquiry': 'info',
            'bulk-order': 'primary',
            'partnership': 'success',
            'complaint': 'danger',
            'feedback': 'warning',
            'technical-support': 'primary',
            'wholesale': 'success',
            'franchise': 'warning',
            'catering': 'info',
            'corporate-gifts': 'primary',
            'return-refund': 'danger',
            'other': 'secondary'
        };
        return typeClasses[type] || 'secondary';
    }

    getPriorityBadgeClass(priority) {
        const priorityClasses = {
            'low': 'secondary',
            'medium': 'info',
            'high': 'warning',
            'urgent': 'danger'
        };
        return priorityClasses[priority] || 'info';
    }

    getStatusBadgeClass(status) {
        const statusClasses = {
            'new': 'primary',
            'in-progress': 'warning',
            'pending-info': 'info',
            'resolved': 'success',
            'closed': 'secondary',
            'escalated': 'danger'
        };
        return statusClasses[status] || 'secondary';
    }

    getSLABadgeClass(slaStatus) {
        if (slaStatus.includes('Overdue')) return 'danger';
        if (slaStatus === 'On Track') return 'success';
        return 'warning';
    }

    truncateText(text, maxLength) {
        if (text.length <= maxLength) return text;
        return text.substring(0, maxLength) + '...';
    }

    async viewInquiry(id) {
        try {
            const response = await fetch(`/api/contact-inquiries/${id}`, {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
                }
            });
            const data = await response.json();

            if (data.success) {
                this.showInquiryDetailsModal(data.data);
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('Error viewing inquiry:', error);
            showErrorMessage('Failed to load inquiry details');
        }
    }

    showInquiryDetailsModal(inquiry) {
        // Safe access to inquiry properties
        const inquiryData = inquiry.inquiry || {};
        const type = inquiryData.type || 'general';
        const priority = inquiryData.priority || 'medium';
        const subject = inquiryData.subject || 'No Subject';
        const message = inquiryData.message || 'No Message';
        
        const responsesHTML = inquiry.responses?.map(response => `
            <div class="response-item ${response.isInternal ? 'internal-response' : 'external-response'}">
                <div class="response-header">
                    <span class="responder">${response.respondedBy?.name || 'Unknown'}</span>
                    <span class="response-date">${new Date(response.sentAt).toLocaleString()}</span>
                    ${response.isInternal ? '<span class="internal-badge">Internal</span>' : ''}
                </div>
                <div class="response-message">${response.message}</div>
            </div>
        `).join('') || '<p>No responses yet</p>';

        const notesHTML = inquiry.internalNotes?.map(note => `
            <div class="note-item">
                <div class="note-header">
                    <span class="note-author">${note.addedBy?.name || 'Unknown'}</span>
                    <span class="note-date">${new Date(note.addedAt).toLocaleString()}</span>
                </div>
                <div class="note-content">${note.note}</div>
            </div>
        `).join('') || '<p>No internal notes</p>';

        const modalHTML = `
            <div class="modal-overlay" onclick="closeModal()">
                <div class="modal-content large-modal" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h3><i class="fas fa-headset"></i> Contact Inquiry Details</h3>
                        <button class="close-btn" onclick="closeModal()">&times;</button>
                    </div>
                    <div class="modal-body">
                        <div class="inquiry-details">
                            <div class="detail-section">
                                <h4>Contact Information</h4>
                                <div class="detail-row">
                                    <label>Name:</label>
                                    <span>${inquiry.contactInfo?.name || 'Unknown'}</span>
                                </div>
                                <div class="detail-row">
                                    <label>Email:</label>
                                    <span>${inquiry.contactInfo?.email || 'No Email'}</span>
                                </div>
                                ${inquiry.contactInfo?.phone ? `
                                    <div class="detail-row">
                                        <label>Phone:</label>
                                        <span>${inquiry.contactInfo.phone}</span>
                                    </div>
                                ` : ''}
                                ${inquiry.contactInfo?.company ? `
                                    <div class="detail-row">
                                        <label>Company:</label>
                                        <span>${inquiry.contactInfo.company}</span>
                                    </div>
                                ` : ''}
                            </div>

                            <div class="detail-section">
                                <h4>Inquiry Details</h4>
                                <div class="detail-row">
                                    <label>Type:</label>
                                    <span class="badge badge-${this.getTypeBadgeClass(type)}">${type}</span>
                                </div>
                                <div class="detail-row">
                                    <label>Priority:</label>
                                    <span class="badge badge-${this.getPriorityBadgeClass(priority)}">${priority}</span>
                                </div>
                                <div class="detail-row">
                                    <label>Subject:</label>
                                    <span>${subject}</span>
                                </div>
                                <div class="detail-row">
                                    <label>Message:</label>
                                    <p class="message-content">${message}</p>
                                </div>
                            </div>

                            <div class="detail-section">
                                <h4>Status & Assignment</h4>
                                <div class="detail-row">
                                    <label>Current Status:</label>
                                    <span class="badge badge-${this.getStatusBadgeClass(inquiry.status.current)}">${inquiry.status.current}</span>
                                </div>
                                <div class="detail-row">
                                    <label>Assigned To:</label>
                                    <span>${inquiry.assignment?.assignedTo?.name || 'Unassigned'}</span>
                                </div>
                                <div class="detail-row">
                                    <label>Department:</label>
                                    <span>${inquiry.assignment?.department || 'N/A'}</span>
                                </div>
                                <div class="detail-row">
                                    <label>SLA Status:</label>
                                    <span class="badge badge-${this.getSLABadgeClass(inquiry.slaStatus)}">${inquiry.slaStatus}</span>
                                </div>
                            </div>

                            <div class="detail-section">
                                <h4>Responses</h4>
                                <div class="responses-list">${responsesHTML}</div>
                            </div>

                            <div class="detail-section">
                                <h4>Internal Notes</h4>
                                <div class="notes-list">${notesHTML}</div>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-secondary" onclick="closeModal()">Close</button>
                        <button class="btn btn-primary" onclick="contactInquiriesManager.respondToInquiry('${inquiry._id}')">Respond</button>
                        <button class="btn btn-info" onclick="contactInquiriesManager.assignInquiry('${inquiry._id}')">Assign</button>
                        <button class="btn btn-warning" onclick="contactInquiriesManager.updateStatus('${inquiry._id}')">Update Status</button>
                    </div>
                </div>
            </div>
        `;

        document.body.insertAdjacentHTML('beforeend', modalHTML);
    }

    async showAnalytics() {
        try {
            const response = await fetch('/api/contact-inquiries/analytics', {
                headers: {
                    'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
                }
            });
            const data = await response.json();

            if (data.success) {
                this.showAnalyticsModal(data.data);
            } else {
                throw new Error(data.message);
            }
        } catch (error) {
            console.error('Error loading analytics:', error);
            showErrorMessage('Failed to load analytics');
        }
    }

    showAnalyticsModal(analytics) {
        const modalHTML = `
            <div class="modal-overlay" onclick="closeModal()">
                <div class="modal-content" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h3><i class="fas fa-chart-bar"></i> Contact Inquiries Analytics</h3>
                        <button class="close-btn" onclick="closeModal()">&times;</button>
                    </div>
                    <div class="modal-body">
                        <div class="analytics-grid">
                            <div class="stat-card">
                                <h4>Total Inquiries</h4>
                                <div class="stat-value">${analytics.summary?.totalInquiries || 0}</div>
                            </div>
                            <div class="stat-card">
                                <h4>Avg Response Time</h4>
                                <div class="stat-value">${analytics.summary?.avgResponseTime?.toFixed(1) || 0}h</div>
                            </div>
                            <div class="stat-card">
                                <h4>Avg Resolution Time</h4>
                                <div class="stat-value">${analytics.summary?.avgResolutionTime?.toFixed(1) || 0}h</div>
                            </div>
                        </div>
                        
                        <div class="distribution-charts">
                            <div class="chart-section">
                                <h4>Status Distribution</h4>
                                <div class="distribution-list">
                                    ${analytics.statusDistribution?.map(item => `
                                        <div class="distribution-item">
                                            <span class="label">${item._id}</span>
                                            <span class="value">${item.count}</span>
                                        </div>
                                    `).join('') || '<p>No data available</p>'}
                                </div>
                            </div>
                            
                            <div class="chart-section">
                                <h4>Type Distribution</h4>
                                <div class="distribution-list">
                                    ${analytics.typeDistribution?.map(item => `
                                        <div class="distribution-item">
                                            <span class="label">${item._id}</span>
                                            <span class="value">${item.count}</span>
                                        </div>
                                    `).join('') || '<p>No data available</p>'}
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button class="btn btn-secondary" onclick="closeModal()">Close</button>
                    </div>
                </div>
            </div>
        `;

        document.body.insertAdjacentHTML('beforeend', modalHTML);
    }

    respondToInquiry(id) {
        // Implementation for respond modal
        console.log('Respond to inquiry modal - to be implemented');
        showErrorMessage('Respond feature coming soon!');
    }

    assignInquiry(id) {
        // Implementation for assign modal
        console.log('Assign inquiry modal - to be implemented');
        showErrorMessage('Assign feature coming soon!');
    }

    updateStatus(id) {
        // Implementation for status update modal
        console.log('Update status modal - to be implemented');
        showErrorMessage('Update status feature coming soon!');
    }

    addNote(id) {
        // Implementation for add note modal
        console.log('Add note modal - to be implemented');
        showErrorMessage('Add note feature coming soon!');
    }
}

// Initialize the contact inquiries manager
const contactInquiriesManager = new ContactInquiriesManager();
