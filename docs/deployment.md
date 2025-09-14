# Shlink-UI-Rails Production Deployment Guide (English)

## Overview

This guide provides detailed instructions for deploying the Shlink-UI-Rails application to production on OCI (Oracle Cloud Infrastructure) Ampere A1 instances.

**Architecture Overview:**
- **Web Server:** Caddy (HTTPS automation, reverse proxy)
- **Application:** Dockerized Rails application
- **Database:** External managed MySQL
- **Cache:** Upstash Redis
- **CI/CD:** GitHub Actions
- **Domain:** app.kety.at (Cloudflare DNS)

---

## Prerequisites

### Required Services & Accounts

| Service | Purpose | Required Information |
|---------|---------|---------------------|
| **OCI (Oracle Cloud Infrastructure)** | Server hosting | Ampere A1 instance |
| **External Managed MySQL** | Database | Connection string, credentials |
| **Upstash** | Redis cache | Redis connection URL |
| **Cloudflare** | DNS management | Domain: app.kety.at |
| **MailerSend** | Email delivery | API token |
| **Google Cloud Console** | OAuth2 authentication | Client ID, secret |
| **GitHub** | Source code & CI/CD | Repository, Actions permissions |

### Required Tools

- SSH client
- Git
- Text editor

---

## Step 1: OCI Instance Setup

### 1.1 Instance Creation

**Recommended Specifications:**
- **Shape:** VM.Standard.A1.Flex
- **OCPU:** 4 cores
- **Memory:** 24GB RAM
- **OS:** Ubuntu 22.04 LTS (ARM64)
- **Storage:** 100GB or more

**Security Group Configuration:**
- SSH (Port 22): Allow from management IPs only
- HTTP (Port 80): Allow from all
- HTTPS (Port 443): Allow from all

### 1.2 Initial Setup and Security Hardening

Connect to the instance via SSH and execute the following:

```bash
# System update
sudo apt update && sudo apt upgrade -y

# Install basic packages
sudo apt install -y curl wget git unzip fail2ban ufw htop

# Firewall configuration (Important: ensure SSH connection remains active)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
# Enable firewall (verify SSH connection before executing)
sudo ufw --force enable

# SSH brute force protection (fail2ban)
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Check fail2ban status
sudo fail2ban-client status
```

### 1.3 Dedicated User Creation and Directory Setup

```bash
# Create application-specific user
# --system: Create as system user
# --group: Create group with same name
# --home: Set home directory to /opt/shlink-ui-rails
# --shell: Set login shell
sudo adduser --system --group --home /opt/shlink-ui-rails --shell /bin/bash shlink

# Create required directory structure
sudo mkdir -p /opt/shlink-ui-rails/{app,config,logs,backups,scripts,tmp,storage}
sudo chown -R shlink:shlink /opt/shlink-ui-rails

# Create system-wide log directory
sudo mkdir -p /var/log/shlink-ui-rails
sudo chown shlink:shlink /var/log/shlink-ui-rails

# Verify directory structure
ls -la /opt/shlink-ui-rails/
```

### 1.4 Docker Installation

```bash
# Use official Docker installation script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# Install Docker Compose (check for latest version and update URL)
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add dedicated user to docker group
sudo usermod -aG docker shlink

# Configure Docker service for auto-start
sudo systemctl enable docker
sudo systemctl start docker

# Verify installation
docker --version
docker-compose --version
```

### 1.5 Caddy Web Server Installation

```bash
# Add Caddy official repository
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list

# Install Caddy
sudo apt update
sudo apt install caddy

# Verify Caddy service
sudo systemctl status caddy
```

---

## Step 2: Environment Variables and Application Configuration

### 2.1 Environment Variables File Creation

Create the environment variables file as the dedicated user:

```bash
# Switch to dedicated user
sudo su - shlink

# Navigate to application directory
cd /opt/shlink-ui-rails

# Create environment variables file with secure permissions
cat > .env.production << 'EOF'
# Rails basic configuration
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
LOG_LEVEL=info

# Security configuration (MUST change these)
SECRET_KEY_BASE=your-very-long-secret-key-here-change-this
DEVISE_SECRET_KEY=your-devise-secret-key-here-change-this
SECURITY_FORCE_SSL=true
SECURITY_HEADERS_ENABLED=true

# Database configuration (change to your managed MySQL info)
DATABASE_URL=mysql2://username:password@mysql-host:3306/shlink_ui_rails_production

# Redis configuration (change to your Upstash info)
REDIS_URL=rediss://default:password@redis-host:6380

# Google OAuth2 configuration (obtain from Google Cloud Console)
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Email configuration (obtain from MailerSend)
MAILERSEND_API_TOKEN=your-mailersend-api-token
MAIL_FROM=noreply@app.kety.at

# Shlink API configuration (change to your Shlink server info)
SHLINK_BASE_URL=https://your-shlink-server.com
SHLINK_API_KEY=your-shlink-api-key

# WebAuthn configuration
WEBAUTHN_RP_NAME=Shlink-UI-Rails
WEBAUTHN_RP_ID=app.kety.at
WEBAUTHN_ORIGIN=https://app.kety.at

# Application configuration
APP_HOST=app.kety.at
APP_PROTOCOL=https
APP_TIMEZONE=Tokyo
EOF

# Restrict file permissions (Important: security measure)
chmod 600 .env.production

# Return to original user
exit
```

### 2.2 Secret Key Generation

```bash
# Generate strong secret keys for production
# Use these commands to generate secure keys before production deployment

# For SECRET_KEY_BASE
openssl rand -hex 64

# For DEVISE_SECRET_KEY
openssl rand -hex 64

# Set the generated strings in the corresponding fields in .env.production
```

---

## Step 3: Caddy Configuration

### 3.1 Caddyfile Configuration

```bash
# Configure Caddyfile
sudo tee /etc/caddy/Caddyfile << 'EOF'
# app.kety.at configuration
app.kety.at {
	# Reverse proxy to Rails application
	reverse_proxy localhost:3000 {
		# Health check configuration
		health_uri /health
		health_interval 10s
		health_timeout 5s
	}

	# Security headers
	header {
		# HTTPS enforcement
		Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
		# XSS protection
		X-Content-Type-Options "nosniff"
		X-Frame-Options "SAMEORIGIN"
		X-XSS-Protection "1; mode=block"
		# Other security headers
		Referrer-Policy "strict-origin-when-cross-origin"
		# Hide server information
		-Server
		-X-Powered-By
	}

	# Rate limiting (DDoS protection)
	rate_limit {
		zone general {
			key {remote_host}
			events 100
			window 1m
		}
	}

	# Logging configuration
	log {
		output file /var/log/caddy/app.kety.at.log {
			roll_size 100MB
			roll_keep 10
		}
		format json
	}

	# Error pages
	handle_errors {
		@404 expression {http.error.status_code} == 404
		@5xx expression {http.error.status_code} >= 500 && {http.error.status_code} < 600

		handle @404 {
			respond "Not Found" 404
		}
		handle @5xx {
			respond "Server Error" 500
		}
	}
}

# HTTP to HTTPS redirect
http://app.kety.at {
	redir https://app.kety.at{uri} permanent
}
EOF

# Create Caddy log directory
sudo mkdir -p /var/log/caddy
sudo chown caddy:caddy /var/log/caddy

# Test Caddy configuration
sudo caddy validate --config /etc/caddy/Caddyfile

# Enable and restart Caddy service
sudo systemctl enable caddy
sudo systemctl restart caddy

# Check status
sudo systemctl status caddy
```

---

## Step 4: systemd Service Configuration

### 4.1 Application Auto-start Configuration

```bash
# Create systemd service file
sudo tee /etc/systemd/system/shlink-ui-rails.service << 'EOF'
[Unit]
Description=Shlink UI Rails Application
After=docker.service network-online.target
Wants=network-online.target
Requires=docker.service

[Service]
Type=forking
User=shlink
Group=shlink
WorkingDirectory=/opt/shlink-ui-rails

# Load environment variables file
EnvironmentFile=/opt/shlink-ui-rails/.env.production

# Service execution commands
ExecStartPre=/usr/local/bin/docker-compose -f docker-compose.prod.yml pull --quiet
ExecStart=/usr/local/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.prod.yml down
ExecReload=/usr/local/bin/docker-compose -f docker-compose.prod.yml restart

# Restart configuration
Restart=always
RestartSec=10

# Security configuration
NoNewPrivileges=true
PrivateTmp=true

# Timeout configuration
TimeoutStartSec=300
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd configuration
sudo systemctl daemon-reload

# Enable service (auto-start configuration)
sudo systemctl enable shlink-ui-rails
```

---

## Step 5: GitHub Actions Configuration

### 5.1 GitHub Secrets Configuration

In your GitHub repository, go to **Settings** → **Secrets and variables** → **Actions** and add the following secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `OCI_HOST` | `your-instance-ip` | OCI instance public IP |
| `OCI_USERNAME` | `shlink` | Dedicated user name |
| `OCI_SSH_PRIVATE_KEY` | `-----BEGIN OPENSSH PRIVATE KEY-----...` | SSH private key (created below) |
| `GITHUB_TOKEN` | Auto-generated | For Docker registry (usually auto-configured) |

### 5.2 SSH Key Configuration

```bash
# Generate SSH key as dedicated user
sudo -u shlink ssh-keygen -t ed25519 -f /opt/shlink-ui-rails/.ssh/id_ed25519 -N ""

# Set up SSH configuration directory and permissions
sudo -u shlink mkdir -p /opt/shlink-ui-rails/.ssh
sudo -u shlink chmod 700 /opt/shlink-ui-rails/.ssh
sudo -u shlink chmod 600 /opt/shlink-ui-rails/.ssh/id_ed25519
sudo -u shlink chmod 644 /opt/shlink-ui-rails/.ssh/id_ed25519.pub

# Add public key to authorized_keys
sudo -u shlink cp /opt/shlink-ui-rails/.ssh/id_ed25519.pub /opt/shlink-ui-rails/.ssh/authorized_keys
sudo -u shlink chmod 600 /opt/shlink-ui-rails/.ssh/authorized_keys

# Display private key for GitHub Secrets configuration
sudo cat /opt/shlink-ui-rails/.ssh/id_ed25519
```

**Important:** Copy the displayed private key and set it as the `OCI_SSH_PRIVATE_KEY` secret in GitHub.

---

## Step 6: Initial Deployment

### 6.1 Application Code Deployment

```bash
# Clone Git repository as dedicated user
sudo -u shlink git clone https://github.com/your-username/shlink-ui-rails.git /opt/shlink-ui-rails/app

# Create symbolic links for required files
sudo -u shlink ln -sf /opt/shlink-ui-rails/app/docker-compose.prod.yml /opt/shlink-ui-rails/docker-compose.prod.yml
sudo -u shlink ln -sf /opt/shlink-ui-rails/app/Dockerfile.production /opt/shlink-ui-rails/Dockerfile.production

# Verify directory structure
sudo -u shlink ls -la /opt/shlink-ui-rails/
```

### 6.2 Docker Image Build and Initial Startup

```bash
# Switch to dedicated user
sudo su - shlink
cd /opt/shlink-ui-rails

# Verify environment variables file exists
ls -la .env.production

# Build Docker image (first time only)
docker-compose -f docker-compose.prod.yml build

# Initialize database (Important: must be executed first)
docker-compose -f docker-compose.prod.yml run --rm app rails db:create
docker-compose -f docker-compose.prod.yml run --rm app rails db:migrate
docker-compose -f docker-compose.prod.yml run --rm app rails db:seed

# Start application
docker-compose -f docker-compose.prod.yml up -d

# Check startup status
docker-compose -f docker-compose.prod.yml ps

# Check logs
docker-compose -f docker-compose.prod.yml logs app

# Return to original user
exit
```

### 6.3 Start systemd Service

```bash
# Start systemd service
sudo systemctl start shlink-ui-rails

# Check status
sudo systemctl status shlink-ui-rails

# Check logs
sudo journalctl -u shlink-ui-rails -f
```

---

## Step 7: DNS Configuration (Cloudflare)

### 7.1 DNS Record Configuration

Configure the following settings in the Cloudflare dashboard:

**A Record Configuration:**
- **Type:** A
- **Name:** app
- **IPv4 address:** [OCI instance public IP]
- **TTL:** Auto
- **Proxy status:** 🟠 Proxied (Orange cloud)

### 7.2 SSL/TLS Configuration

Configure the following in Cloudflare:
- **SSL/TLS setting:** Full (strict)
- **Always Use HTTPS:** Enable
- **HTTP Strict Transport Security (HSTS):** Enable

---

## Step 8: Backup and Monitoring Configuration

### 8.1 Backup Script Configuration

```bash
# Create backup script
sudo -u shlink tee /opt/shlink-ui-rails/scripts/backup.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# Configuration
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/shlink-ui-rails/backups"
RETENTION_DAYS=30
LOG_FILE="/var/log/shlink-ui-rails/backup.log"

# Logging function
log() {
    echo "$(date): $1" | tee -a "$LOG_FILE"
}

# Start backup
log "Starting backup process"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Load environment variables
source /opt/shlink-ui-rails/.env.production

# Database backup
log "Creating database backup"
# Extract information from DATABASE_URL
DB_HOST=$(echo $DATABASE_URL | sed 's/.*@\([^:]*\):.*/\1/')
DB_PORT=$(echo $DATABASE_URL | sed 's/.*:\([0-9]*\)\/.*/\1/')
DB_NAME=$(echo $DATABASE_URL | sed 's/.*\/\([^?]*\).*/\1/')
DB_USER=$(echo $DATABASE_URL | sed 's/.*:\/\/\([^:]*\):.*/\1/')
DB_PASS=$(echo $DATABASE_URL | sed 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/')

# Execute database dump
mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$BACKUP_DIR/db_backup_$DATE.sql.gz"

# Application files backup
log "Creating application backup"
tar -czf "$BACKUP_DIR/app_backup_$DATE.tar.gz" -C /opt/shlink-ui-rails \
    --exclude=backups \
    --exclude=logs \
    --exclude=tmp \
    .

# Clean old backups
log "Cleaning old backups"
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete

log "Backup process completed successfully"
EOF

# Grant script execution permissions
sudo chown shlink:shlink /opt/shlink-ui-rails/scripts/backup.sh
sudo chmod 750 /opt/shlink-ui-rails/scripts/backup.sh

# Configure crontab (execute backup daily at 2 AM)
sudo -u shlink crontab << 'EOF'
# Execute backup daily at 2 AM
0 2 * * * /opt/shlink-ui-rails/scripts/backup.sh
EOF

# Verify crontab
sudo -u shlink crontab -l
```

### 8.2 Log Rotation Configuration

```bash
# Configure logrotate
sudo tee /etc/logrotate.d/shlink-ui-rails << 'EOF'
/var/log/caddy/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 caddy caddy
    postrotate
        systemctl reload caddy
    endscript
}

/var/log/shlink-ui-rails/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 shlink shlink
}
EOF
```

---

## Step 9: Operation Verification and Testing

### 9.1 Basic Operation Verification

```bash
# Check service status
sudo systemctl status caddy
sudo systemctl status shlink-ui-rails

# Check ports
sudo netstat -tlnp | grep -E ':(80|443|3000)'

# Check Docker container status
sudo -u shlink docker-compose -f /opt/shlink-ui-rails/docker-compose.prod.yml ps

# Verify health checks
curl -f http://localhost:3000/health
curl -f https://app.kety.at/health
```

### 9.2 Log Verification

```bash
# Application logs
sudo -u shlink docker-compose -f /opt/shlink-ui-rails/docker-compose.prod.yml logs app

# Caddy logs
sudo tail -f /var/log/caddy/app.kety.at.log

# systemd logs
sudo journalctl -u shlink-ui-rails -f
sudo journalctl -u caddy -f
```

### 9.3 Security Verification

```bash
# Check firewall status
sudo ufw status verbose

# Check fail2ban status
sudo fail2ban-client status sshd

# Verify SSL certificate
echo | openssl s_client -connect app.kety.at:443 -servername app.kety.at 2>/dev/null | openssl x509 -noout -text

# Verify security headers
curl -I https://app.kety.at/
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Docker Containers Won't Start

```bash
# Check logs
sudo -u shlink docker-compose -f /opt/shlink-ui-rails/docker-compose.prod.yml logs app

# Check resource usage
sudo -u shlink docker stats
free -h
df -h

# Verify environment variables
sudo -u shlink cat /opt/shlink-ui-rails/.env.production
```

#### 2. Database Connection Errors

```bash
# Test connection
sudo -u shlink docker-compose -f /opt/shlink-ui-rails/docker-compose.prod.yml run --rm app rails runner "ActiveRecord::Base.connection.execute('SELECT 1')"

# Check network connectivity
ping mysql-host-name
telnet mysql-host-name 3306
```

#### 3. SSL Certificate Issues

```bash
# Check Caddy logs
sudo journalctl -u caddy -f

# Restart to re-obtain certificates
sudo systemctl restart caddy

# Check DNS configuration
nslookup app.kety.at
```

#### 4. GitHub Actions Deployment Errors

```bash
# Test SSH connection
ssh -o StrictHostKeyChecking=no shlink@your-instance-ip

# Verify GitHub Secrets
# Check Settings → Secrets and variables → Actions in repository

# Check deployment logs
sudo cat /opt/shlink-ui-rails/logs/deploy.log
```

#### 5. Performance Issues

```bash
# Check system resources
top
htop
iostat
vmstat 1

# Check application metrics
sudo -u shlink docker-compose -f /opt/shlink-ui-rails/docker-compose.prod.yml exec app rails runner "puts Rails.cache.stats"

# Analyze Caddy access logs
sudo tail -f /var/log/caddy/app.kety.at.log | jq .
```

---

## Regular Maintenance

### Weekly Tasks

```bash
# System updates
sudo apt update && sudo apt upgrade -y

# Docker cleanup
sudo -u shlink docker system prune -f

# Check log sizes
du -sh /var/log/caddy/
du -sh /var/log/shlink-ui-rails/
du -sh /opt/shlink-ui-rails/logs/
```

### Monthly Tasks

```bash
# Check backup status
ls -la /opt/shlink-ui-rails/backups/

# Security check
sudo fail2ban-client status
sudo ufw status

# Performance analysis
# Analyze access logs, check resource usage, etc.
```

---

## Security Best Practices

### Important Configuration Checks

1. **Environment file permissions:** `chmod 600 .env.production`
2. **SSH configuration:** Disable password auth, key-only authentication
3. **Firewall:** Only open necessary ports
4. **SSL/TLS:** Strong encryption configuration
5. **Rate limiting:** DDoS attack protection
6. **Log monitoring:** Detect abnormal access patterns

### Regular Security Audits

- Apply system updates
- Check SSL certificate expiration
- Detect log anomalies
- Verify backup integrity
- Review access permissions

---

## Support & Contact

When issues occur, please gather the following information before contacting support:

1. **Error messages** (complete stack traces)
2. **Log files** (relevant sections)
3. **Executed operations** (reproduction steps)
4. **Environment information** (OS, Docker, service versions)

**Log File Locations:**
- Application: `docker-compose logs`
- Caddy: `/var/log/caddy/app.kety.at.log`
- System: `/var/log/syslog`
- Deployment: `/opt/shlink-ui-rails/logs/deploy.log`

---

**📝 Note:** This guide is updated regularly. Please check for the latest version before proceeding with deployment.