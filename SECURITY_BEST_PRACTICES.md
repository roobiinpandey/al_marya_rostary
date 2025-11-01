# Security Credentials - Best Practices

## ⚠️ CRITICAL SECURITY RULES

### 1. NEVER Commit Real Credentials to Git

**WRONG** ❌:
```javascript
const MONGODB_URI = 'mongodb+srv://realuser:realpassword@cluster.mongodb.net/database';
```

**CORRECT** ✅:
```javascript
const MONGODB_URI = process.env.MONGODB_URI;
if (!MONGODB_URI) {
  throw new Error('MONGODB_URI environment variable is required');
}
```

### 2. Use Environment Variables

**Backend (.env file - NEVER commit):**
```env
MONGODB_URI=mongodb+srv://USERNAME:PASSWORD@CLUSTER.mongodb.net/DATABASE
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
FIREBASE_SERVICE_ACCOUNT_KEY=path/to/key.json
JWT_SECRET=your-random-secure-string
```

**Render.com Environment Variables:**
1. Dashboard → Your Service → Environment
2. Add each variable manually
3. Never store in git

### 3. Protect API Keys

**Google API Keys:**
- Add API restrictions in Google Cloud Console
- Restrict to specific Android app SHA-1 fingerprints
- Restrict to specific HTTP referrers for web

**Firebase:**
- Client API keys in `google-services.json` are safe (public)
- NEVER commit service account keys (`firebase-adminsdk-*.json`)

### 4. .gitignore Configuration

Always include:
```
# Environment variables
.env
.env.local
backend/.env

# Firebase service accounts
**/firebase-adminsdk*.json
**/serviceAccountKey.json
**/service-account*.json

# Credentials
**/*credentials*.txt
**/*secrets*.txt
**/*ENV_VARS*.env
```

### 5. Git History Cleanup

If credentials were committed:

**Option 1: BFG Repo Cleaner (Recommended)**
```bash
brew install bfg
bfg --delete-files sensitive-file.txt
bfg --replace-text passwords.txt
git push --force
```

**Option 2: git-filter-repo**
```bash
brew install git-filter-repo
git filter-repo --path sensitive-file.txt --invert-paths
git push --force
```

### 6. Credential Rotation

If a credential is exposed:
1. **Rotate immediately** (change password/regenerate key)
2. Clean git history
3. Update all services using the old credential
4. Monitor for unauthorized access

### 7. MongoDB Atlas Security

**Best Practices:**
- Use specific database users (not admin)
- Rotate passwords quarterly
- Enable IP whitelist (add Render.com IPs)
- Use read-only users for analytics
- Monitor access logs

**Example Connection String Template:**
```
mongodb+srv://USERNAME:PASSWORD@CLUSTER.mongodb.net/DATABASE?retryWrites=true&w=majority
```

Replace:
- `USERNAME`: Database user name
- `PASSWORD`: Strong password (never commit)
- `CLUSTER`: Your cluster address
- `DATABASE`: Database name

### 8. Google Cloud API Security

**Maps API:**
- Restrict to Android app SHA-1
- Set usage quotas
- Monitor usage in Cloud Console

**Firebase API:**
- Configure authorized domains
- Use App Check for additional security
- Restrict service account permissions

### 9. Render.com Deployment

**Environment Variables:**
```
MONGODB_URI=<from-mongodb-atlas>
CLOUDINARY_CLOUD_NAME=<from-cloudinary>
CLOUDINARY_API_KEY=<from-cloudinary>
CLOUDINARY_API_SECRET=<from-cloudinary>
NODE_ENV=production
PORT=10000
```

**Never:**
- Store in git
- Share in documentation
- Include in README files

### 10. Team Security

**Code Reviews:**
- Check for hardcoded credentials
- Verify .env files are not committed
- Review API key usage

**Access Control:**
- Limit MongoDB Atlas access
- Limit Render.com access
- Use principle of least privilege

**Documentation:**
- Use placeholder values only
- Document process, not actual credentials
- Keep sensitive docs local-only

---

## 📋 Security Checklist

Before each commit:
- [ ] No hardcoded credentials
- [ ] .env files in .gitignore
- [ ] Service account keys excluded
- [ ] API keys properly restricted
- [ ] Documentation sanitized

Before deployment:
- [ ] Environment variables set in Render
- [ ] MongoDB IP whitelist configured
- [ ] API keys restricted to production domains
- [ ] Service accounts have minimal permissions

Regular maintenance:
- [ ] Rotate credentials quarterly
- [ ] Review access logs monthly
- [ ] Update API key restrictions
- [ ] Audit team access

---

## 🆘 Emergency Response

If credentials are exposed:

1. **Immediate** (< 1 hour):
   - Rotate all exposed credentials
   - Update production services
   - Check access logs

2. **Short-term** (< 24 hours):
   - Clean git history
   - Review for unauthorized access
   - Document incident

3. **Long-term** (< 1 week):
   - Implement additional security
   - Train team on best practices
   - Set up monitoring alerts

---

## 📚 Resources

- [MongoDB Atlas Security](https://docs.atlas.mongodb.com/security/)
- [Google Cloud API Security](https://cloud.google.com/docs/security)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [BFG Repo Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)
- [OWASP Secrets Management](https://owasp.org/www-community/vulnerabilities/Use_of_hard-coded_password)

---

**Remember**: The best security practice is to never commit credentials in the first place. Use environment variables everywhere!
