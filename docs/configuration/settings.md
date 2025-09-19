# 🔧 Configuration Settings Guide

This guide explains the unified configuration system used in Shlink-UI-Rails and how to manage application settings.

## 🏗️ Configuration System Overview

Shlink-UI-Rails uses a unified configuration system (ApplicationConfig) that manages settings with the following priority order:

```
1. SystemSetting (Database)    - Changeable via admin interface
2. Environment Variables (ENV) - Set during deployment
3. config gem (Settings)       - Application configuration files
4. Default Values             - Defined in code
```

## ⚙️ Configuration Methods

### 1. Required Settings (Environment Variables)

These settings must be specified via environment variables:

```bash
# Rails Basic Configuration
RAILS_ENV=production
SECRET_KEY_BASE=your-very-long-secret-key-base

# Database Configuration
DATABASE_URL=mysql2://user:password@host:3306/database_name

# Shlink API Configuration
SHLINK_BASE_URL=https://your-shlink-server.com
SHLINK_API_KEY=your-shlink-api-key

# Redis Configuration
REDIS_URL=redis://your-redis-host:6379/0
```

### 2. Optional Settings (Admin Interface or Environment Variables)

These settings can be changed dynamically via the admin interface, and default values can be overridden with environment variables:

#### CAPTCHA Settings
```bash
CAPTCHA_ENABLED=false
CAPTCHA_SITE_KEY=your-turnstile-site-key
CAPTCHA_SECRET_KEY=your-turnstile-secret-key
```

#### Rate Limiting Settings
```bash
RATE_LIMIT_ENABLED=true
RATE_LIMIT_LOGIN_REQUESTS_PER_HOUR=10
RATE_LIMIT_REGISTRATION_REQUESTS_PER_HOUR=5
RATE_LIMIT_API_REQUESTS_PER_MINUTE=60
```

#### Email Settings
```bash
# SMTP Configuration
EMAIL_ADAPTER=smtp
EMAIL_FROM_ADDRESS=noreply@your-domain.com
EMAIL_SMTP_ADDRESS=smtp.gmail.com
EMAIL_SMTP_PORT=587
EMAIL_SMTP_USER_NAME=your-email@gmail.com
EMAIL_SMTP_PASSWORD=your-app-password
EMAIL_SMTP_AUTHENTICATION=plain
EMAIL_SMTP_ENABLE_STARTTLS_AUTO=true

# MailerSend Configuration
EMAIL_ADAPTER=mailersend
MAILERSEND_API_TOKEN=your-api-token
MAILERSEND_FROM_EMAIL=noreply@your-domain.com
```

#### OAuth Settings
```bash
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
```

#### WebAuthn Settings (Security Keys)
```bash
WEBAUTHN_RP_NAME=Your-App-Name
WEBAUTHN_RP_ID=your-domain.com
WEBAUTHN_ORIGIN=https://your-domain.com
WEBAUTHN_TIMEOUT=60000
```

#### Security Settings
```bash
SECURITY_REQUIRE_STRONG_PASSWORD=true
SECURITY_MAX_LOGIN_ATTEMPTS=5
SECURITY_SESSION_TIMEOUT=7200
SECURITY_FORCE_SSL=true
```

#### Performance Settings
```bash
PERFORMANCE_CACHE_TTL=3600
PERFORMANCE_DATABASE_POOL_SIZE=10
PERFORMANCE_BACKGROUND_JOB_THREADS=5
```

## 🛠️ Using Configuration Settings

### In Code (Direct Access)

#### 1. ApplicationConfig (Direct Access)
```ruby
# Basic setting retrieval
ApplicationConfig.get('captcha.enabled', false)

# Type-specific methods
ApplicationConfig.enabled?('captcha.enabled')       # boolean
ApplicationConfig.number('captcha.timeout', 10)     # integer
ApplicationConfig.string('email.adapter', 'smtp')   # string
ApplicationConfig.array('allowed.domains', [])      # array

# Category-wide retrieval
ApplicationConfig.category('captcha')
```

#### 2. ConfigShortcuts (Convenience Methods)
```ruby
# Available in controllers, models, jobs, and mailers
captcha_enabled?           # CAPTCHA enabled/disabled
shlink_base_url           # Shlink API URL
email_adapter             # Email adapter
smtp_settings             # Complete SMTP settings
redis_url                 # Redis connection URL
```

### Dynamic Configuration Changes

```ruby
# Update setting value (executed from admin interface)
ApplicationConfig.set('captcha.enabled', true, type: 'boolean', category: 'captcha')

# Reset setting to default value
ApplicationConfig.reset('captcha.enabled')

# Reload system settings (after configuration changes)
ApplicationConfig.reload!
```

## 📝 Environment Variable Naming Convention

Environment variable names are created by converting setting keys to uppercase and replacing dots (.) with underscores (_):

| Setting Key | Environment Variable |
|-------------|---------------------|
| `captcha.enabled` | `CAPTCHA_ENABLED` |
| `email.smtp.address` | `EMAIL_SMTP_ADDRESS` |
| `rate_limit.login.requests_per_hour` | `RATE_LIMIT_LOGIN_REQUESTS_PER_HOUR` |

## 🖥️ Admin Interface Configuration

### Accessing System Settings

1. Access the admin dashboard
2. Click "System Settings"
3. Modify settings in each category
4. Click "Save" to apply changes

Changed settings are immediately reflected throughout the application.

### Available Setting Categories

#### Basic System
- Site name and description
- Default timezone
- Pagination settings

#### Security
- Password requirements
- Session settings
- SSL enforcement

#### CAPTCHA
- Enable/disable CAPTCHA
- Turnstile configuration
- CAPTCHA timeout settings

#### Rate Limiting
- Login attempt limits
- Registration limits
- API rate limits

#### Email
- Email adapter selection
- SMTP configuration
- MailerSend configuration

#### Performance
- Cache settings
- Database pool configuration
- Background job settings

## 🔍 Debugging and Troubleshooting

### Checking Configuration Values
```ruby
# Check configuration values in Rails console
ApplicationConfig.get('captcha.enabled')

# Check configuration priority
puts "SystemSetting: #{SystemSetting.get('captcha.enabled')}"
puts "Environment: #{ENV['CAPTCHA_ENABLED']}"
puts "Config gem: #{Settings.captcha.enabled}"
puts "Unified system: #{ApplicationConfig.get('captcha.enabled')}"
```

### Clearing Configuration Cache
```ruby
# Clear cache in production
Rails.cache.delete_matched("app_config:*")
```

### Configuration Not Applying

If settings don't seem to be taking effect:

1. Check configuration priority order
2. Verify SystemSetting table contains the values
3. Restart the application
4. Clear cache (in production environments)

### Resetting Configuration

```bash
# Reset all settings to defaults
docker compose exec web rails runner "SystemSetting.destroy_all; SystemSetting.initialize_defaults!"

# Reset specific category
docker compose exec web rails runner "SystemSetting.by_category('captcha').destroy_all; SystemSetting.initialize_defaults!"
```

## 🧪 Testing Configuration

### Testing Environment Variables
```bash
# Test SMTP configuration
docker compose exec web rails runner "
  begin
    ActionMailer::Base.mail(
      from: ENV['EMAIL_FROM_ADDRESS'],
      to: 'test@example.com',
      subject: 'Test Email',
      body: 'Configuration test'
    ).deliver_now
    puts 'Email configuration working!'
  rescue => e
    puts \"Email error: \#{e.message}\"
  end
"

# Test database connection
docker compose exec web rails runner "
  begin
    ActiveRecord::Base.connection.execute('SELECT 1')
    puts 'Database connection working!'
  rescue => e
    puts \"Database error: \#{e.message}\"
  end
"

# Test Redis connection
docker compose exec web rails runner "
  begin
    Redis.new(url: ENV['REDIS_URL']).ping
    puts 'Redis connection working!'
  rescue => e
    puts \"Redis error: \#{e.message}\"
  end
"
```

## 📊 Configuration Examples

### Development Environment
```bash
# .env.development
RAILS_ENV=development
DATABASE_URL=mysql2://root@db:3306/shlink_ui_rails_development
REDIS_URL=redis://redis:6379/0
SHLINK_BASE_URL=http://localhost:8080
SHLINK_API_KEY=your-dev-api-key
EMAIL_ADAPTER=letter_opener
CAPTCHA_ENABLED=false
```

### Production Environment
```bash
# .env.production
RAILS_ENV=production
SECRET_KEY_BASE=your-very-long-secret-key-base
DATABASE_URL=mysql2://user:password@mysql-host:3306/shlink_ui_rails_production
REDIS_URL=rediss://user:password@redis-host:6379
SHLINK_BASE_URL=https://shlink.yourdomain.com
SHLINK_API_KEY=your-production-api-key
EMAIL_ADAPTER=mailersend
MAILERSEND_API_TOKEN=your-mailersend-token
MAILERSEND_FROM_EMAIL=noreply@yourdomain.com
CAPTCHA_ENABLED=true
CAPTCHA_SITE_KEY=your-turnstile-site-key
CAPTCHA_SECRET_KEY=your-turnstile-secret-key
WEBAUTHN_RP_ID=yourdomain.com
WEBAUTHN_ORIGIN=https://yourdomain.com
SECURITY_FORCE_SSL=true
SECURITY_REQUIRE_STRONG_PASSWORD=true
```

## 🔗 Related Documentation

- [Development Setup](../setup/development.md) - Development environment configuration
- [Production Deployment](../deployment/production.md) - Production environment setup
- [Japanese Documentation](settings_ja.md) - 日本語版設定ガイド

## 🆘 Support

For configuration issues:
1. Check the troubleshooting section above
2. Verify environment variables are correctly set
3. Review [GitHub Issues](https://github.com/enjoydarts/shlink-ui-rails/issues)
4. Test individual components (database, Redis, email) separately

---

**Security Note**: Never commit sensitive configuration values (API keys, passwords, secrets) to version control. Always use environment variables or secure secret management systems.