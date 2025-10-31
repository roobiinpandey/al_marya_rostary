/**
 * Al Marya Rostery - Banner Analytics Tracking
 * Client-side banner tracking for mobile app and web integration
 */

class BannerTracker {
    constructor(options = {}) {
        this.apiBaseUrl = options.apiBaseUrl || 'http://localhost:5001';
        this.trackingEnabled = options.trackingEnabled !== false;
        this.viewThreshold = options.viewThreshold || 0.5; // 50% visibility threshold
        this.viewTimeout = options.viewTimeout || 1000; // 1 second view duration
        
        this.viewedBanners = new Set();
        this.viewTimeouts = new Map();
        this.intersectionObserver = null;
        
        if (this.trackingEnabled) {
            this.init();
        }
    }
    
    init() {
        // Initialize Intersection Observer for view tracking
        if (typeof IntersectionObserver !== 'undefined') {
            this.setupIntersectionObserver();
        }
        
        // Setup click tracking
        this.setupClickTracking();
        
        console.log('🎯 Banner Analytics Tracking initialized');
    }
    
    setupIntersectionObserver() {
        this.intersectionObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                const bannerId = entry.target.dataset.bannerId;
                // Skip if no ID, or if ID is invalid (undefined, null, empty string)
                if (!bannerId || bannerId === 'undefined' || bannerId === 'null') return;
                
                if (entry.isIntersecting) {
                    // Banner is visible - start view timer
                    this.startViewTimer(bannerId, entry.target);
                } else {
                    // Banner is not visible - cancel view timer
                    this.cancelViewTimer(bannerId);
                }
            });
        }, {
            threshold: this.viewThreshold,
            rootMargin: '0px'
        });
        
        // Observe existing banner elements
        this.observeExistingBanners();
    }
    
    setupClickTracking() {
        document.addEventListener('click', (event) => {
            const bannerElement = event.target.closest('[data-banner-id]');
            if (bannerElement) {
                const bannerId = bannerElement.dataset.bannerId;
                // Skip if ID is invalid
                if (!bannerId || bannerId === 'undefined' || bannerId === 'null') return;
                
                this.trackClick(bannerId, {
                    element: bannerElement,
                    event: event
                });
            }
        });
    }
    
    observeExistingBanners() {
        document.querySelectorAll('[data-banner-id]').forEach(banner => {
            this.observeBanner(banner);
        });
    }
    
    observeBanner(element) {
        const bannerId = element.dataset.bannerId;
        // Only observe if banner has valid ID
        if (this.intersectionObserver && bannerId && bannerId !== 'undefined' && bannerId !== 'null') {
            this.intersectionObserver.observe(element);
        }
    }
    
    startViewTimer(bannerId, element) {
        // Cancel existing timer
        this.cancelViewTimer(bannerId);
        
        // Start new timer
        const timeoutId = setTimeout(() => {
            this.trackView(bannerId, {
                element: element,
                timestamp: Date.now()
            });
        }, this.viewTimeout);
        
        this.viewTimeouts.set(bannerId, timeoutId);
    }
    
    cancelViewTimer(bannerId) {
        const timeoutId = this.viewTimeouts.get(bannerId);
        if (timeoutId) {
            clearTimeout(timeoutId);
            this.viewTimeouts.delete(bannerId);
        }
    }
    
    async trackView(bannerId, metadata = {}) {
        if (this.viewedBanners.has(bannerId)) {
            return; // Already tracked this view
        }
        
        // Validate banner ID (must be a valid MongoDB ObjectID format)
        if (!this.isValidObjectId(bannerId)) {
            console.warn(`Invalid banner ID format: ${bannerId}`);
            return;
        }
        
        try {
            const response = await this.sendTrackingRequest(`/api/sliders/${bannerId}/view`, {
                timestamp: metadata.timestamp || Date.now(),
                userAgent: navigator.userAgent,
                viewport: {
                    width: window.innerWidth,
                    height: window.innerHeight
                }
            });
            
            if (response.success) {
                this.viewedBanners.add(bannerId);
                console.log(`📊 Banner view tracked: ${bannerId}`);
                
                // Dispatch custom event
                this.dispatchTrackingEvent('bannerView', {
                    bannerId,
                    metadata
                });
            }
        } catch (error) {
            // Silently fail - don't spam console with tracking errors
            if (this.apiBaseUrl.includes('localhost')) {
                console.debug('Failed to track banner view:', error.message);
            }
        }
    }
    
    async trackClick(bannerId, metadata = {}) {
        // Validate banner ID
        if (!this.isValidObjectId(bannerId)) {
            console.warn(`Invalid banner ID format: ${bannerId}`);
            return;
        }
        
        try {
            const response = await this.sendTrackingRequest(`/api/sliders/${bannerId}/click`, {
                timestamp: Date.now(),
                userAgent: navigator.userAgent,
                clickPosition: metadata.event ? {
                    x: metadata.event.clientX,
                    y: metadata.event.clientY
                } : null
            });
            
            if (response.success) {
                console.log(`🖱️ Banner click tracked: ${bannerId}`);
                
                // Dispatch custom event
                this.dispatchTrackingEvent('bannerClick', {
                    bannerId,
                    metadata
                });
            }
        } catch (error) {
            // Silently fail - don't spam console with tracking errors
            if (this.apiBaseUrl.includes('localhost')) {
                console.debug('Failed to track banner click:', error.message);
            }
        }
    }
    
    async sendTrackingRequest(endpoint, data) {
        const response = await fetch(`${this.apiBaseUrl}${endpoint}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        return await response.json();
    }
    
    dispatchTrackingEvent(eventType, data) {
        const event = new CustomEvent(`bannerTracking:${eventType}`, {
            detail: data
        });
        document.dispatchEvent(event);
    }
    
    // Validate MongoDB ObjectID format
    isValidObjectId(id) {
        // Check for null, undefined, empty string, or string 'undefined'/'null'
        if (!id || typeof id !== 'string' || id === 'undefined' || id === 'null') {
            return false;
        }
        // MongoDB ObjectID is exactly 24 hex characters
        return /^[0-9a-fA-F]{24}$/.test(id);
    }
    
    // Manual tracking methods for programmatic use
    manualTrackView(bannerId, metadata = {}) {
        return this.trackView(bannerId, metadata);
    }
    
    manualTrackClick(bannerId, metadata = {}) {
        return this.trackClick(bannerId, metadata);
    }
    
    // Add new banner to tracking
    addBanner(bannerElement) {
        if (bannerElement.dataset.bannerId) {
            this.observeBanner(bannerElement);
        }
    }
    
    // Remove banner from tracking
    removeBanner(bannerElement) {
        if (this.intersectionObserver && bannerElement.dataset.bannerId) {
            this.intersectionObserver.unobserve(bannerElement);
            const bannerId = bannerElement.dataset.bannerId;
            this.cancelViewTimer(bannerId);
            this.viewedBanners.delete(bannerId);
        }
    }
    
    // Destroy tracker
    destroy() {
        if (this.intersectionObserver) {
            this.intersectionObserver.disconnect();
        }
        
        // Clear all timers
        this.viewTimeouts.forEach(timeoutId => clearTimeout(timeoutId));
        this.viewTimeouts.clear();
        this.viewedBanners.clear();
        
        console.log('🎯 Banner Analytics Tracking destroyed');
    }
    
    // Get tracking statistics
    getStats() {
        return {
            viewedBanners: Array.from(this.viewedBanners),
            activeTimers: this.viewTimeouts.size,
            trackingEnabled: this.trackingEnabled
        };
    }
}

// Auto-initialize if in browser environment
if (typeof window !== 'undefined') {
    window.BannerTracker = BannerTracker;
    
    // Create global instance
    window.bannerTracker = new BannerTracker({
        apiBaseUrl: window.API_BASE_URL || 'http://localhost:5001',
        trackingEnabled: true
    });
    
    // Listen for dynamic content changes
    if (typeof MutationObserver !== 'undefined') {
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                mutation.addedNodes.forEach((node) => {
                    if (node.nodeType === Node.ELEMENT_NODE) {
                        // Check if the added node is a banner
                        if (node.dataset && node.dataset.bannerId) {
                            window.bannerTracker.addBanner(node);
                        }
                        
                        // Check for banner elements within the added node
                        const banners = node.querySelectorAll && node.querySelectorAll('[data-banner-id]');
                        if (banners) {
                            banners.forEach(banner => window.bannerTracker.addBanner(banner));
                        }
                    }
                });
                
                mutation.removedNodes.forEach((node) => {
                    if (node.nodeType === Node.ELEMENT_NODE) {
                        // Check if the removed node is a banner
                        if (node.dataset && node.dataset.bannerId) {
                            window.bannerTracker.removeBanner(node);
                        }
                        
                        // Check for banner elements within the removed node
                        const banners = node.querySelectorAll && node.querySelectorAll('[data-banner-id]');
                        if (banners) {
                            banners.forEach(banner => window.bannerTracker.removeBanner(banner));
                        }
                    }
                });
            });
        });
        
        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = BannerTracker;
}
