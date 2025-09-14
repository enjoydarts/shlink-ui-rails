# 🚀 Shlink-UI-Rails Initial Setup Guide

This guide provides step-by-step instructions for first-time deployers of Shlink-UI-Rails.

## 📋 Setup Process

### 1. Basic Setup
```bash
# Database setup and initial data creation
rails db:setup
```

### 2. Admin Account Login
- 📧 **Email**: `admin@yourdomain.com`
- 🔑 **Password**: `change_me_please`

⚠️ **For security, please change your password immediately after login**

### 3. System Configuration

Navigate to Admin Panel > System Settings and configure the following:

#### 🏠 Basic System Settings
- **Site Name**: Your service name (e.g., "MyShortURL")
- **Site URL**: Your domain (e.g., "https://short.example.com")
- **Admin Email**: Your email address
- **Site Description**: SEO description

#### 📧 Email Settings (Required)
Required for password resets and notification emails.

**Using Gmail:**
1. **Email Adapter**: `smtp`
2. **From Address**: `noreply@yourdomain.com`
3. **SMTP Server**: `smtp.gmail.com`
4. **SMTP Port**: `587`
5. **SMTP Username**: Your Gmail address
6. **SMTP Password**: [Gmail App Password](https://support.google.com/accounts/answer/185833)

**Using MailerSend:**
1. **Email Adapter**: `mailersend`
2. **MailerSend API Key**: Get from [MailerSend](https://www.mailersend.com)

#### 🛡️ CAPTCHA Settings (Recommended for Production)
Protect against spam and abuse. Enable for production environments.

1. Create account at [Cloudflare Turnstile](https://dash.cloudflare.com/profile/api-tokens) (free)
2. Get Site Key and Secret Key
3. **CAPTCHA Enabled**: `true`
4. Configure the keys

## 🔧 Environment Variables (Optional)

Some settings can be configured via environment variables:

```bash
# Admin account
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=your_secure_password

# Database
DATABASE_URL=mysql2://user:password@host:3306/database

# Production environment
RAILS_ENV=production
SECRET_KEY_BASE=your_secret_key_base
```

## 📝 Additional Production Settings

### SSL/TLS Configuration
```bash
# Get SSL certificate (e.g., Let's Encrypt)
# Change site URL to https://
```

### Security Settings
- **Require Strong Password**: `enabled`
- **Max Login Attempts**: `5 times`
- **Session Timeout**: `24 hours`

### Performance Settings
- **Cache TTL**: `3600 seconds` (1 hour)
- **Stats Update Interval**: `15 minutes`
- **Items Per Page**: `20 items`

## 🆘 Troubleshooting

### Email Sending Issues
1. Test SMTP settings using the "Test" button
2. Check if port 587 is open in firewall
3. For Gmail, ensure you're using App Password

### CAPTCHA Not Displaying
1. Verify Site Key is correctly configured
2. Check if domain is registered with Cloudflare Turnstile

### Forgot Admin Password
```bash
# Change password via Rails console
rails console
admin = User.find_by(email: 'admin@yourdomain.com')
admin.update!(password: 'new_password', password_confirmation: 'new_password')
```

## 🎉 Setup Complete

After configuration, test the following:

- [ ] User registration/login works
- [ ] URL shortening works
- [ ] Password reset emails are delivered
- [ ] CAPTCHA displays (if enabled)

If issues occur, use the "Test" buttons in System Settings to test each feature.

---

**🔗 Additional Documentation**
- [README.md](README.md) - Development environment setup
- [README_ja.md](README_ja.md) - Japanese documentation
- [SETUP_JA.md](SETUP_JA.md) - Japanese setup guide
- API Documentation - API usage
- Troubleshooting - Detailed troubleshooting