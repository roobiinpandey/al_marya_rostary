/* Settings Management Module */

async function loadSettings() {
    try {
        showLoading('settingsContent');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/settings?includePrivate=true`);
        const data = await handleApiResponse(response);
        
        if (data.success) {
            // Flatten the settings object (from categorized to flat)
            const flatSettings = {};
            for (const category in data.data) {
                for (const key in data.data[category]) {
                    flatSettings[key] = data.data[category][key].value;
                }
            }
            renderSettings(flatSettings);
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
                               value="${settings.app_name || 'Al Marya Rostery'}" />
                    </div>
                    <div class="form-group">
                        <label>Contact Email</label>
                        <input type="email" class="form-control" id="storeEmail" 
                               value="${settings.contact_email || 'info@almaryarostery.com'}" />
                    </div>
                    <div class="form-group">
                        <label>Contact Phone</label>
                        <input type="tel" class="form-control" id="storePhone" 
                               value="${settings.contact_phone || '+971 XX XXX XXXX'}" />
                    </div>
                    <div class="form-group">
                        <label>WhatsApp Number</label>
                        <input type="tel" class="form-control" id="whatsappNumber" 
                               value="${settings.whatsapp_number || '+971 XX XXX XXXX'}" />
                    </div>
                    <div class="form-group">
                        <label>Business Hours</label>
                        <input type="text" class="form-control" id="businessHours" 
                               value="${settings.business_hours || '9:00 AM - 10:00 PM'}" 
                               placeholder="e.g., 9:00 AM - 10:00 PM" />
                    </div>
                    <div class="form-group">
                        <label>Store Address</label>
                        <textarea class="form-control" id="storeAddress" rows="3">${settings.address || 'Dubai, UAE'}</textarea>
                        <small class="form-text text-muted">This address will be used for map navigation</small>
                    </div>
                </div>
            </div>

            <div class="settings-section">
                <h3><i class="fas fa-map-marker-alt"></i> Store Location (Google Maps)</h3>
                <div class="alert alert-info">
                    <i class="fas fa-info-circle"></i> 
                    <strong>How to get your store coordinates:</strong><br>
                    1. Open <a href="https://www.google.com/maps" target="_blank">Google Maps</a><br>
                    2. Search for your store or right-click on your location<br>
                    3. Click on the coordinates (e.g., 25.0760, 55.1320) at the top or in the popup<br>
                    4. The coordinates will be copied - paste them below<br>
                    5. Format: First number is Latitude, second is Longitude
                </div>
                <div class="settings-grid">
                    <div class="form-group">
                        <label>Latitude <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="storeLatitude" 
                               value="${settings.store_latitude || ''}" 
                               placeholder="e.g., 25.0760" />
                        <small class="form-text text-muted">Example: 25.0760 (Dubai Marina)</small>
                    </div>
                    <div class="form-group">
                        <label>Longitude <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="storeLongitude" 
                               value="${settings.store_longitude || ''}" 
                               placeholder="e.g., 55.1320" />
                        <small class="form-text text-muted">Example: 55.1320 (Dubai Marina)</small>
                    </div>
                </div>
                <div class="form-group">
                    <button type="button" class="btn btn-secondary" onclick="testMapLocation()">
                        <i class="fas fa-map-marked-alt"></i> Test Location in Google Maps
                    </button>
                </div>
            </div>

            <div class="settings-section">
                <h3><i class="fas fa-shopping-cart"></i> Order Settings</h3>
                <div class="settings-grid">
                    <div class="form-group">
                        <label>Minimum Order Amount (AED)</label>
                        <input type="number" class="form-control" id="minOrderAmount" 
                               value="${settings.minimum_order_amount || 0}" step="0.01" />
                    </div>
                    <div class="form-group">
                        <label>Delivery Fee (AED)</label>
                        <input type="number" class="form-control" id="deliveryFee" 
                               value="${settings.delivery_fee || 0}" step="0.01" />
                    </div>
                    <div class="form-group">
                        <label>Free Delivery Threshold (AED)</label>
                        <input type="number" class="form-control" id="freeDeliveryThreshold" 
                               value="${settings.free_delivery_threshold || 100}" step="0.01" />
                    </div>
                    <div class="form-group">
                        <label>Tax Rate (%)</label>
                        <input type="number" class="form-control" id="taxRate" 
                               value="${settings.tax_rate || 5}" step="0.01" />
                    </div>
                </div>
            </div>

            <div class="settings-section">
                <h3><i class="fas fa-bell"></i> Notification Settings</h3>
                <div class="settings-grid">
                    <div class="form-group">
                        <label class="checkbox-label">
                            <input type="checkbox" id="emailNotifications" 
                                   ${settings.email_notifications_enabled !== false ? 'checked' : ''} />
                            <span>Enable Email Notifications</span>
                        </label>
                    </div>
                    <div class="form-group">
                        <label class="checkbox-label">
                            <input type="checkbox" id="orderNotifications" 
                                   ${settings.order_status_notifications !== false ? 'checked' : ''} />
                            <span>New Order Notifications</span>
                        </label>
                    </div>
                    <div class="form-group">
                        <label class="checkbox-label">
                            <input type="checkbox" id="lowStockNotifications" 
                                   ${settings.low_stock_notifications !== false ? 'checked' : ''} />
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
                            <option value="DD/MM/YYYY" ${settings.date_format === 'DD/MM/YYYY' ? 'selected' : ''}>DD/MM/YYYY</option>
                            <option value="MM/DD/YYYY" ${settings.date_format === 'MM/DD/YYYY' ? 'selected' : ''}>MM/DD/YYYY</option>
                            <option value="YYYY-MM-DD" ${settings.date_format === 'YYYY-MM-DD' ? 'selected' : ''}>YYYY-MM-DD</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="checkbox-label">
                            <input type="checkbox" id="maintenanceMode" 
                                   ${settings.maintenance_mode ? 'checked' : ''} />
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
                               value="${settings.primary_color || '#8B4513'}" />
                    </div>
                    <div class="form-group">
                        <label>Secondary Color</label>
                        <input type="color" class="form-control" id="secondaryColor" 
                               value="${settings.secondary_color || '#D2691E'}" />
                    </div>
                    <div class="form-group">
                        <label>Logo URL</label>
                        <input type="text" class="form-control" id="logoUrl" 
                               value="${settings.logo_url || '/assets/images/logo.png'}" />
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
        // Map frontend field names to database keys
        const settings = {
            // Store Information -> General & Business
            'app_name': document.getElementById('storeName')?.value,
            'contact_email': document.getElementById('storeEmail')?.value,
            'contact_phone': document.getElementById('storePhone')?.value,
            'whatsapp_number': document.getElementById('whatsappNumber')?.value,
            'business_hours': document.getElementById('businessHours')?.value,
            'address': document.getElementById('storeAddress')?.value,
            'store_latitude': document.getElementById('storeLatitude')?.value,
            'store_longitude': document.getElementById('storeLongitude')?.value,
            
            // Order Settings -> Business
            'minimum_order_amount': parseFloat(document.getElementById('minOrderAmount')?.value || 0),
            'delivery_fee': parseFloat(document.getElementById('deliveryFee')?.value || 0),
            'free_delivery_threshold': parseFloat(document.getElementById('freeDeliveryThreshold')?.value || 100),
            'tax_rate': parseFloat(document.getElementById('taxRate')?.value || 5),
            
            // Notification Settings -> Notification
            'email_notifications_enabled': document.getElementById('emailNotifications')?.checked,
            'order_status_notifications': document.getElementById('orderNotifications')?.checked,
            'low_stock_notifications': document.getElementById('lowStockNotifications')?.checked,
            
            // System Settings -> Business & General
            'currency': document.getElementById('currency')?.value,
            'timezone': document.getElementById('timezone')?.value,
            'date_format': document.getElementById('dateFormat')?.value,
            'maintenance_mode': document.getElementById('maintenanceMode')?.checked,
            
            // Appearance Settings -> Business
            'primary_color': document.getElementById('primaryColor')?.value,
            'secondary_color': document.getElementById('secondaryColor')?.value,
            'logo_url': document.getElementById('logoUrl')?.value
        };

        showGlobalLoading('Saving settings...');
        
        const response = await authenticatedFetch(`${API_BASE_URL}/api/admin/settings/bulk`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ settings })
        });
        
        const data = await handleApiResponse(response);
        
        hideGlobalLoading();
        
        if (data.success) {
            showToast('✅ Settings saved successfully!', 'success');
            // Reload settings to show the saved values
            setTimeout(() => loadSettings(), 500);
        } else {
            showToast('❌ Failed to save settings: ' + (data.message || 'Unknown error'), 'error');
        }
    } catch (error) {
        hideGlobalLoading();
        const logger = window.adminUtils?.logger || console;
        logger.error('Error saving settings:', error);
        showToast('❌ Error saving settings. Please try again.', 'error');
    }
}

// Test the map location by opening Google Maps with the coordinates
function testMapLocation() {
    const latitude = document.getElementById('storeLatitude')?.value;
    const longitude = document.getElementById('storeLongitude')?.value;
    
    if (!latitude || !longitude) {
        showToast('⚠️ Please enter both latitude and longitude first!', 'warning');
        return;
    }
    
    // Validate coordinates
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    
    if (isNaN(lat) || isNaN(lng)) {
        showToast('❌ Invalid coordinates! Please enter valid numbers.', 'error');
        return;
    }
    
    if (lat < -90 || lat > 90) {
        showToast('❌ Latitude must be between -90 and 90!', 'error');
        return;
    }
    
    if (lng < -180 || lng > 180) {
        showToast('❌ Longitude must be between -180 and 180!', 'error');
        return;
    }
    
    // Open Google Maps with the coordinates
    const mapsUrl = `https://www.google.com/maps/search/?api=1&query=${lat},${lng}`;
    window.open(mapsUrl, '_blank');
    showToast('✅ Opening Google Maps with your store location...', 'success');
}
