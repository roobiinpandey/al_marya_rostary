/* Al Marya Rostery Admin Panel - Main JavaScript File */

// Configuration
const API_BASE_URL = window.location.hostname === 'localhost' 
    ? `http://localhost:${window.location.port || '5001'}` 
    : 'https://al-marya-rostary.onrender.com';

// Global variables
let currentSection = 'dashboard';
let charts = {};
let currentUser = null;
let authToken = null;

// Helper function to validate JWT token format
function isValidToken(token) {
    if (!token || typeof token !== 'string') return false;
    const parts = token.split('.');
    return parts.length === 3 && parts.every(part => part.length > 0);
}

// Initialize admin panel
document.addEventListener('DOMContentLoaded', function() {
    // Initialize login form event listeners first
    initializeLoginForm();
    
    // Then check authentication
    checkAuthentication();
    
    // Track performance
    trackPerformance();
    
    // Use production-safe logger
    const logger = window.adminUtils?.logger || console;
    logger.log('🚀 Al Marya Rostery Admin Panel v2.1 - PRODUCTION EDITION');
    logger.log('🤖 NEW: Automatic Firebase User Sync - Real-time user registration sync');
    logger.log('⚡ Features: Real API Integration, Keyboard Shortcuts, Toast Notifications');
    logger.log('🔐 Security: CSP Headers, Input Sanitization, CSRF Protection');
});

/* ===== AUTHENTICATION FUNCTIONS ===== */

function initializeLoginForm() {
    const usernameInput = document.getElementById('loginUsername');
    const passwordInput = document.getElementById('loginPassword');
    const usernameError = document.getElementById('username-error');
    const passwordError = document.getElementById('password-error');
    const forgotPasswordLink = document.getElementById('forgot-password-link');

    // Focus on username field when page loads
    if (usernameInput && usernameInput.offsetParent !== null) {
        usernameInput.focus();
    }

    // Input validation on blur
    if (usernameInput) {
        usernameInput.addEventListener('blur', function() {
            if (!this.value.trim()) {
                showError(usernameError, 'Username is required');
            } else {
                hideError(usernameError);
            }
        });
    }

    if (passwordInput) {
        passwordInput.addEventListener('blur', function() {
            if (!this.value.trim()) {
                showError(passwordError, 'Password is required');
            } else {
                hideError(passwordError);
            }
        });
    }

    // Forgot password functionality
    if (forgotPasswordLink) {
        forgotPasswordLink.addEventListener('click', function(e) {
            e.preventDefault();
            alert('Please contact system administrator to reset your password.');
        });
    }

    // Form submit handler
    const loginForm = document.getElementById('adminLoginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', function(e) {
            handleLogin(e);
        });
    }
}

function checkAuthentication() {
    authToken = localStorage.getItem('adminToken');
    currentUser = JSON.parse(localStorage.getItem('adminUser') || 'null');
    
    if (authToken && isValidToken(authToken) && currentUser) {
        showAdminPanel();
    } else {
        if (authToken && !isValidToken(authToken)) {
            const logger = window.adminUtils?.logger || console;
            logger.warn('Invalid token format found, clearing localStorage');
            localStorage.removeItem('adminToken');
            localStorage.removeItem('adminUser');
            authToken = null;
            currentUser = null;
        }
        showLoginPage();
    }
}

function showLoginPage() {
    document.body.className = 'login-mode';
    document.getElementById('loginContainer').style.display = 'flex';
    document.getElementById('adminLayout').style.display = 'none';
    
    setTimeout(() => {
        const usernameInput = document.getElementById('loginUsername');
        if (usernameInput) {
            usernameInput.focus();
        }
    }, 100);
}

function showAdminPanel() {
    document.body.className = 'admin-mode';
    document.getElementById('loginContainer').style.display = 'none';
    document.getElementById('adminLayout').style.display = 'block';
    initializeAdmin();
}

async function handleLogin(event) {
    event.preventDefault();
    
    resetErrors();
    
    const username = document.getElementById('loginUsername').value.trim();
    const password = document.getElementById('loginPassword').value.trim();
    const loginBtn = document.getElementById('loginBtn');
    const loginLoading = document.getElementById('loginLoading');
    const usernameError = document.getElementById('username-error');
    const passwordError = document.getElementById('password-error');
    
    let isValid = true;
    
    if (!username) {
        showError(usernameError, 'Username is required');
        isValid = false;
    }
    
    if (!password) {
        showError(passwordError, 'Password is required');
        isValid = false;
    }
    
    if (!isValid) return;
    
    loginBtn.disabled = true;
    loginBtn.textContent = 'Logging in...';
    loginBtn.classList.add('loading');
    loginLoading.style.display = 'block';
    
    try {
        const response = await fetch(`${API_BASE_URL}/api/auth/admin-login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ username: username, password })
        });
        
        const data = await response.json();
        
        if (data.success) {
            authToken = data.data.token;
            currentUser = data.data.user;
            
            localStorage.setItem('adminToken', authToken);
            localStorage.setItem('adminUser', JSON.stringify(currentUser));
            
            document.getElementById('loginSuccess').style.display = 'block';
            
            setTimeout(() => {
                showAdminPanel();
            }, 1000);
        } else {
            throw new Error('Invalid credentials');
        }
    } catch (error) {
        const logger = window.adminUtils?.logger || console;
        logger.error('Login error:', error);
        document.getElementById('loginError').style.display = 'block';
        document.getElementById('loginPassword').value = '';
        document.getElementById('loginPassword').focus();
    } finally {
        loginBtn.disabled = false;
        loginBtn.textContent = 'Login to Admin Panel';
        loginBtn.classList.remove('loading');
        loginLoading.style.display = 'none';
    }
}

function resetErrors() {
    hideError(document.getElementById('username-error'));
    hideError(document.getElementById('password-error'));
    hideError(document.getElementById('loginError'));
    hideError(document.getElementById('loginSuccess'));
}

function showError(errorElement, message) {
    if (errorElement) {
        errorElement.textContent = message;
        errorElement.style.display = 'block';
    }
}

function hideError(errorElement) {
    if (errorElement) {
        errorElement.style.display = 'none';
    }
}

function logout() {
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminUser');
    authToken = null;
    currentUser = null;
    showLoginPage();
}

/* ===== API HELPER FUNCTIONS ===== */

async function authenticatedFetch(url, options = {}) {
    const defaultHeaders = {
        'Content-Type': 'application/json'
    };
    
    if (authToken && isValidToken(authToken)) {
        defaultHeaders['Authorization'] = `Bearer ${authToken}`;
    }
    
    const config = {
        ...options,
        headers: {
            ...defaultHeaders,
            ...options.headers
        }
    };
    
    try {
        const response = await fetch(url, config);
        const logger = window.adminUtils?.logger || console;
        
        if (response.status === 401) {
            logger.warn(`Authentication failed for ${url} - redirecting to login`);
            logout();
            throw new Error('Authentication expired - please login again');
        }
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        return response;
    } catch (error) {
        const logger = window.adminUtils?.logger || console;
        logger.error('API Request failed:', error);
        throw error;
    }
}

async function handleApiResponse(response) {
    if (!response) {
        throw new Error('No response received');
    }
    
    const data = await response.json();
    return data;
}

/* ===== CORE ADMIN FUNCTIONS ===== */

async function initializeAdmin() {
    showGlobalLoading('Initializing Admin Panel...');
    
    initProductionFeatures();
    
    const logger = window.adminUtils?.logger || console;
    try {
        const healthCheck = await fetch(`${API_BASE_URL}/health`);
        if (!healthCheck.ok) {
            logger.warn('Backend health check failed');
        }
    } catch (error) {
        logger.warn('Backend connectivity check failed:', error.message);
        showErrorById('dashboardStats', 'Backend server unavailable - please start the server');
        hideGlobalLoading();
        return;
    }
    
    loadDashboardData();
    loadCategories();
    initializeCharts();
    hideGlobalLoading();
}

function showSection(sectionName) {
    document.querySelectorAll('.content-section').forEach(section => {
        section.classList.remove('active');
    });

    document.querySelectorAll('.menu-item').forEach(item => {
        item.classList.remove('active');
    });

    document.getElementById(sectionName).classList.add('active');
    
    if (event && event.target) {
        event.target.classList.add('active');
    }

    currentSection = sectionName;

    switch(sectionName) {
        case 'dashboard':
            loadDashboardData();
            break;
        case 'analytics':
            loadAnalytics();
            break;
        case 'reports':
            loadReports();
            break;
        case 'products':
            loadProducts();
            break;
        case 'categories':
            loadCategories();
            break;
        case 'orders':
            loadOrders();
            break;
        case 'users':
            loadUsers();
            break;
        case 'sliders':
            loadSliders();
            break;
        case 'settings':
            loadSettings();
            break;
        case 'firebase':
            initializeFirebaseManagement();
            break;
    }
}

/* ===== UTILITY FUNCTIONS ===== */

function showLoading(elementId) {
    document.getElementById(elementId).innerHTML = `
        <div class="loading">
            <i class="fas fa-spinner"></i>
            <p>Loading...</p>
        </div>
    `;
}

function showErrorById(elementId, message) {
    const element = document.getElementById(elementId);
    if (!element) return;
    
    const isBackendDown = message.includes('server') || message.includes('Backend');
    const helpText = isBackendDown ? 
        '<small style="display: block; margin-top: 1rem; opacity: 0.8;">💡 Make sure the backend server is running on port 5001</small>' : 
        '';
        
    element.innerHTML = `
        <div class="text-center" style="padding: 2rem; color: var(--danger);">
            <i class="fas fa-exclamation-triangle" style="font-size: 2rem; margin-bottom: 1rem;"></i>
            <p>${message}</p>
            ${helpText}
        </div>
    `;
}

function showGlobalLoading(message = 'Loading...') {
    document.getElementById('loadingText').textContent = message;
    document.getElementById('globalLoading').style.display = 'flex';
}

function hideGlobalLoading() {
    document.getElementById('globalLoading').style.display = 'none';
}

function showToast(message, type = 'success', duration = 3000) {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    
    const container = document.getElementById('toastContainer');
    container.appendChild(toast);
    
    setTimeout(() => toast.classList.add('show'), 100);
    
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => container.removeChild(toast), 300);
    }, duration);
}

function initializeCharts() {
    // Charts will be initialized when data is loaded
}

function refreshDashboard() {
    loadDashboardData();
}

/* ===== PERFORMANCE & UTILITIES ===== */

function trackPerformance() {
    if ('performance' in window) {
        window.addEventListener('load', () => {
            setTimeout(() => {
                const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart;
                if (loadTime > 0) {
                    const logger = window.adminUtils?.logger || console;
                    logger.log(`Page loaded in ${loadTime}ms`);
                    
                    const perfData = JSON.parse(localStorage.getItem('perfData') || '[]');
                    perfData.push({ 
                        timestamp: Date.now(), 
                        loadTime,
                        userAgent: navigator.userAgent.substring(0, 100)
                    });
                    
                    if (perfData.length > 10) perfData.shift();
                    localStorage.setItem('perfData', JSON.stringify(perfData));
                }
            }, 100);
        });
    }
}

function setupKeyboardShortcuts() {
    document.addEventListener('keydown', (e) => {
        if (e.ctrlKey || e.metaKey) {
            switch(e.key) {
                case 'd':
                    e.preventDefault();
                    showSection('dashboard');
                    showToast('Switched to Dashboard', 'info', 1500);
                    break;
                case 'p':
                    e.preventDefault();
                    showSection('products');
                    showToast('Switched to Products', 'info', 1500);
                    break;
                case 'o':
                    e.preventDefault();
                    showSection('orders');
                    showToast('Switched to Orders', 'info', 1500);
                    break;
                case 'u':
                    e.preventDefault();
                    showSection('users');
                    showToast('Switched to Users', 'info', 1500);
                    break;
            }
        }
    });
}

function initProductionFeatures() {
    setupKeyboardShortcuts();
}

function sanitizeInput(input) {
    if (typeof input !== 'string') return input;
    return input
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#x27;')
        .replace(/\//g, '&#x2F;');
}

// Error Boundary
window.addEventListener('error', (e) => {
    const logger = window.adminUtils?.logger || console;
    logger.error('Global error:', e.error);
    showToast('An unexpected error occurred. Please refresh the page.', 'error', 5000);
});
