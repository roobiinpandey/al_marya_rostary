/* Common Utilities Module */

// Common utility functions used across all admin modules

// Production-safe logger
const logger = {
    isDevelopment() {
        return window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
    },
    
    log(...args) {
        if (this.isDevelopment()) {
            console.log(...args);
        }
    },
    
    warn(...args) {
        if (this.isDevelopment()) {
            console.warn(...args);
        }
    },
    
    error(...args) {
        // Always log errors (in production, these should be sent to error tracking service)
        console.error(...args);
        // TODO: In production, send to error tracking service (Sentry, LogRocket, etc.)
    },
    
    info(...args) {
        if (this.isDevelopment()) {
            console.info(...args);
        }
    },
    
    debug(...args) {
        if (this.isDevelopment()) {
            console.debug(...args);
        }
    }
};

// Animation and Performance utilities
const performanceTracker = {
    startTime: performance.now(),
    
    mark(label) {
        const time = performance.now();
        logger.log(`Performance Mark [${label}]: ${(time - this.startTime).toFixed(2)}ms`);
        return time;
    },

    measure(startTime, label) {
        const endTime = performance.now();
        const duration = endTime - startTime;
        logger.log(`Performance Measure [${label}]: ${duration.toFixed(2)}ms`);
        return duration;
    }
};

// Animation helpers
const animations = {
    fadeIn(element, duration = 300) {
        element.style.opacity = '0';
        element.style.display = 'block';
        
        const start = performance.now();
        
        function animate(currentTime) {
            const elapsed = currentTime - start;
            const progress = Math.min(elapsed / duration, 1);
            
            element.style.opacity = progress;
            
            if (progress < 1) {
                requestAnimationFrame(animate);
            }
        }
        
        requestAnimationFrame(animate);
    },

    slideDown(element, duration = 300) {
        element.style.height = '0';
        element.style.overflow = 'hidden';
        element.style.display = 'block';
        
        const fullHeight = element.scrollHeight;
        const start = performance.now();
        
        function animate(currentTime) {
            const elapsed = currentTime - start;
            const progress = Math.min(elapsed / duration, 1);
            
            element.style.height = (fullHeight * progress) + 'px';
            
            if (progress === 1) {
                element.style.height = 'auto';
                element.style.overflow = 'visible';
            } else {
                requestAnimationFrame(animate);
            }
        }
        
        requestAnimationFrame(animate);
    },

    pulse(element) {
        element.style.transform = 'scale(1.05)';
        element.style.transition = 'transform 0.15s ease';
        
        setTimeout(() => {
            element.style.transform = 'scale(1)';
        }, 150);
    }
};

// Data validation utilities
const validation = {
    email(email) {
        const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return re.test(email);
    },

    phone(phone) {
        const re = /^[\+]?[1-9][\d]{0,15}$/;
        return re.test(phone.replace(/\s/g, ''));
    },

    required(value) {
        return value !== null && value !== undefined && value.toString().trim().length > 0;
    },

    minLength(value, min) {
        return value && value.toString().length >= min;
    },

    maxLength(value, max) {
        return value && value.toString().length <= max;
    },

    numeric(value) {
        return !isNaN(parseFloat(value)) && isFinite(value);
    },

    price(value) {
        const price = parseFloat(value);
        return !isNaN(price) && price >= 0;
    }
};

// Form handling utilities
const formUtils = {
    getFormData(formElement) {
        const formData = new FormData(formElement);
        const data = {};
        
        for (let [key, value] of formData.entries()) {
            if (data[key]) {
                // Handle multiple values (like checkboxes)
                if (Array.isArray(data[key])) {
                    data[key].push(value);
                } else {
                    data[key] = [data[key], value];
                }
            } else {
                data[key] = value;
            }
        }
        
        return data;
    },

    validateForm(formElement, rules) {
        const data = this.getFormData(formElement);
        const errors = {};
        
        for (const [field, fieldRules] of Object.entries(rules)) {
            const value = data[field];
            
            for (const rule of fieldRules) {
                if (typeof rule === 'function') {
                    const result = rule(value);
                    if (result !== true) {
                        if (!errors[field]) errors[field] = [];
                        errors[field].push(result);
                    }
                }
            }
        }
        
        return {
            isValid: Object.keys(errors).length === 0,
            errors: errors,
            data: data
        };
    },

    showFieldErrors(formElement, errors) {
        // Clear previous errors
        formElement.querySelectorAll('.field-error').forEach(el => el.remove());
        formElement.querySelectorAll('.is-invalid').forEach(el => el.classList.remove('is-invalid'));
        
        // Show new errors
        for (const [field, fieldErrors] of Object.entries(errors)) {
            const input = formElement.querySelector(`[name="${field}"]`);
            if (input) {
                input.classList.add('is-invalid');
                
                const errorDiv = document.createElement('div');
                errorDiv.className = 'field-error text-danger small mt-1';
                errorDiv.textContent = Array.isArray(fieldErrors) ? fieldErrors[0] : fieldErrors;
                
                input.parentNode.appendChild(errorDiv);
            }
        }
    }
};

// Data formatting utilities
const formatters = {
    currency(amount, currency = 'AED') {
        const num = parseFloat(amount);
        if (isNaN(num)) return `0.00 ${currency}`;
        
        return `${num.toFixed(2)} ${currency}`;
    },

    date(dateString, options = {}) {
        const date = new Date(dateString);
        if (isNaN(date.getTime())) return 'Invalid Date';
        
        const defaultOptions = {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        };
        
        return date.toLocaleDateString('en-US', { ...defaultOptions, ...options });
    },

    time(dateString) {
        const date = new Date(dateString);
        if (isNaN(date.getTime())) return 'Invalid Time';
        
        return date.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit'
        });
    },

    datetime(dateString) {
        return `${this.date(dateString)} ${this.time(dateString)}`;
    },

    fileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    },

    truncate(text, maxLength = 100) {
        if (!text || text.length <= maxLength) return text;
        return text.substring(0, maxLength) + '...';
    },

    capitalize(text) {
        if (!text) return '';
        return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase();
    },

    phone(phoneNumber) {
        if (!phoneNumber) return '';
        const cleaned = phoneNumber.replace(/\D/g, '');
        
        if (cleaned.length === 10) {
            return cleaned.replace(/(\d{3})(\d{3})(\d{4})/, '($1) $2-$3');
        } else if (cleaned.length === 11 && cleaned[0] === '1') {
            return cleaned.replace(/(\d{1})(\d{3})(\d{3})(\d{4})/, '+$1 ($2) $3-$4');
        }
        
        return phoneNumber; // Return original if format not recognized
    }
};

// Storage utilities
const storage = {
    set(key, value) {
        try {
            localStorage.setItem(key, JSON.stringify(value));
            return true;
        } catch (error) {
            logger.error('Error saving to localStorage:', error);
            return false;
        }
    },

    get(key, defaultValue = null) {
        try {
            const item = localStorage.getItem(key);
            return item ? JSON.parse(item) : defaultValue;
        } catch (error) {
            logger.error('Error reading from localStorage:', error);
            return defaultValue;
        }
    },

    remove(key) {
        try {
            localStorage.removeItem(key);
            return true;
        } catch (error) {
            logger.error('Error removing from localStorage:', error);
            return false;
        }
    },

    clear() {
        try {
            localStorage.clear();
            return true;
        } catch (error) {
            logger.error('Error clearing localStorage:', error);
            return false;
        }
    }
};

// Debounce utility
function debounce(func, wait, immediate = false) {
    let timeout;
    
    return function executedFunction(...args) {
        const later = () => {
            timeout = null;
            if (!immediate) func(...args);
        };
        
        const callNow = immediate && !timeout;
        
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
        
        if (callNow) func(...args);
    };
}

// Throttle utility
function throttle(func, limit) {
    let inThrottle;
    
    return function(...args) {
        if (!inThrottle) {
            func.apply(this, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
}

// Array utilities
const arrayUtils = {
    unique(array) {
        return [...new Set(array)];
    },

    groupBy(array, key) {
        return array.reduce((groups, item) => {
            const group = typeof key === 'function' ? key(item) : item[key];
            groups[group] = groups[group] || [];
            groups[group].push(item);
            return groups;
        }, {});
    },

    sortBy(array, key, direction = 'asc') {
        return [...array].sort((a, b) => {
            const aVal = typeof key === 'function' ? key(a) : a[key];
            const bVal = typeof key === 'function' ? key(b) : b[key];
            
            if (aVal < bVal) return direction === 'asc' ? -1 : 1;
            if (aVal > bVal) return direction === 'asc' ? 1 : -1;
            return 0;
        });
    },

    chunk(array, size) {
        const chunks = [];
        for (let i = 0; i < array.length; i += size) {
            chunks.push(array.slice(i, i + size));
        }
        return chunks;
    }
};

// URL utilities
const urlUtils = {
    getParams() {
        return new URLSearchParams(window.location.search);
    },

    getParam(name) {
        return this.getParams().get(name);
    },

    setParam(name, value) {
        const params = this.getParams();
        params.set(name, value);
        const newUrl = `${window.location.pathname}?${params.toString()}`;
        window.history.replaceState({}, '', newUrl);
    },

    removeParam(name) {
        const params = this.getParams();
        params.delete(name);
        const newUrl = params.toString() 
            ? `${window.location.pathname}?${params.toString()}`
            : window.location.pathname;
        window.history.replaceState({}, '', newUrl);
    }
};

// Color utilities
const colorUtils = {
    hexToRgb(hex) {
        const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        return result ? {
            r: parseInt(result[1], 16),
            g: parseInt(result[2], 16),
            b: parseInt(result[3], 16)
        } : null;
    },

    rgbToHex(r, g, b) {
        return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
    },

    getContrastColor(hexColor) {
        const rgb = this.hexToRgb(hexColor);
        if (!rgb) return '#000000';
        
        const brightness = (rgb.r * 299 + rgb.g * 587 + rgb.b * 114) / 1000;
        return brightness > 128 ? '#000000' : '#ffffff';
    }
};

// Export utilities for use in other modules
window.adminUtils = {
    logger,
    performanceTracker,
    animations,
    validation,
    formUtils,
    formatters,
    storage,
    debounce,
    throttle,
    arrayUtils,
    urlUtils,
    colorUtils
};
