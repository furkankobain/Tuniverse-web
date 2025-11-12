# 📧 Email Templates Setup Guide

## Beautiful HTML Email Templates for Tuniverse

This folder contains professional, branded email templates for:
- ✉️ **Email Verification** - Welcome new users
- 🔐 **Password Reset** - Secure password recovery

---

## 🎨 Template Features

- **Modern Design**: Gradient headers, clean layout, mobile-responsive
- **Brand Colors**: Tuniverse red (#FF5E5E) theme
- **Professional**: Includes security warnings, expiry notices
- **User-Friendly**: Alternative links, support contact info
- **Emoji Icons**: Visual appeal without images

---

## 🚀 Setup Instructions

### Method 1: Firebase Console (Recommended)

1. **Go to Firebase Console**
   - Navigate to: https://console.firebase.google.com/
   - Select your project: `musicshare-adfe8`

2. **Open Authentication Settings**
   - Click **Authentication** in left sidebar
   - Go to **Templates** tab
   - Select **Email address verification** or **Password reset**

3. **Customize Template**
   - Click **Edit Template** (pencil icon)
   - Copy HTML content from `verification_email.html` or `password_reset_email.html`
   - Paste into the template editor
   - Replace placeholders:
     - `{{VERIFICATION_LINK}}` → Use Firebase's `%LINK%` variable
     - `{{RESET_LINK}}` → Use Firebase's `%LINK%` variable

4. **Set Sender Email**
   - **From**: `noreply@tuniverseapp.com`
   - **From name**: `Tuniverse`
   - Click **Save**

5. **Email Action Handler URL**
   - Set to: `https://tuniverseapp.com/__/auth/action`
   - Or your custom domain email handler

---

### Method 2: Custom Email Service (Advanced)

If you want more control (different emails, analytics, etc.):

#### Option A: SendGrid Integration

1. **Create SendGrid Account**
   ```
   https://sendgrid.com/
   Free tier: 100 emails/day
   ```

2. **Domain Verification**
   - Add `noreply@tuniverseapp.com` as verified sender
   - Add DNS records for `tuniverseapp.com`:
     - SPF: `v=spf1 include:sendgrid.net ~all`
     - DKIM: (provided by SendGrid)
     - DMARC: `v=DMARC1; p=none;`

3. **API Key**
   - Generate API key in SendGrid dashboard
   - Save as Firebase environment variable

4. **Cloud Functions**
   - Install: `npm install @sendgrid/mail`
   - Create function to send emails
   - Use templates from this folder

#### Option B: Mailgun Integration

```bash
# Similar setup to SendGrid
# Free tier: 5,000 emails/month
```

---

## 📝 Email Variables

### Verification Email
- `{{VERIFICATION_LINK}}` - Email verification URL
- Dynamic content: User's email, signup timestamp

### Password Reset Email  
- `{{RESET_LINK}}` - Password reset URL
- Expires: 1 hour (configurable in Firebase)

---

## 🔧 Testing Emails

### Test in Development

1. **Firebase Emulator**
   ```bash
   firebase emulators:start
   ```
   - Emails won't actually send
   - View email content in emulator UI

2. **Your Personal Email**
   ```dart
   // Create test account with your email
   await FirebaseAuth.instance.createUserWithEmailAndPassword(
     email: 'your-email@gmail.com',
     password: 'test123',
   );
   ```

3. **Email Testing Services**
   - [Mailtrap.io](https://mailtrap.io/) - Catch emails in sandbox
   - [Ethereal.email](https://ethereal.email/) - Fake SMTP service

---

## 📧 Email Addresses Setup

Add these email addresses to your domain:

### Primary Emails
- ✅ `noreply@tuniverseapp.com` - Automated emails (verification, reset)
- ✅ `contact@tuniverseapp.com` - General inquiries  
- ✅ `support@tuniverseapp.com` - User support

### Optional Emails
- `hello@tuniverseapp.com` - Marketing/newsletter
- `team@tuniverseapp.com` - Team communications
- `admin@tuniverseapp.com` - Admin notifications

---

## 🎯 Firebase Console Quick Links

- **Email Templates**: https://console.firebase.google.com/project/musicshare-adfe8/authentication/emails
- **Settings**: https://console.firebase.google.com/project/musicshare-adfe8/settings/general

---

## ✅ Checklist

After setup, verify:

- [ ] Email templates configured in Firebase Console
- [ ] Sender email set to `noreply@tuniverseapp.com`
- [ ] Test email verification works
- [ ] Test password reset works
- [ ] Emails display correctly on mobile
- [ ] Links work and redirect properly
- [ ] SPF/DKIM records added for deliverability

---

## 🆘 Troubleshooting

### Emails not sending?
- Check Firebase Console → Authentication → Templates
- Verify sender email is authorized
- Check spam folder

### Emails look broken?
- Some email clients block CSS
- Test on Gmail, Outlook, Apple Mail
- Use inline CSS if needed

### Deliverability issues?
- Add SPF/DKIM DNS records
- Verify domain ownership
- Avoid spam trigger words

---

## 📞 Support

Questions? Contact: **support@tuniverseapp.com**

---

**© 2025 Tuniverse. All rights reserved.**
