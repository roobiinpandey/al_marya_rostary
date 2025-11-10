# Dynamic Certificate Pinning Implementation Guide

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Quick Start](#quick-start)
4. [Detailed Setup](#detailed-setup)
5. [Testing](#testing)
6. [Rollout Procedure](#rollout-procedure)
7. [Troubleshooting](#troubleshooting)
8. [Security Best Practices](#security-best-practices)

---

## Overview

This guide explains how to implement dynamic SSL/TLS certificate pinning in the Al Marya Rostery mobile apps. Dynamic pinning allows the app to verify backend certificates without requiring app updates when certificates are rotated.

### Why Dynamic Pinning?

**Traditional pinning:**
- Hard-coded pins in app
- Requires app update to change pins
- Risk of app lockout if certificate is forgotten during rotation

**Dynamic pinning:**
- Pins fetched from backend at runtime
- Cached locally for offline operation
- Automatic fallback to hardcoded pins if fetch fails
- Zero-downtime certificate rotation

### Key Components

| Component | File | Purpose |
|-----------|------|---------|
| `CertificatePinningService` | `lib/core/security/certificate_pinning_service.dart` | Main pinning verification |
| `DynamicCertificateConfigService` | `lib/core/security/dynamic_certificate_config_service.dart` | Fetch and cache pins |
| Backend Endpoint | `/api/security/certificate-pins` | Serves current pins |

---

## Architecture

### Application Flow

```
App Startup
    ↓
[CertificatePinningService.initialize()]
    ├─ Load cached pins from secure storage
    ├─ Try fetch fresh pins from /api/security/certificate-pins
    ├─ Use latest pins or fall back to cached/hardcoded pins
    └─ Start periodic refresh timer (every 24 hours)
    ↓
When making HTTPS requests
    ├─ Extract certificate pin from response
    ├─ Check against dynamic pins (if loaded)
    ├─ Check against fallback pins
    ├─ Check against hardcoded pins (legacy)
    └─ Allow/reject request based on match
    ↓
Background (every 24 hours)
    ├─ Periodically refresh pins from backend
    └─ Notify app if pins changed
```

### Pin Storage Hierarchy

The app checks pins in this order:
1. **Dynamic Primary Pins** (from API, highest priority)
2. **Dynamic Backup Pins** (from API, for certificate rotation)
3. **Fallback Primary Pins** (hardcoded fallback)
4. **Fallback Backup Pins** (hardcoded fallback)
5. **Hardcoded Legacy Pins** (for backward compatibility)

If ANY pin matches, the certificate is accepted.

### Offline Support

```
Network Available       Network Unavailable
        ↓                       ↓
    Fetch fresh            Use cached pins
    pins from API          (up to 7 days old)
        ↓                       ↓
    Cache locally          Fallback to hardcoded
        ↓                       ↓
    Use fresh pins         Allow HTTPS requests
```

---

## Quick Start

### For App Developers

#### 1. Install Dependencies

No new dependencies needed! The implementation uses:
- `flutter_secure_storage` (already in your project)
- `http` package (already in your project)
- `dart:io` (built-in)

#### 2. Initialize in App Startup

```dart
// In your main.dart or app initialization
import 'package:al_marya_rostery/core/security/certificate_pinning_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize certificate pinning FIRST
  // before making any HTTPS requests
  await CertificatePinningService.initialize();
  
  runApp(const MyApp());
}
```

#### 3. Use in HTTP Client

```dart
import 'dart:io';
import 'package:al_marya_rostery/core/security/certificate_pinning_service.dart';

// Get secure socket context
SecurityContext context = CertificatePinningService.getSecureSocketContext();

// Use with HttpClient
HttpClient client = HttpClient()
  ..badCertificateCallback = (X509Certificate cert, String host, int port) {
    return CertificatePinningService.verifyCertificate(cert, host);
  };

// Or use with dio package
final dio = Dio();
// Dio uses the system HTTP client by default
```

#### 4. Monitor Pinning Status

```dart
// Get current pinning statistics
Map<String, dynamic> stats = CertificatePinningService.getPinningStats();
print('Pinning enabled: ${stats['enabled']}');
print('Total pins: ${stats['total_pins']}');

// Listen for pin updates
final configService = DynamicCertificateConfigService();
configService.onConfigUpdated((config) {
  print('Pins updated to version: ${config.version}');
  // Notify user if needed
});
```

---

## Detailed Setup

### For Backend Developers

#### Step 1: Generate Certificate Pins

Get your backend server's certificate pin:

```bash
# 1. Connect to your server and download certificate
openssl s_client -connect almaryarostary.onrender.com:443 < /dev/null \
  | openssl x509 -out cert.pem

# 2. Extract public key
openssl x509 -in cert.pem -pubkey -noout > pubkey.pem

# 3. Generate SHA256 pin (what the app will verify)
openssl asn1parse -strparse 19 -in pubkey.pem -out /dev/stdout \
  | openssl dgst -sha256 -binary | base64

# Output example:
# 6dxjKzxpMbDFEUx2zVLJ0VnqzJe+yzL0P5hbMlFvtME=
```

**Format**: The app expects pins with `sha256/` prefix:
```
sha256/6dxjKzxpMbDFEUx2zVLJ0VnqzJe+yzL0P5hbMlFvtME=
```

#### Step 2: Implement Backend Endpoint

Create endpoint at `/api/security/certificate-pins`:

```javascript
// Node.js/Express example
router.get('/api/security/certificate-pins', (req, res) => {
  const config = {
    version: "1.0.0",
    primaryPins: [
      "sha256/6dxjKzxpMbDFEUx2zVLJ0VnqzJe+yzL0P5hbMlFvtME="
    ],
    backupPins: [], // For rotation scenarios
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
  };
  
  res.set('Cache-Control', 'public, max-age=86400');
  res.json(config);
});
```

**Required Fields:**
- `version`: String, increment when pins change
- `primaryPins`: Array of at least one valid pin
- `backupPins`: Array (can be empty)
- `expiresAt`: ISO 8601 date string

#### Step 3: Store Pins Securely

Don't commit pins to version control:

```javascript
// ❌ Bad: Hardcoded in code
const pins = ["sha256/xxx"];

// ✅ Good: Load from environment
const pins = process.env.CERTIFICATE_PINS.split(',');

// ✅ Better: Load from secure config service
const pins = await ConfigService.getCertificatePins();

// ✅ Best: Rotate automatically with cert updates
const pins = await getCertificatePinsFromLetsEncrypt();
```

---

## Testing

### Local Testing

#### Test 1: Verify Endpoint is Accessible

```bash
# Should return 200 with correct JSON structure
curl -i https://almaryarostary.onrender.com/api/security/certificate-pins

# Check response
# HTTP/1.1 200 OK
# Content-Type: application/json
# {
#   "version": "1.0.0",
#   "primaryPins": ["sha256/..."],
#   ...
# }
```

#### Test 2: Verify Pin Format

```bash
# Extract your server's actual pin
openssl s_client -connect almaryarostary.onrender.com:443 < /dev/null \
  | openssl x509 -pubkey -noout | openssl asn1parse -strparse 19 -out /dev/stdout \
  | openssl dgst -sha256 -binary | base64

# Compare with what's in /api/security/certificate-pins
# Should match exactly (without sha256/ prefix)
```

#### Test 3: Test with Mobile App

**On macOS/Linux:**
```bash
# Build and run app with logging
flutter run --verbose 2>&1 | grep -i "certificate\|pin\|config"

# Watch for:
# ✅ Fetched fresh config: ...
# ✅ Certificate pin verified (dynamic primary)
```

**On Physical Device (Android):**
```bash
# View logs while app is initializing
adb logcat | grep -i "certificate\|pin\|config"

# Uninstall app, clear cache
adb uninstall com.al_marya.rostery
adb shell pm clear-cache

# Reinstall and watch logs during startup
flutter run
```

**On Physical Device (iOS):**
```bash
# Connect device to macOS
# Open Device Logs in Xcode
# Filter for "certificate" or "pin"
# Run app and watch logs
```

### Integration Test

```dart
// test/core/security/certificate_pinning_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:al_marya_rostery/core/security/certificate_pinning_service.dart';
import 'package:al_marya_rostery/core/security/dynamic_certificate_config_service.dart';

void main() {
  group('Certificate Pinning', () {
    test('Service initializes successfully', () async {
      await CertificatePinningService.initialize();
      final stats = CertificatePinningService.getPinningStats();
      expect(stats['enabled'], true);
    });

    test('Dynamic config service loads config', () async {
      final service = DynamicCertificateConfigService();
      await service.initialize();
      final config = await service.getConfig();
      expect(config, isNotNull);
    });

    test('Cache statistics are accurate', () async {
      final service = DynamicCertificateConfigService();
      final stats = service.getCacheStats();
      expect(stats['initialized'], isNotNull);
    });
  });
}
```

### Monitoring in Production

#### Check Server Logs

```bash
# Monitor /api/security/certificate-pins requests
tail -f /var/log/app/access.log | grep "certificate-pins"

# Should see frequent requests (multiple times per day per app)
# Low error rate (<1%)
# Fast response times (<100ms)
```

#### Monitor App Analytics

Add tracking to your analytics service:

```dart
// Optional: Track pin verification events
AnalyticsService.logEvent(
  name: 'certificate_pin_verified',
  parameters: {
    'host': host,
    'pin_type': 'dynamic_primary', // or 'fallback', 'hardcoded'
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```

#### Common Issues to Monitor

```
1. Certificate Pin Verification Failures
   → Indicates potential MITM or misconfiguration
   → Action: Check app logs, verify pin format

2. High Endpoint Error Rate (>1%)
   → App can't fetch fresh pins
   → Action: Check endpoint availability, ensure correct URL

3. Users Running Outdated App Versions
   → Can't use latest pins
   → Action: Promote app update, monitor version adoption

4. Network Timeouts on Endpoint
   → App falls back to cached pins
   → Action: Optimize endpoint performance, add caching
```

---

## Rollout Procedure

### Phase 1: Initial Deployment (Week 1)

**For Backend Team:**

1. Generate certificate pin for current certificate:
   ```bash
   # Get the pin for your current SSL certificate
   ```

2. Implement `/api/security/certificate-pins` endpoint

3. Return your current certificate pin:
   ```json
   {
     "version": "1.0.0",
     "primaryPins": ["sha256/YOUR_CURRENT_PIN"],
     "backupPins": [],
     "expiresAt": "2025-12-10T10:00:00Z"
   }
   ```

**For Mobile Team:**

1. Add security files to app:
   - `certificate_pinning_service.dart`
   - `dynamic_certificate_config_service.dart`

2. Initialize in `main.dart`:
   ```dart
   await CertificatePinningService.initialize();
   ```

3. Test with staging endpoint first

4. Deploy to production with app update

### Phase 2: Certificate Rotation (When Needed)

When you need to update your SSL certificate:

#### Day 1: Add New Certificate to Backup

```json
{
  "version": "1.0.1",
  "primaryPins": ["sha256/OLD_PIN"],
  "backupPins": ["sha256/NEW_PIN"],
  "expiresAt": "2025-12-10T10:00:00Z"
}
```

1. Deploy new certificate to backend server
2. Update endpoint to include new pin in `backupPins`
3. Deploy updated endpoint
4. Monitor error logs (should be minimal)
5. Wait 24-48 hours for apps to refresh

#### Day 3: Promote New Certificate to Primary

After confirming new certificate is working:

```json
{
  "version": "1.0.2",
  "primaryPins": ["sha256/NEW_PIN"],
  "backupPins": ["sha256/OLD_PIN"],
  "expiresAt": "2025-12-10T10:00:00Z"
}
```

1. Update endpoint (swap primary and backup)
2. Deploy updated endpoint
3. Monitor logs (error rate should drop to near-zero)
4. Wait 1 week for all apps to update

#### Day 7: Remove Old Certificate

```json
{
  "version": "1.0.3",
  "primaryPins": ["sha256/NEW_PIN"],
  "backupPins": [],
  "expiresAt": "2025-12-10T10:00:00Z"
}
```

1. Ensure old certificate is no longer used by any server
2. Update endpoint to remove old pin
3. Deploy updated endpoint
4. Complete!

### Rollback Procedure (If Issues Arise)

If pin verification fails for many users:

1. **Immediate (within 1 hour):**
   - Revert endpoint to previous version
   - Check app logs for error details
   - Verify new pin format is correct

2. **Short-term (1-24 hours):**
   - Users with cached pins will auto-recover
   - No app update required (uses fallback pins)

3. **Long-term:**
   - Fix issue and roll out again following normal phases

---

## Troubleshooting

### Problem: "Certificate pin verification failed"

**Symptoms:**
- User sees connection errors
- App logs show: `❌ Certificate pin verification failed!`

**Diagnosis:**

1. Check pin format:
   ```bash
   # Extract your server's actual pin
   openssl s_client -connect almaryarostary.onrender.com:443 < /dev/null \
     | openssl x509 -pubkey -noout | openssl asn1parse -strparse 19 -out /dev/stdout \
     | openssl dgst -sha256 -binary | base64
   ```

2. Compare with endpoint response:
   ```bash
   curl https://almaryarostary.onrender.com/api/security/certificate-pins | jq '.primaryPins'
   ```

3. Verify pin has `sha256/` prefix in app config

**Solutions:**

- If pins don't match: Regenerate pin (wrong certificate)
- If format is wrong: Add `sha256/` prefix
- If endpoint hasn't updated: Clear app cache and retry

### Problem: App Can't Reach Endpoint

**Symptoms:**
- App logs show: `⚠️ Could not load dynamic pins, using fallback`
- Endpoint request fails with timeout/connection error

**Diagnosis:**

```bash
# Test endpoint accessibility
curl -v https://almaryarostary.onrender.com/api/security/certificate-pins

# Check DNS resolution
nslookup almaryarostary.onrender.com

# Check endpoint exists
curl -o /dev/null -s -w "%{http_code}\n" https://almaryarostary.onrender.com/api/security/certificate-pins
```

**Solutions:**

- Endpoint returns 404: Check URL is exactly `/api/security/certificate-pins`
- Endpoint is slow (>10s): Optimize backend, add caching
- DNS fails: Check domain is correct
- Server is down: Restore service

### Problem: Pin Verification Failures After Certificate Update

**Symptoms:**
- Massive spike in certificate verification failures
- All users affected simultaneously

**Immediate Actions:**

1. Check if old certificate is still being used:
   ```bash
   openssl s_client -connect almaryarostary.onrender.com:443 < /dev/null \
     | openssl x509 -pubkey -noout | openssl asn1parse -strparse 19 -out /dev/stdout \
     | openssl dgst -sha256 -binary | base64
   ```

2. Check if endpoint was updated:
   ```bash
   curl https://almaryarostary.onrender.com/api/security/certificate-pins | jq '.'
   ```

3. If endpoint hasn't been updated: Update immediately
4. If pins don't match: Regenerate new pin
5. Follow rollback procedure in "Rollout Procedure" section

**Prevention:**

- Always test pins BEFORE rolling out
- Use backup pins during rotation
- Monitor error rates in real-time
- Have rollback plan ready

### Problem: Cache Not Updating

**Symptoms:**
- App still using old pins even after endpoint change
- App logs show old version number

**Diagnosis:**

```dart
// Check cache stats in app
final service = DynamicCertificateConfigService();
print(service.getCacheStats());

// Will show:
// - cached_config: current cached config
// - is_valid: whether cache is still valid
// - time_to_expiry_hours: how long until refresh
```

**Solutions:**

- **For testing**: Clear app data to reset cache
- **For users**: Wait up to 7 days for cache expiry (or use forceRefresh)
- **For immediate**: Increment version number (signals update available)

---

## Security Best Practices

### 1. Pin Generation

```bash
# ✅ DO: Use these exact commands
openssl s_client -connect almaryarostary.onrender.com:443 < /dev/null \
  | openssl x509 -pubkey -noout | openssl asn1parse -strparse 19 -out /dev/stdout \
  | openssl dgst -sha256 -binary | base64

# ❌ DON'T: Extract from wrong domain/certificate
# ❌ DON'T: Use MD5 or SHA1
# ❌ DON'T: Use certificate pin instead of public key pin
```

### 2. Pin Storage

```javascript
// ❌ Bad: Hardcoded in code
const pins = ["sha256/xxx"];
git commit pins

// ✅ Good: Environment variables
const pins = process.env.CERTIFICATE_PINS.split(',');

// ✅ Better: Secure config service
const pins = await SecureConfigService.get('pins');

// ✅ Best: Rotate with certificate lifecycle
const pins = await getCertificatePinsFromLetsEncrypt();
```

### 3. Endpoint Security

```javascript
// ✅ DO:
- Serve endpoint over HTTPS only
- Set appropriate cache headers
- Use CDN for availability
- Monitor endpoint health
- Rate limit gently (prevent abuse)

// ❌ DON'T:
- Serve over HTTP (pins could be intercepted)
- Require authentication (blocking pin fetch)
- Leak additional sensitive info in response
- Ignore endpoint errors
```

### 4. Rotation Process

```
✅ DO:
- Use backup pins during rotation
- Wait 24-48h between phases
- Monitor error rates at each phase
- Have rollback ready
- Increment version number
- Communicate changes to team

❌ DON'T:
- Remove old pin immediately
- Rotate without backup pins
- Push multiple updates quickly
- Forget to test pins first
```

### 5. Monitoring & Alerting

```
Set up alerts for:
- Pin verification failure spike (>1%)
- Endpoint becomes unavailable (>2% error rate)
- Endpoint response time >500ms
- Version adoption < 80% after 2 weeks
```

### 6. Hardcoded Fallback Pins

```dart
// Always have fallback pins for emergency bypass
static List<String> _fallbackPrimaryPins = [
  "sha256/CURRENT_CERT_PIN",
  "sha256/BACKUP_CERT_PIN"
];

// Update fallback pins when certificate rotates
// These are extracted from bundle at build time
```

---

## Summary

✅ **What You've Implemented:**
- Dynamic certificate pins from backend
- Secure local caching (7-day TTL)
- Automatic refresh every 24 hours
- Fallback to hardcoded pins if fetch fails
- MITM attack detection
- Zero-downtime certificate rotation

✅ **What Users Get:**
- Protection against MITM attacks
- App works offline (cached pins)
- Automatic updates without app reinstall
- Security monitoring and alerts

✅ **What You Need to Do:**
1. Generate pin for your current certificate
2. Implement `/api/security/certificate-pins` endpoint
3. Initialize pinning in app startup
4. Monitor endpoint and error rates
5. Follow rollout procedure for certificate changes

---

## Quick Reference

### Key Commands

```bash
# Get certificate pin
openssl s_client -connect almaryarostary.onrender.com:443 < /dev/null \
  | openssl x509 -pubkey -noout | openssl asn1parse -strparse 19 -out /dev/stdout \
  | openssl dgst -sha256 -binary | base64

# Test endpoint
curl https://almaryarostary.onrender.com/api/security/certificate-pins

# View app logs (Flutter)
flutter logs | grep certificate
```

### File Locations

```
App Files:
  - lib/core/security/certificate_pinning_service.dart
  - lib/core/security/dynamic_certificate_config_service.dart
  - lib/main.dart (add initialization)

Documentation:
  - BACKEND_CERTIFICATE_ENDPOINT.md (endpoint spec)
  - DYNAMIC_PINNING_IMPLEMENTATION_GUIDE.md (this file)
```

### Important URLs

```
Backend Endpoint:
  - GET https://almaryarostary.onrender.com/api/security/certificate-pins
  
Documentation:
  - https://developer.android.com/training/articles/security-config
  - https://developer.apple.com/library/archive/qa/qa1357/_index.html
  - https://owasp.org/www-community/pinning
```

---

## Support

For questions or issues:
1. Check Troubleshooting section
2. Review app logs for specific errors
3. Verify pin format matches exactly
4. Test endpoint with `curl` first
5. Contact security team if MITM suspected
