# 🚀 Production Deployment Guide

This guide provides comprehensive instructions for deploying Shlink-UI-Rails to production environments.

## 🏗️ Architecture Overview

**Recommended Production Stack:**
- **Web Server:** Caddy (HTTPS automation, reverse proxy)
- **Application:** Dockerized Rails application
- **Database:** External managed MySQL 8.4+
- **Cache:** Redis (Upstash, ElastiCache, or self-hosted)
- **CI/CD:** GitHub Actions
- **DNS:** Cloudflare (recommended)

## 🎯 Prerequisites

### Required Services & Accounts

| Service | Purpose | Required Information |
|---------|---------|---------------------|
| **Cloud Provider** | Server hosting | VPS/Instance (2+ CPU, 4GB+ RAM) |
| **MySQL Database** | Primary database | Connection string, credentials |
| **Redis Service** | Cache & sessions | Redis connection URL |
| **DNS Provider** | Domain management | Domain configuration |
| **Email Service** | Email delivery | SMTP or API credentials |
| **OAuth Provider** | Authentication (optional) | Client ID, secret |
| **GitHub** | Source code & CI/CD | Repository, Actions permissions |

### Required Tools

- SSH client
- Git
- Docker and Docker Compose
- Text editor

## 📋 Deployment Options

### Option 1: Automated Setup (Recommended)

For quick production deployment using Docker Compose:

#### 1.1 Clone and Setup
```bash
# Clone repository
git clone https://github.com/enjoydarts/shlink-ui-rails.git
cd shlink-ui-rails

# Create required directories
mkdir -p logs storage tmp

# Set permissions (if needed)
sudo chown -R 1000:1000 logs storage tmp
```

#### 1.2 Environment Configuration
Create `.env.production` file:

```bash
# Application
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
SECRET_KEY_BASE=your_very_long_secret_key_base

# Database (External MySQL)
DATABASE_URL=mysql2://username:password@host:3306/database_name

# Redis
REDIS_URL=redis://username:password@host:6379/0

# Domain and URLs
RAILS_FORCE_SSL=true
WEBAUTHN_RP_ID=yourdomain.com
WEBAUTHN_ORIGIN=https://yourdomain.com

# Email Configuration (MailerSend example)
EMAIL_ADAPTER=mailersend
MAILERSEND_API_TOKEN=your_api_token
MAILERSEND_FROM_EMAIL=noreply@yourdomain.com

# OAuth (optional)
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret

# Security
SECURITY_FORCE_SSL=true
SECURITY_SESSION_TIMEOUT=7200

# Performance
RAILS_MAX_THREADS=10
RAILS_MIN_THREADS=5
```

#### 1.3 Deploy Application
```bash
# Start services
docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f app
```

### Option 2: Manual Server Setup

For custom server configurations:

#### 2.1 Server Preparation
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Caddy (reverse proxy)
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install caddy
```

#### 2.2 Caddy Configuration
Create `/etc/caddy/Caddyfile`:

```caddy
yourdomain.com {
    reverse_proxy localhost:3000

    # Security headers
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
    }

    # Enable compression
    encode gzip

    # Log configuration
    log {
        output file /var/log/caddy/access.log {
            roll_size 100mb
            roll_keep 5
            roll_keep_for 720h
        }
    }
}
```

#### 2.3 Application Deployment
```bash
# Create application directory
sudo mkdir -p /opt/shlink-ui-rails
cd /opt/shlink-ui-rails

# Clone application
git clone https://github.com/enjoydarts/shlink-ui-rails.git .

# Set up environment
cp .env.example .env.production
# Edit .env.production with your configuration

# Start application
docker-compose -f docker-compose.prod.yml up -d

# Start Caddy
sudo systemctl enable caddy
sudo systemctl start caddy
```

## 🔧 Configuration Details

### Database Setup

#### External MySQL (Recommended)
```bash
# Example connection strings
DATABASE_URL=mysql2://user:password@mysql-host:3306/shlink_ui_rails_production

# For managed services (AWS RDS, GCP Cloud SQL, etc.)
DATABASE_URL=mysql2://user:password@host:3306/database?sslmode=require
```

#### Schema Management
```bash
# Apply database schema (run during deployment)
docker-compose exec app bundle exec ridgepole -c config/database.yml -E production --apply -f db/schemas/Schemafile
```

### Redis Configuration

#### External Redis Services
```bash
# Upstash Redis
REDIS_URL=rediss://username:password@host:6379

# AWS ElastiCache
REDIS_URL=redis://clustercfg.cluster-name.region.cache.amazonaws.com:6379

# Self-hosted Redis with auth
REDIS_URL=redis://username:password@host:6379/0
```

### SSL/TLS Configuration

#### Automatic HTTPS (Caddy)
Caddy automatically provisions SSL certificates from Let's Encrypt. No additional configuration needed.

#### Manual SSL Setup
```bash
# Install certificates manually if needed
sudo mkdir -p /etc/ssl/certs/yourdomain.com
sudo cp fullchain.pem /etc/ssl/certs/yourdomain.com/
sudo cp privkey.pem /etc/ssl/certs/yourdomain.com/
```

## 🚀 CI/CD Setup (GitHub Actions)

### Repository Secrets Configuration

Add these secrets to your GitHub repository:

| Secret Name | Value |
|-------------|--------|
| `DEPLOY_HOST` | Your server IP address |
| `DEPLOY_USER` | SSH username |
| `DEPLOY_KEY` | SSH private key |
| `PRODUCTION_ENV` | Complete .env.production content |

### Deploy Workflow

The repository includes GitHub Actions workflow for automated deployment. It will:

1. Run tests on pull requests
2. Deploy to production when pushing to `main` branch
3. Perform health checks after deployment
4. Rollback on deployment failures

## 📊 Monitoring & Logging

### Health Checks
```bash
# Application health
curl -f https://yourdomain.com/health || exit 1

# Container health
docker-compose -f docker-compose.prod.yml ps

# Resource usage
docker stats --no-stream
```

### Log Management
```bash
# Application logs
tail -f logs/production.log

# Container logs
docker-compose -f docker-compose.prod.yml logs -f app

# Caddy logs
sudo tail -f /var/log/caddy/access.log
```

### Log Rotation
Configure logrotate for application logs:

```bash
# Create /etc/logrotate.d/shlink-ui-rails
/opt/shlink-ui-rails/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 www-data www-data
    postrotate
        docker-compose -f /opt/shlink-ui-rails/docker-compose.prod.yml restart app
    endscript
}
```

## 🆘 Troubleshooting

### Common Issues

#### Permission Errors
```bash
# Fix container permissions
docker-compose exec app chown -R app:app /app/log /app/storage /app/tmp

# Fix host permissions
sudo chown -R 1000:1000 logs storage tmp
```

#### Database Connection Issues
```bash
# Test database connection
docker-compose exec app rails runner "ActiveRecord::Base.connection.execute('SELECT 1')"

# Check database configuration
docker-compose exec app rails runner "puts Rails.application.config.database_configuration['production']"
```

#### SSL Certificate Issues
```bash
# Check Caddy configuration
sudo caddy validate --config /etc/caddy/Caddyfile

# Reload Caddy
sudo systemctl reload caddy

# Check certificate status
curl -I https://yourdomain.com
```

#### Memory Issues
```bash
# Check memory usage
free -h
docker stats --no-stream

# Optimize container memory limits
# Edit docker-compose.prod.yml to add memory limits
```

### Performance Optimization

#### Database Optimization
```bash
# Add database indexes (if needed)
docker-compose exec app rails runner "
  ActiveRecord::Base.connection.execute('CREATE INDEX ...')
"

# Database query optimization
docker-compose exec app rails runner "
  puts ActiveRecord::Base.connection.execute('SHOW PROCESSLIST')
"
```

#### Application Optimization
```bash
# Precompile assets
docker-compose exec app rails assets:precompile

# Clear cache
docker-compose exec app rails cache:clear

# Restart application
docker-compose restart app
```

## 🔧 Maintenance

### Regular Maintenance Tasks

#### Daily
```bash
# Check application health
curl -f https://yourdomain.com/health

# Monitor disk space
df -h

# Check container status
docker-compose ps
```

#### Weekly
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Clean Docker images
docker system prune -f

# Backup database
# (Configure automated backups for your database service)
```

#### Monthly
```bash
# Update application
git pull origin main
docker-compose build --no-cache
docker-compose up -d

# Review logs for errors
grep -i error logs/production.log

# Security updates
sudo apt update && sudo apt upgrade -y
```

## 🔗 Additional Resources

- [Configuration Guide](../configuration/settings.md) - Detailed configuration options
- [Operations Guide](../operations/cd-system.md) - CI/CD and monitoring
- [Development Setup](../setup/development.md) - Development environment
- [Japanese Documentation](production_ja.md) - 日本語版デプロイガイド

## 🆘 Support

For deployment issues:
1. Check the [troubleshooting section](#troubleshooting) above
2. Review [GitHub Issues](https://github.com/enjoydarts/shlink-ui-rails/issues)
3. Check application logs and server logs
4. Verify all environment variables are correctly set

---

**Security Note**: Always use HTTPS in production, keep your dependencies updated, and follow security best practices for your server and database configurations.