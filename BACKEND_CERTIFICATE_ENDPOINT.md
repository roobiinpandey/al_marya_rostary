# Backend Certificate Pins Endpoint Documentation

## Overview

The mobile app requires a backend endpoint that serves dynamic SSL/TLS certificate pins. This allows the app to verify backend certificates and detect potential Man-in-the-Middle (MITM) attacks without requiring app updates.

## Endpoint Specification

### URL
```
GET https://almaryarostary.onrender.com/api/security/certificate-pins
```

### Authentication
**None required** - This endpoint must be publicly accessible since it's called during app initialization, before authentication is established.

### Response Format

#### Success Response (HTTP 200)
```json
{
  "version": "1.0.0",
  "primaryPins": [
    "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
    "sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
  ],
  "backupPins": [
    "sha256/CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC="
  ],
  "expiresAt": "2025-12-10T10:00:00Z"
}
```

#### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | Yes | Configuration version (e.g., "1.0.0"). Used to detect updates and coordinate rollout. Increment this when pins change. |
| `primaryPins` | string[] | Yes | Array of primary certificate pins in SHA256 format. **Must have at least one pin.** |
| `backupPins` | string[] | No | Array of backup certificate pins for certificate rotation scenarios. Can be empty. |
| `expiresAt` | ISO 8601 string | Yes | When this configuration expires. The app will request a fresh copy if cached config is expired. Recommend 7-30 days in the future. |

### Response Headers
```
Content-Type: application/json
Cache-Control: public, max-age=86400
```

## Certificate Pin Format

### SHA256 Public Key Pin
The pin is a base64-encoded SHA256 hash of the certificate's public key in DER format (Subject Public Key Info).

**Format:**
```
sha256/<BASE64_ENCODED_SHA256_HASH>
```

**Example:**
```
sha256/6dxjKzxpMbDFEUx2zVLJ0VnqzJe+yzL0P5hbMlFvtME=
```

### Getting Certificate Pins

#### Step 1: Get the Certificate
```bash
openssl s_client -connect almaryarostary.onrender.com:443 < /dev/null
```

#### Step 2: Extract and Save the Certificate
```bash
openssl s_client -connect almaryarostary.onrender.com:443 < /dev/null | openssl x509 -out cert.pem
```

#### Step 3: Extract the Public Key
```bash
openssl x509 -in cert.pem -pubkey -noout > pubkey.pem
```

#### Step 4: Generate the SHA256 Pin
```bash
openssl asn1parse -strparse 19 -in pubkey.pem -out /dev/stdout | openssl dgst -sha256 -binary | base64
```

**Output Example:**
```
6dxjKzxpMbDFEUx2zVLJ0VnqzJe+yzL0P5hbMlFvtME=
```

## Implementation Guide for Backend

### Node.js/Express Example

```javascript
// controllers/security.controller.js
const express = require('express');
const router = express.Router();

// Certificate configuration (should be loaded from secure config/database)
const CERTIFICATE_CONFIG = {
  version: "1.0.0",
  primaryPins: [
    "sha256/YOUR_PRIMARY_CERT_PIN_HERE"
  ],
  backupPins: [
    "sha256/YOUR_BACKUP_CERT_PIN_HERE" // Optional, for certificate rotation
  ],
  expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString() // 7 days from now
};

// GET /api/security/certificate-pins
router.get('/certificate-pins', (req, res) => {
  res.set('Cache-Control', 'public, max-age=86400');
  res.json(CERTIFICATE_CONFIG);
});

module.exports = router;
```

### Python/Flask Example

```python
# routes/security.py
from flask import Blueprint, jsonify
from datetime import datetime, timedelta

security_bp = Blueprint('security', __name__)

CERTIFICATE_CONFIG = {
    'version': '1.0.0',
    'primaryPins': [
        'sha256/YOUR_PRIMARY_CERT_PIN_HERE'
    ],
    'backupPins': [
        'sha256/YOUR_BACKUP_CERT_PIN_HERE'
    ],
    'expiresAt': (datetime.utcnow() + timedelta(days=7)).isoformat() + 'Z'
}

@security_bp.route('/api/security/certificate-pins', methods=['GET'])
def get_certificate_pins():
    response = jsonify(CERTIFICATE_CONFIG)
    response.headers['Cache-Control'] = 'public, max-age=86400'
    return response
```

### Java/Spring Boot Example

```java
// controller/SecurityController.java
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;

@RestController
@RequestMapping("/api/security")
public class SecurityController {
    
    @GetMapping("/certificate-pins")
    public ResponseEntity<Map<String, Object>> getCertificatePins() {
        Map<String, Object> config = new HashMap<>();
        config.put("version", "1.0.0");
        config.put("primaryPins", List.of(
            "sha256/YOUR_PRIMARY_CERT_PIN_HERE"
        ));
        config.put("backupPins", List.of(
            "sha256/YOUR_BACKUP_CERT_PIN_HERE"
        ));
        config.put("expiresAt", 
            Instant.now().plus(7, ChronoUnit.DAYS).toString()
        );
        
        return ResponseEntity.ok()
            .header("Cache-Control", "public, max-age=86400")
            .body(config);
    }
}
```

## Certificate Rotation Procedure

When you need to update your SSL certificate:

### Phase 1: Add New Certificate to Backups (Day 1)
1. Generate pin for new certificate
2. Add pin to `backupPins` array
3. Deploy updated endpoint
4. Wait for all apps to pick up the new configuration (24-48 hours)

```json
{
  "version": "1.0.1",
  "primaryPins": ["sha256/OLD_PIN"],
  "backupPins": ["sha256/NEW_PIN"],
  "expiresAt": "2025-12-10T10:00:00Z"
}
```

### Phase 2: Promote New Certificate to Primary (Day 2-3)
After confirming new certificate is deployed on backend:
1. Move new pin to `primaryPins`
2. Keep old pin in `backupPins`
3. Deploy updated endpoint

```json
{
  "version": "1.0.2",
  "primaryPins": ["sha256/NEW_PIN"],
  "backupPins": ["sha256/OLD_PIN"],
  "expiresAt": "2025-12-10T10:00:00Z"
}
```

### Phase 3: Remove Old Certificate (Day 7+)
After waiting for all users to update (~1 week):
1. Remove old pin from `backupPins`
2. Deploy updated endpoint

```json
{
  "version": "1.0.3",
  "primaryPins": ["sha256/NEW_PIN"],
  "backupPins": [],
  "expiresAt": "2025-12-10T10:00:00Z"
}
```

## Error Handling

### Client-Side Behavior

The mobile app implements the following error handling:

| Scenario | App Behavior |
|----------|-------------|
| Endpoint returns HTTP 200 with valid pins | Use returned pins immediately |
| Endpoint returns HTTP error (4xx, 5xx) | Use cached pins if available, fallback to hardcoded pins |
| Network timeout | Use cached pins if available, fallback to hardcoded pins |
| Malformed response | Ignore response, use cached pins or hardcoded pins |
| Empty `primaryPins` array | Reject config, use fallback pins |

### Server-Side Recommendations

- **Monitor**: Track error rates on this endpoint
- **Redundancy**: Ensure this endpoint is highly available (use CDN if possible)
- **Rate Limiting**: Consider gentle rate limiting (e.g., 1000 req/min per IP) since unauthenticated
- **Caching**: Set `Cache-Control` headers to reduce server load

## Testing

### Verify Endpoint Configuration

```bash
# Test endpoint response
curl -i https://almaryarostary.onrender.com/api/security/certificate-pins

# Expected output (example):
# HTTP/1.1 200 OK
# Content-Type: application/json
# Cache-Control: public, max-age=86400
#
# {
#   "version": "1.0.0",
#   "primaryPins": ["sha256/..."],
#   "backupPins": ["sha256/..."],
#   "expiresAt": "2025-12-10T10:00:00Z"
# }
```

### Test with Mobile App

1. Deploy updated endpoint
2. Uninstall app or clear app data
3. Reinstall app
4. Check device logs:
   ```bash
   # For Android (using Flutter)
   flutter logs | grep -i "certificate\|pin\|config"
   
   # For iOS
   log stream --level debug --predicate 'process == "Runner"' | grep -i "certificate\|pin\|config"
   ```
5. Look for log messages like:
   - ✅ `Fetched fresh config: DynamicCertConfig(...)`
   - ✅ `Certificate pin verified (dynamic primary)`

## Security Considerations

1. **Public Endpoint**: This endpoint is intentionally public and unauthenticated. Don't expose sensitive information here.

2. **HTTPS Only**: The endpoint should only be served over HTTPS to prevent pin disclosure during transmission.

3. **Pin Generation**: Use proper tools to extract pins from certificates. Incorrect pin format will cause legitimate traffic to be rejected.

4. **Version Tracking**: Always increment the version when pins change to help coordinate rollout.

5. **Backup Pins**: Always maintain at least one backup pin during certificate rotation to prevent lockout.

6. **Expiry Dates**: Set reasonable expiry dates (7-30 days) to encourage app updates and prevent stale pins.

## Troubleshooting

### Apps Rejecting All Certificates

**Symptoms**: Users report connection errors immediately after new certificate deployment

**Causes**:
- Incorrect pin format (missing `sha256/` prefix)
- Wrong certificate (pin from wrong domain)
- Empty `primaryPins` array

**Solution**:
1. Verify pin format: `sha256/<BASE64_HASH>`
2. Verify you extracted pin from your backend certificate
3. Ensure `primaryPins` has at least one pin
4. Test with `curl` first

### Apps Not Updating Configuration

**Symptoms**: Apps still using old pins even after endpoint update

**Causes**:
- Cache not expired yet (default 7 days)
- Version number not incremented
- Background refresh disabled

**Solution**:
1. Use `forceRefresh()` in app for immediate update
2. Clear app cache during testing
3. Increment version number when pins change

### MITM Attack Detected

**Symptoms**: All users reporting certificate verification failures

**Response**:
1. Check server certificate validity
2. Check app logs for pin verification failures
3. Verify endpoint is returning correct pins
4. Consider immediate app update if pins were compromised

## Monitoring & Alerts

### Recommended Metrics to Track

```
- Endpoint response time (should be <100ms)
- Error rate (should be <0.1%)
- Cache hit rate (should be >90%)
- Version adoption rate (track via app analytics)
```

### Sample Alert Rules

- Alert if endpoint response time > 500ms
- Alert if endpoint error rate > 1%
- Alert if pin verification failures spike

## Resources

- [OWASP Certificate Pinning](https://owasp.org/www-community/pinning)
- [Android Network Security Configuration](https://developer.android.com/training/articles/security-config)
- [iOS App Transport Security](https://developer.apple.com/library/archive/qa/qa1357/_index.html)
- [RFC 7469 - Public Key Pinning Extension](https://tools.ietf.org/html/rfc7469)
