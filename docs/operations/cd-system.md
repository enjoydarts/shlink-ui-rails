# 🚀 CI/CD System Documentation

This document describes the Continuous Deployment (CD) system used in Shlink-UI-Rails, which provides automated deployment to production using GitHub Actions.

## 📋 System Overview

The CD system implements automated deployment triggered by pushes to the main branch, including test execution, deployment, health checks, and automatic rollback on failure.

```
GitHub Repository (main branch)
       ↓ push trigger
GitHub Actions Workflow
       ├── Pre-checks
       ├── Test Execution
       ├── Docker Image Build & Push
       ├── Production Deployment
       ├── Health Check & Verification
       └── Notification
```

## 🔧 Workflow Components

### 1. Pre-checks

**Purpose**: Determine whether deployment should proceed

**Process**:
- Check if commit message contains `[skip deploy]`
- Verify test skip settings for manual execution
- Pass deployment execution flags to other jobs

**Skip Conditions**:
- Commit message contains `[skip deploy]`

### 2. Test Execution

**Purpose**: Verify code quality and tests

**Process**:
- Start MySQL and Redis service containers
- Set up Ruby environment
- Set up database
- Run RuboCop code quality checks
- Execute RSpec tests

**Skip Conditions**:
- Pre-checks set skip flag
- Test skip specified during manual execution (emergency deployments)

### 3. Docker Image Build & Push

**Purpose**: Build and publish Docker images

**Process**:
- Build multi-stage Docker image
- Tag image with commit SHA and 'latest'
- Push to GitHub Container Registry (ghcr.io)
- Cache layers for faster builds

**Registry**: `ghcr.io/yourusername/shlink-ui-rails`

### 4. Production Deployment

**Purpose**: Deploy application to production server

**Process**:
- Connect to production server via SSH
- Pull latest Docker image
- Update environment configuration
- Apply database migrations (Ridgepole)
- Restart application services
- Verify container startup

**Target Server**: `yourdomain.com`

### 5. Health Check & Verification

**Purpose**: Verify successful deployment

**Process**:
- HTTP health endpoint check (`/health`)
- Database connectivity verification
- Service availability confirmation
- Response time validation

**Retry Logic**:
- Maximum 10 attempts
- 30-second intervals
- Automatic rollback on failure

### 6. Post-deployment Notification

**Purpose**: Notify team of deployment results

**Supported Channels**:
- Slack notifications
- Discord notifications
- Email notifications

## 🔑 Required Secrets

Configure these secrets in GitHub repository settings:

### Deployment Secrets
| Secret Name | Description |
|-------------|-------------|
| `DEPLOY_HOST` | Production server IP address |
| `DEPLOY_USER` | SSH username for production server |
| `DEPLOY_KEY` | SSH private key for server access |
| `PRODUCTION_ENV` | Complete `.env.production` file content |

### Notification Secrets (Optional)
| Secret Name | Description |
|-------------|-------------|
| `SLACK_WEBHOOK_URL` | Slack webhook URL for notifications |
| `DISCORD_WEBHOOK_URL` | Discord webhook URL for notifications |
| `NOTIFICATION_EMAIL` | Email address for notifications |

## 🎛️ Workflow Configuration

### Automatic Triggers

**Main Branch Push**:
```yaml
on:
  push:
    branches: [ main ]
```

**Manual Trigger**:
```yaml
on:
  workflow_dispatch:
    inputs:
      skip_tests:
        description: 'Skip tests (emergency deployment)'
        required: false
        default: false
        type: boolean
```

### Environment Variables

**Production Environment**:
- `RAILS_ENV=production`
- `DOCKER_DEFAULT_PLATFORM=linux/amd64`
- Custom environment from `PRODUCTION_ENV` secret

## 🛡️ Safety Features

### Pre-deployment Checks
- Comprehensive test suite execution
- Code quality validation (RuboCop)
- Security scanning (Brakeman)
- Database migration dry-run

### Rollback Mechanism
- Automatic rollback on health check failure
- Previous image preservation
- Database migration rollback capability
- Service restoration procedures

### Blue-Green Deployment Simulation
- Zero-downtime deployment strategy
- Health check before traffic routing
- Gradual service restart

## 📊 Monitoring Integration

### Health Endpoints
```bash
# Application health (Rails standard)
GET /health
GET /up

# Application version
GET /version
```

### Metrics Collection
- Deployment frequency tracking
- Success/failure rates
- Rollback frequency
- Deployment duration metrics

## 🔧 Manual Deployment

### Emergency Deployment
For urgent deployments that need to skip tests:

1. Go to GitHub Actions tab
2. Select "Deploy to Production" workflow
3. Click "Run workflow"
4. Check "Skip tests (emergency deployment)"
5. Click "Run workflow"

### Manual Rollback
```bash
# SSH to production server
ssh user@yourdomain.com

# Rollback to previous image
docker-compose -f docker-compose.prod.yml down
docker tag ghcr.io/yourusername/shlink-ui-rails:previous ghcr.io/yourusername/shlink-ui-rails:latest
docker-compose -f docker-compose.prod.yml up -d

# Verify rollback
docker-compose logs -f app
```

## 🐛 Troubleshooting

### Common Issues

#### Deployment Fails at Health Check
```bash
# Check application logs
docker-compose logs app

# Check container status
docker-compose ps

# Manual health check
curl -f https://yourdomain.com/health
```

#### SSH Connection Issues
```bash
# Verify SSH key is correct
ssh -i path/to/key user@server

# Check server SSH configuration
sudo systemctl status ssh
```

#### Docker Build Failures
```bash
# Check build logs in GitHub Actions
# Review Dockerfile changes
# Verify base image availability
```

#### Database Migration Failures
```bash
# Check migration status
bundle exec ridgepole -c config/database.yml -E production --dry-run -f db/schemas/Schemafile

# Manual migration
bundle exec ridgepole -c config/database.yml -E production --apply -f db/schemas/Schemafile
```

### Debug Commands

#### Deployment Status
```bash
# Check running containers
docker ps

# View deployment logs
journalctl -u docker -f

# Check application health
curl -i https://yourdomain.com/health
```

#### Performance Monitoring
```bash
# Resource usage
docker stats

# Application metrics
docker exec app rails runner "puts Rails.cache.stats"

# Database performance
docker exec app rails dbconsole -c "SHOW PROCESSLIST;"
```

## 📈 Performance Optimization

### Build Optimization
- Multi-stage Docker builds
- Layer caching
- Minimal base images
- Asset precompilation

### Deployment Speed
- Parallel job execution
- Incremental updates
- Smart cache invalidation
- Optimized health checks

## 🔗 Related Documentation

- [Production Deployment Guide](../deployment/production.md) - Manual deployment instructions
- [Monitoring Guide](monitoring.md) - Application monitoring and alerting
- [Configuration Guide](../configuration/settings.md) - Environment configuration
- [Japanese Documentation](cd-system_ja.md) - 日本語版CI/CDドキュメント

## 📞 Support

For CI/CD issues:
1. Check GitHub Actions logs for detailed error messages
2. Review the troubleshooting section above
3. Verify all required secrets are configured
4. Check server connectivity and resources
5. Review [GitHub Issues](https://github.com/enjoydarts/shlink-ui-rails/issues)

---

**Note**: This system is designed for high reliability and includes multiple safety mechanisms. Always test changes thoroughly before deploying to production.