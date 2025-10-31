# 🔧 Gmail SMTP Setup Guide for Al Marya Rostery

## 🚨 **CURRENT ISSUE: Gmail Authentication Failed**

**Error**: `535-5.7.8 Username and Password not accepted`
**Account**: `almaryahrostery@gmail.com`
**Current App Password**: `krfb ilrx hdgm qaii` (NOT WORKING)

## ⚠️ IMPORTANT: App Password vs Regular Password

**❌ Don't use:** Regular Gmail password
**✅ Use:** 16-character App Password (like: `abcd efgh ijkl mnop`)

---

## � **STEP-BY-STEP FIX**

### **Step 1: Enable 2-Factor Authentication (Required)**

1. **Go to Gmail Security Settings:**
   ```
   🔗 https://myaccount.google.com/security
   ```

2. **Enable 2-Step Verification:**
   - Look for "2-Step Verification" section
   - Click "Get started" if not enabled
   - Follow the setup process
   - **IMPORTANT**: 2FA is REQUIRED for App Passwords

### Step 1: Enable 2-Factor Authentication
1. **Go to:** [Google Account Security](https://myaccount.google.com/security)
2. **Sign in** with `almaryahrostery@gmail.com` and password `Nepal@1590`
3. **Find:** "How you sign in to Google" section
4. **Click:** "2-Step Verification" 
5. **Follow prompts** to enable 2FA (you'll need your phone)

### Step 2: Generate App Password (AFTER 2FA is enabled)
1. **Go to:** [App Passwords](https://myaccount.google.com/apppasswords)
2. **Sign in** with `almaryahrostery@gmail.com` if asked
3. **Select:** "Mail" from the dropdown menu
4. **Click:** "Generate"
5. **Copy:** The 16-character password (format: `abcd efgh ijkl mnop`)

### Step 3: Update Configuration
Run this command and enter the **App Password** (not your regular password):
```bash
./setup-new-gmail.sh
```

---

## 🔧 Quick Setup Commands

After getting your App Password, you can also update manually:

```bash
# Replace YOUR_APP_PASSWORD with the actual 16-character password
sed -i.bak 's/SMTP_PASS=NEED_NEW_APP_PASSWORD_FOR_NEW_ACCOUNT/SMTP_PASS=YOUR_APP_PASSWORD/' .env

# Restart server
npm restart
```

---

## 🧪 Testing Your Configuration

Once configured, test with these endpoints:

```bash
# Check configuration
curl -H "Authorization: Bearer ADMIN_TOKEN" http://localhost:5001/api/test/email-config

# Send test email
curl -X POST -H "Content-Type: application/json" \
     -H "Authorization: Bearer ADMIN_TOKEN" \
     -d '{"to":"your-test-email@example.com"}' \
     http://localhost:5001/api/test/send-email
```

---

## 📱 Firebase Integration

Your current Firebase setup will work with the new email for:
- ✅ User authentication (login/signup) - handled by Firebase
- ✅ System notifications - handled by new Gmail SMTP
- ✅ Order confirmations - handled by new Gmail SMTP
- ✅ Newsletter emails - handled by new Gmail SMTP

---

## 🔍 Troubleshooting

### If you get "Invalid login" errors:
1. **Check:** 2FA is enabled on `almaryahrostery@gmail.com`
2. **Verify:** You're using App Password, not regular password
3. **Confirm:** App Password format is correct (`abcd efgh ijkl mnop`)
4. **Test:** Try logging into Gmail normally to ensure account works

### If App Password generation fails:
1. **Wait:** 10-15 minutes after enabling 2FA
2. **Refresh:** The App Passwords page
3. **Try:** Different browser or incognito mode
4. **Check:** Account security settings aren't blocking app access

---

## 🎯 Expected Results

After correct setup, you should see in server logs:
```
✅ GMAIL email service verified successfully
```

Instead of:
```
⚠️ Email transporter verification failed: Invalid login
```

---

## 🔐 Security Notes

- **Never share** your App Password
- **Don't commit** App Passwords to Git
- **Keep** your regular password (`Nepal@1590`) secure
- **Rotate** App Passwords regularly
- **Use** different App Passwords for different applications

---

## 📞 Need Help?

If you're still having issues:
1. Try the troubleshooting script: `./troubleshoot-email.sh`
2. Check server logs for detailed error messages
3. Verify Gmail account is accessible and 2FA is working
4. Consider using SendGrid as an alternative if Gmail continues to fail

---

**Next Action:** Enable 2FA on `almaryahrostery@gmail.com`, then generate an App Password and run the setup script again.
