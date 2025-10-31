/**
 * Support Tickets Management Module
 * Handles customer support ticket viewing, response, and status management
 */

const supportTicketsManager = {
    tickets: [],
    currentFilter: 'all',
    
    async init() {
        await this.loadSupportStats();
        await this.loadTickets();
    },

    async loadSupportStats() {
        showLoading();
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/support-tickets/stats`);
            const data = await response.json();
            
            if (data.success) {
                this.renderStats(data.data);
            }
        } catch (error) {
            console.error('Error loading support stats:', error);
            showError('Failed to load support statistics');
        } finally {
            hideLoading();
        }
    },

    renderStats(stats) {
        const statsHtml = `
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
                        <i class="fas fa-ticket-alt"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">${stats.total || 0}</div>
                        <div class="stat-label">Total Tickets</div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);">
                        <i class="fas fa-clock"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">${stats.open || 0}</div>
                        <div class="stat-label">Open Tickets</div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);">
                        <i class="fas fa-user-headset"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">${stats.inProgress || 0}</div>
                        <div class="stat-label">In Progress</div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon" style="background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);">
                        <i class="fas fa-check-circle"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">${stats.resolved || 0}</div>
                        <div class="stat-label">Resolved</div>
                    </div>
                </div>
            </div>
        `;
        
        document.getElementById('supportStats').innerHTML = statsHtml;
    },

    async loadTickets(filter = 'all') {
        showLoading();
        this.currentFilter = filter;
        
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/support-tickets?status=${filter}`);
            const data = await response.json();
            
            if (data.success) {
                this.tickets = data.data;
                this.renderTicketsTable(this.tickets);
            }
        } catch (error) {
            console.error('Error loading tickets:', error);
            showError('Failed to load support tickets');
        } finally {
            hideLoading();
        }
    },

    renderTicketsTable(tickets) {
        if (!tickets || tickets.length === 0) {
            document.getElementById('ticketsTable').innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-ticket-alt"></i>
                    <h3>No Support Tickets</h3>
                    <p>No support tickets found for the selected filter.</p>
                </div>
            `;
            return;
        }

        const tableHtml = `
            <div class="table-container">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Ticket ID</th>
                            <th>Subject</th>
                            <th>User</th>
                            <th>Priority</th>
                            <th>Status</th>
                            <th>Category</th>
                            <th>Created</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${tickets.map(ticket => this.renderTicketRow(ticket)).join('')}
                    </tbody>
                </table>
            </div>
        `;
        
        document.getElementById('ticketsTable').innerHTML = tableHtml;
    },

    renderTicketRow(ticket) {
        const statusBadge = this.getStatusBadge(ticket.status);
        const priorityBadge = this.getPriorityBadge(ticket.priority);
        
        return `
            <tr data-ticket-id="${ticket._id}">
                <td><strong>#${ticket.ticketNumber || ticket._id.slice(-6)}</strong></td>
                <td>
                    <div class="ticket-subject">
                        ${ticket.subject}
                        ${ticket.unread ? '<span class="badge badge-danger" style="font-size: 0.7em;">New</span>' : ''}
                    </div>
                </td>
                <td>
                    <div class="user-info">
                        <strong>${ticket.userName || ticket.userEmail || 'Unknown'}</strong>
                        <small>${ticket.userEmail || ''}</small>
                    </div>
                </td>
                <td>${priorityBadge}</td>
                <td>${statusBadge}</td>
                <td><span class="badge badge-secondary">${ticket.category || 'General'}</span></td>
                <td>${new Date(ticket.createdAt).toLocaleDateString()}</td>
                <td>
                    <button class="btn btn-sm btn-primary" onclick="supportTicketsManager.viewTicket('${ticket._id}')">
                        <i class="fas fa-eye"></i> View
                    </button>
                </td>
            </tr>
        `;
    },

    getStatusBadge(status) {
        const badges = {
            'open': '<span class="badge badge-danger">Open</span>',
            'in-progress': '<span class="badge badge-warning">In Progress</span>',
            'resolved': '<span class="badge badge-success">Resolved</span>',
            'closed': '<span class="badge badge-secondary">Closed</span>'
        };
        return badges[status] || '<span class="badge badge-secondary">Unknown</span>';
    },

    getPriorityBadge(priority) {
        const badges = {
            'low': '<span class="badge badge-info">Low</span>',
            'medium': '<span class="badge badge-warning">Medium</span>',
            'high': '<span class="badge badge-danger">High</span>',
            'urgent': '<span class="badge" style="background: #dc3545;">Urgent</span>'
        };
        return badges[priority] || '<span class="badge badge-secondary">Normal</span>';
    },

    async viewTicket(ticketId) {
        showLoading();
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/support-tickets/${ticketId}`);
            const data = await response.json();
            
            if (data.success) {
                this.showTicketModal(data.data);
            }
        } catch (error) {
            console.error('Error loading ticket:', error);
            showError('Failed to load ticket details');
        } finally {
            hideLoading();
        }
    },

    showTicketModal(ticket) {
        const modalHtml = `
            <div class="modal-overlay" onclick="supportTicketsManager.closeModal()">
                <div class="modal-content large" onclick="event.stopPropagation()">
                    <div class="modal-header">
                        <h2>
                            <i class="fas fa-ticket-alt"></i> 
                            Ticket #${ticket.ticketNumber || ticket._id.slice(-6)}
                        </h2>
                        <button class="close-btn" onclick="supportTicketsManager.closeModal()">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>
                    
                    <div class="modal-body">
                        <div class="ticket-details">
                            <div class="ticket-header-info">
                                <div class="info-group">
                                    <label>Subject:</label>
                                    <strong>${ticket.subject}</strong>
                                </div>
                                <div class="info-group">
                                    <label>Status:</label>
                                    ${this.getStatusBadge(ticket.status)}
                                </div>
                                <div class="info-group">
                                    <label>Priority:</label>
                                    ${this.getPriorityBadge(ticket.priority)}
                                </div>
                                <div class="info-group">
                                    <label>Category:</label>
                                    <span class="badge badge-secondary">${ticket.category || 'General'}</span>
                                </div>
                            </div>
                            
                            <div class="ticket-user-info">
                                <h4>Customer Information</h4>
                                <p><strong>Name:</strong> ${ticket.userName || 'N/A'}</p>
                                <p><strong>Email:</strong> ${ticket.userEmail || 'N/A'}</p>
                                <p><strong>Created:</strong> ${new Date(ticket.createdAt).toLocaleString()}</p>
                            </div>
                            
                            <div class="ticket-message">
                                <h4>Message</h4>
                                <div class="message-content">${ticket.message || 'No message provided'}</div>
                            </div>
                            
                            ${ticket.responses && ticket.responses.length > 0 ? `
                                <div class="ticket-responses">
                                    <h4>Responses (${ticket.responses.length})</h4>
                                    ${ticket.responses.map(response => `
                                        <div class="response-item">
                                            <div class="response-header">
                                                <strong>${response.respondedBy || 'Admin'}</strong>
                                                <small>${new Date(response.createdAt).toLocaleString()}</small>
                                            </div>
                                            <div class="response-message">${response.message}</div>
                                        </div>
                                    `).join('')}
                                </div>
                            ` : ''}
                            
                            <div class="ticket-response-form">
                                <h4>Add Response</h4>
                                <textarea id="responseMessage" class="form-control" rows="4" 
                                    placeholder="Type your response here..."></textarea>
                                <div style="margin-top: 1rem;">
                                    <button class="btn btn-primary" onclick="supportTicketsManager.respondToTicket('${ticket._id}')">
                                        <i class="fas fa-paper-plane"></i> Send Response
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="modal-footer">
                        <div class="status-actions">
                            <label>Update Status:</label>
                            <select id="ticketStatus" class="form-control" style="width: auto; display: inline-block;">
                                <option value="open" ${ticket.status === 'open' ? 'selected' : ''}>Open</option>
                                <option value="in-progress" ${ticket.status === 'in-progress' ? 'selected' : ''}>In Progress</option>
                                <option value="resolved" ${ticket.status === 'resolved' ? 'selected' : ''}>Resolved</option>
                                <option value="closed" ${ticket.status === 'closed' ? 'selected' : ''}>Closed</option>
                            </select>
                            <button class="btn btn-success" onclick="supportTicketsManager.updateTicketStatus('${ticket._id}')">
                                <i class="fas fa-save"></i> Update Status
                            </button>
                        </div>
                        <button class="btn btn-secondary" onclick="supportTicketsManager.closeModal()">
                            Close
                        </button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', modalHtml);
    },

    async respondToTicket(ticketId) {
        const message = document.getElementById('responseMessage').value.trim();
        
        if (!message) {
            showError('Please enter a response message');
            return;
        }
        
        showLoading();
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/support-tickets/${ticketId}/respond`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ message })
            });
            
            const data = await response.json();
            
            if (data.success) {
                showSuccess('Response sent successfully');
                this.closeModal();
                await this.loadTickets(this.currentFilter);
            } else {
                showError(data.message || 'Failed to send response');
            }
        } catch (error) {
            console.error('Error sending response:', error);
            showError('Failed to send response');
        } finally {
            hideLoading();
        }
    },

    async updateTicketStatus(ticketId) {
        const status = document.getElementById('ticketStatus').value;
        
        showLoading();
        try {
            const response = await authenticatedFetch(`${API_BASE_URL}/api/support-tickets/${ticketId}/status`, {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ status })
            });
            
            const data = await response.json();
            
            if (data.success) {
                showSuccess('Ticket status updated successfully');
                this.closeModal();
                await this.loadTickets(this.currentFilter);
                await this.loadSupportStats();
            } else {
                showError(data.message || 'Failed to update status');
            }
        } catch (error) {
            console.error('Error updating status:', error);
            showError('Failed to update ticket status');
        } finally {
            hideLoading();
        }
    },

    closeModal() {
        const modal = document.querySelector('.modal-overlay');
        if (modal) {
            modal.remove();
        }
    },

    async exportTickets() {
        showLoading();
        try {
            const tickets = this.tickets;
            const csvData = this.convertToCSV(tickets);
            this.downloadCSV(csvData, `support-tickets-${Date.now()}.csv`);
            showSuccess('Tickets exported successfully');
        } catch (error) {
            console.error('Error exporting tickets:', error);
            showError('Failed to export tickets');
        } finally {
            hideLoading();
        }
    },

    convertToCSV(tickets) {
        const headers = ['Ticket ID', 'Subject', 'User', 'Email', 'Priority', 'Status', 'Category', 'Created'];
        const rows = tickets.map(ticket => [
            ticket.ticketNumber || ticket._id.slice(-6),
            ticket.subject,
            ticket.userName || 'N/A',
            ticket.userEmail || 'N/A',
            ticket.priority || 'Normal',
            ticket.status,
            ticket.category || 'General',
            new Date(ticket.createdAt).toLocaleDateString()
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
    }
};

// Initialize when section is shown
if (typeof window.showSection !== 'undefined') {
    const originalShowSection = window.showSection;
    window.showSection = function(section) {
        originalShowSection(section);
        if (section === 'support-tickets') {
            supportTicketsManager.init();
        }
    };
}
