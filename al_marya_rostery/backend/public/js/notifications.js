const notificationsManager = {
    async init() {
        await this.loadStats();
        await this.loadNotifications('all');
    },
    async loadStats() {
        try {
            const res = await fetch('/api/notifications/stats');
            const data = await res.json();
            if(data.success && document.getElementById('notificationStats')) {
                document.getElementById('notificationStats').innerHTML = `<p>Total: ${data.data.total}, Sent: ${data.data.sent}</p>`;
            }
        } catch(e) { console.error(e); }
    },
    async loadNotifications(status) {
        try {
            const res = await fetch('/api/notifications');
            const data = await res.json();
            if(data.success) {
                this.notifications = data.data || [];
                this.render();
            }
        } catch(e) { console.error(e); }
    },
    render() {
        const el = document.getElementById('notificationsList');
        if(!el) return;
        if(this.notifications.length === 0) {
            el.innerHTML = '<p>No notifications</p>';
            return;
        }
        el.innerHTML = this.notifications.map(n => `<div class="card"><h4>${n.title}</h4><p>${n.body}</p><p>Status: ${n.status}</p><button onclick="notificationsManager.send('${n._id}')">Send</button></div>`).join('');
    },
    showCreateNotificationModal() {
        const m = document.getElementById('notificationModal');
        if(m) m.style.display = 'flex';
    },
    closeNotificationModal() {
        const m = document.getElementById('notificationModal');
        if(m) m.style.display = 'none';
    },
    async saveNotification(e) {
        e.preventDefault();
        const fd = new FormData(e.target);
        try {
            const res = await fetch('/api/notifications', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    title: fd.get('title'),
                    body: fd.get('body'),
                    type: fd.get('type'),
                    priority: fd.get('priority'),
                    targetAudience: fd.get('targetAudience'),
                    status: 'draft'
                })
            });
            if((await res.json()).success) {
                this.closeNotificationModal();
                await this.loadNotifications();
            }
        } catch(e) { console.error(e); }
    },
    async send(id) {
        if(!confirm('Send?')) return;
        try {
            await fetch(`/api/notifications/${id}/send`, { method: 'POST' });
            await this.loadNotifications();
        } catch(e) { console.error(e); }
    },
    async delete(id) {
        if(!confirm('Delete?')) return;
        try {
            await fetch(`/api/notifications/${id}`, { method: 'DELETE' });
            await this.loadNotifications();
        } catch(e) { console.error(e); }
    },
    updateTargetSelection() {
        const targetSelect = document.getElementById('notificationTarget');
        const specificUsersGroup = document.getElementById('specificUsersGroup');
        if(!targetSelect || !specificUsersGroup) return;
        
        if(targetSelect.value === 'specific') {
            specificUsersGroup.style.display = 'block';
        } else {
            specificUsersGroup.style.display = 'none';
        }
    },
    async sendTestNotification() {
        showGlobalLoading('Sending test notification...');
        try {
            const title = document.querySelector('#notificationModal [name="title"]').value;
            const message = document.querySelector('#notificationModal [name="body"]').value;
            const res = await fetch('/api/notifications/test', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    title: title,
                    message: message,
                    topic: 'all_users'
                })
            });
            const data = await res.json();
            showToast(data.success ? 'Test notification sent!' : 'Failed to send test', data.success ? 'success' : 'error');
        } catch(e) { 
            console.error(e);
            showToast('Error sending test notification', 'error');
        } finally {
            hideGlobalLoading();
        }
    },
    async sendNotificationNow() {
        const form = document.getElementById('notificationForm');
        if(!form) return;
        const formData = new FormData(form);
        showGlobalLoading('Creating and sending notification...');
        try {
            const createRes = await fetch('/api/notifications', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    title: formData.get('title'),
                    message: formData.get('body'),
                    type: formData.get('type'),
                    priority: formData.get('priority'),
                    targetAudience: formData.get('targetAudience'),
                    scheduledDate: formData.get('scheduledAt') || null,
                    status: 'sent'
                })
            });
            const createData = await createRes.json();
            if(!createData.success) throw new Error(createData.message);
            
            const sendRes = await fetch(`/api/notifications/${createData.data._id}/send`, { method: 'POST' });
            const sendData = await sendRes.json();
            showToast(sendData.success ? 'Notification sent successfully!' : 'Failed to send', sendData.success ? 'success' : 'error');
            this.closeNotificationModal();
            await this.loadNotifications();
        } catch(e) { 
            console.error(e);
            showToast('Error: ' + e.message, 'error');
        } finally {
            hideGlobalLoading();
        }
    }
};
window.notificationsManager = notificationsManager;
