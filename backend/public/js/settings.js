/* Settings Management Module */

async function loadSettings() {
    try {
        showLoading('settingsContent');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/settings`);
        const data = await handleApiResponse(response);
        
        if (data.success) {
            renderSettings(data.data);
        } else {
            showErrorById('settingsContent', 'Failed to load settings');
        }
    } catch (error) {
        const logger = window.adminUtils?.logger || console;
        logger.error('Error loading settings:', error);
        renderSettingsUI(); // Show UI even if API fails
    }
}

function renderSettings(settings = {}) {
    renderSettingsUI(settings);
}

function renderSettingsUI(settings = {}) {
    const settingsHTML = `
        <div class="settings-container">
            <div class="settings-section">
                <h3><i class="fas fa-store"></i> Store Information</h3>
                <div class="settings-grid">
                    <div class="form-group">
                        <label>Store Name</label>
                        <input type="text" class="form-control" id="storeName" 
                               value="${settings.storeName || 'Al Marya Rostery'}" />
                    </div>
                    <div class="form-group">
                        <label>Contact Email</label>
                        <input type="email" class="form-control" id="storeEmail" 
                               value="${settings.storeEmail || 'info@almaryarostery.com'}" />
                    </div>
                    <div class="form-group">
                        <label>Contact Phone</label>
                        <input type="tel" class="form-control" id="storePhone" 
                               value="${settings.storePhone || '+971 XX XXX XXXX'}" />
                    </div>
                    <div class="form-group">
                        <label>Store Address</label>
                        <textarea class="form-control" id="storeAddress" rows="3">${settings.storeAddress || 'Dubai, UAE'}</textarea>
                    </div>
                </div>
            </div>

            <div class="settings-section">
                <h3><i class="fas fa-shopping-cart"></i> Order Settings</h3>
                <div class="settings-grid">
                    <div class="form-group">
                        <label>Minimum Order Amount (AED)</label>
                        <input type="number" class="form-control" id="minOrderAmount" 
                               value="${settings.minOrderAmount || 0}" step="0.01" />
                    </div>
                    <div class="form-group">
                        <label>Delivery Fee (AED)</label>
                        <input type="number" class="form-control" id="deliveryFee" 
                               value="${settings.deliveryFee || 0}" step="0.01" />
                    </div>
                    <div class="form-group">
                        <label>Free Delivery Threshold (AED)</label>
                        <input type="number" class="form-control" id="freeDeliveryThreshold" 
                               value="${settings.freeDeliveryThreshold || 100}" step="0.01" />
                    </div>
                    <div class="form-group">
                        <label>Tax Rate (%)</label>
                        <input type="number" class="form-control" id="taxRate" 
                               value="${settings.taxRate || 5}" step="0.01" />
                    </div>
                </div>
            </div>

            <div class="settings-section">
                <h3><i class="fas fa-bell"></i> Notification Settings</h3>
                <div class="settings-grid">
                    <div class="form-group">
                        <label class="checkbox-label">
                            <input type="checkbox" id="emailNotifications" 
                                   ${settings.emailNotifications !== false ? 'checked' : ''} />
                            <span>Enable Email Notifications</span>
                        </label>
                    </div>
                    <div class="form-group">
                        <label class="checkbox-label">
                            <input type="checkbox" id="orderNotifications" 
                                   ${settings.orderNotifications !== false ? 'checked' : ''} />
                            <span>New Order Notifications</span>
                        </label>
                    </div>
                    <div class="form-group">
                        <label class="checkbox-label">
                            <input type="checkbox" id="lowStockNotifications" 
                                   ${settings.lowStockNotifications !== false ? 'checked' : ''} />
                            <span>Low Stock Alerts</span>
                        </label>
                    </div>
                </div>
            </div>

            <div class="settings-section">
                <h3><i class="fas fa-cog"></i> System Settings</h3>
                <div class="settings-grid">
                    <div class="form-group">
                        <label>Currency</label>
                        <select class="form-control" id="currency">
                            <option value="AED" ${settings.currency === 'AED' ? 'selected' : ''}>AED - UAE Dirham</option>
                            <option value="USD" ${settings.currency === 'USD' ? 'selected' : ''}>USD - US Dollar</option>
                            <option value="EUR" ${settings.currency === 'EUR' ? 'selected' : ''}>EUR - Euro</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Timezone</label>
                        <select class="form-control" id="timezone">
                            <option value="Asia/Dubai" ${settings.timezone === 'Asia/Dubai' ? 'selected' : ''}>Asia/Dubai (GMT+4)</option>
                            <option value="UTC" ${settings.timezone === 'UTC' ? 'selected' : ''}>UTC (GMT+0)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Date Format</label>
                        <select class="form-control" id="dateFormat">
                            <option value="DD/MM/YYYY" ${settings.dateFormat === 'DD/MM/YYYY' ? 'selected' : ''}>DD/MM/YYYY</option>
                            <option value="MM/DD/YYYY" ${settings.dateFormat === 'MM/DD/YYYY' ? 'selected' : ''}>MM/DD/YYYY</option>
                            <option value="YYYY-MM-DD" ${settings.dateFormat === 'YYYY-MM-DD' ? 'selected' : ''}>YYYY-MM-DD</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="checkbox-label">
                            <input type="checkbox" id="maintenanceMode" 
                                   ${settings.maintenanceMode ? 'checked' : ''} />
                            <span>Maintenance Mode</span>
                        </label>
                    </div>
                </div>
            </div>

            <div class="settings-section">
                <h3><i class="fas fa-palette"></i> Appearance Settings</h3>
                <div class="settings-grid">
                    <div class="form-group">
                        <label>Primary Color</label>
                        <input type="color" class="form-control" id="primaryColor" 
                               value="${settings.primaryColor || '#8B4513'}" />
                    </div>
                    <div class="form-group">
                        <label>Secondary Color</label>
                        <input type="color" class="form-control" id="secondaryColor" 
                               value="${settings.secondaryColor || '#D2691E'}" />
                    </div>
                    <div class="form-group">
                        <label>Logo URL</label>
                        <input type="text" class="form-control" id="logoUrl" 
                               value="${settings.logoUrl || '/assets/images/logo.png'}" />
                    </div>
                </div>
            </div>

            <div class="settings-actions">
                <button class="btn btn-primary" onclick="saveSettings()">
                    <i class="fas fa-save"></i> Save Settings
                </button>
                <button class="btn btn-secondary" onclick="loadSettings()">
                    <i class="fas fa-redo"></i> Reset
                </button>
            </div>
        </div>

        <style>
            .settings-container {
                max-width: 1200px;
                margin: 0 auto;
            }
            .settings-section {
                background: white;
                padding: 2rem;
                margin-bottom: 2rem;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            .settings-section h3 {
                margin-top: 0;
                margin-bottom: 1.5rem;
                color: #333;
                font-size: 1.25rem;
            }
            .settings-section h3 i {
                margin-right: 0.5rem;
                color: #8B4513;
            }
            .settings-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 1.5rem;
            }
            .form-group {
                display: flex;
                flex-direction: column;
            }
            .form-group label {
                margin-bottom: 0.5rem;
                font-weight: 500;
                color: #555;
            }
            .form-control {
                padding: 0.75rem;
                border: 1px solid #ddd;
                border-radius: 4px;
                font-size: 1rem;
            }
            .form-control:focus {
                outline: none;
                border-color: #8B4513;
            }
            .checkbox-label {
                display: flex;
                align-items: center;
                cursor: pointer;
            }
            .checkbox-label input[type="checkbox"] {
                margin-right: 0.5rem;
                width: 18px;
                height: 18px;
                cursor: pointer;
            }
            .settings-actions {
                display: flex;
                gap: 1rem;
                justify-content: flex-end;
                padding: 2rem;
                background: white;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
        </style>
    `;
    
    document.getElementById('settingsContent').innerHTML = settingsHTML;
}

async function saveSettings() {
    try {
        const settings = {
            storeName: document.getElementById('storeName')?.value,
            storeEmail: document.getElementById('storeEmail')?.value,
            storePhone: document.getElementById('storePhone')?.value,
            storeAddress: document.getElementById('storeAddress')?.value,
            minOrderAmount: parseFloat(document.getElementById('minOrderAmount')?.value || 0),
            deliveryFee: parseFloat(document.getElementById('deliveryFee')?.value || 0),
            freeDeliveryThreshold: parseFloat(document.getElementById('freeDeliveryThreshold')?.value || 100),
            taxRate: parseFloat(document.getElementById('taxRate')?.value || 5),
            emailNotifications: document.getElementById('emailNotifications')?.checked,
            orderNotifications: document.getElementById('orderNotifications')?.checked,
            lowStockNotifications: document.getElementById('lowStockNotifications')?.checked,
            currency: document.getElementById('currency')?.value,
            timezone: document.getElementById('timezone')?.value,
            dateFormat: document.getElementById('dateFormat')?.value,
            maintenanceMode: document.getElementById('maintenanceMode')?.checked,
            primaryColor: document.getElementById('primaryColor')?.value,
            secondaryColor: document.getElementById('secondaryColor')?.value,
            logoUrl: document.getElementById('logoUrl')?.value
        };

        showGlobalLoading('Saving settings...');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/settings`, {
            method: 'PUT',
            body: JSON.stringify(settings)
        });
        
        const data = await handleApiResponse(response);
        
        hideGlobalLoading();
        
        if (data.success) {
            showToast('Settings saved successfully', 'success');
        } else {
            showToast('Failed to save settings', 'error');
        }
    } catch (error) {
        hideGlobalLoading();
        const logger = window.adminUtils?.logger || console;
        logger.error('Error saving settings:', error);
        showToast('Error saving settings. Please try again.', 'error');
    }
}
