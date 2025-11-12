# 🚀 Quick Start: Firebase Email Templates

## 5-Minute Setup Guide

### Step 1: Open Firebase Console
```
https://console.firebase.google.com/project/musicshare-adfe8/authentication/emails
```

### Step 2: Configure Email Verification Template

1. Click **Email address verification** 
2. Click **Edit** (pencil icon)
3. **From name**: `Tuniverse`
4. **From email**: `noreply@tuniverseapp.com`
5. **Subject**: `Welcome to Tuniverse! Verify your email 🎵`
6. Copy content from `verification_email.html` and paste into template editor
7. Replace `{{VERIFICATION_LINK}}` with Firebase's `%LINK%` variable
8. Click **Save**

### Step 3: Configure Password Reset Template

1. Click **Password reset**
2. Click **Edit** (pencil icon)
3. **From name**: `Tuniverse`
4. **From email**: `noreply@tuniverseapp.com`
5. **Subject**: `Reset your Tuniverse password 🔐`
6. Copy content from `password_reset_email.html` and paste
7. Replace `{{RESET_LINK}}` with Firebase's `%LINK%` variable
8. Click **Save**

### Step 4: Test Emails

#### Test Email Verification:
```dart
// In your Flutter app
final user = FirebaseAuth.instance.currentUser;
await user?.sendEmailVerification();
```

#### Test Password Reset:
```dart
// Or use the login page "Forgot Password" button
await FirebaseAuth.instance.sendPasswordResetEmail(
  email: 'your-test-email@gmail.com',
);
```

### Step 5: Set Up Custom Domain (Optional)

For better deliverability, add DNS records:

```
Type: TXT
Name: @
Value: v=spf1 include:_spf.firebasemail.com ~all

Type: CNAME
Name: firebase1._domainkey
Value: mail-musicshare-adfe8.firebaseapp.com
```

---

## ✅ Done!

Your email system is now ready. Users will receive beautiful branded emails for:
- ✉️ Email verification after signup
- 🔐 Password reset requests
- 🎵 Sent from `noreply@tuniverseapp.com`

---

## 📧 Support

Need help? Email: **support@tuniverseapp.com**
