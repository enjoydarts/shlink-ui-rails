# 📊 Monitoring and Alerting Guide

This guide covers monitoring, alerting, and notification systems for Shlink-UI-Rails production deployments.

## 🎯 Overview

The monitoring system provides comprehensive visibility into application health, performance metrics, and automated alerting for critical issues.

## 📈 Health Monitoring

### Application Health Endpoints

The application provides the following health check endpoints:

```bash
# Main health check (Rails standard health endpoint)
GET /health
GET /up
Response: {"status": "up"}

# Application version info
GET /version
Response: {"version": "1.2.0", "commit": "abc1234", "timestamp": "2024-01-01T00:00:00Z"}
```

**Note**: Additional health endpoints for database, Redis, and Shlink API connections can be monitored through the admin dashboard at `/admin/dashboard`.

### System Monitoring

#### Resource Monitoring
```bash
# CPU and memory usage
docker stats --no-stream

# Disk usage
df -h

# Application resource limits
docker exec app sh -c 'echo "Memory: $(cat /proc/meminfo | grep MemAvailable)"; echo "CPU: $(nproc) cores"'
```

#### Log Monitoring
```bash
# Application logs
tail -f logs/production.log

# Container logs
docker-compose logs -f app

# System logs
journalctl -f -u docker
```

## 🚨 Deployment Notifications

### Supported Notification Channels

#### 1. Slack Notifications
Send notifications to Slack channels using webhook URLs.

**Setup**:
```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
```

**Message Format**:
```json
{
  "text": "🚀 **Deployment Completed**",
  "attachments": [
    {
      "color": "good",
      "fields": [
        {"title": "Project", "value": "Shlink-UI-Rails", "short": true},
        {"title": "Environment", "value": "Production (yourdomain.com)", "short": true},
        {"title": "Commit", "value": "abc1234", "short": true},
        {"title": "Image", "value": "ghcr.io/yourusername/shlink-ui-rails:latest", "short": true}
      ],
      "footer": "Deployment System",
      "ts": 1640995200
    }
  ]
}
```

#### 2. Discord Notifications
Send notifications to Discord channels using webhook URLs.

**Setup**:
```bash
export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK"
```

**Message Format**:
```json
{
  "embeds": [
    {
      "title": "🚀 Deployment Completed",
      "color": 3066993,
      "fields": [
        {"name": "Project", "value": "Shlink-UI-Rails", "inline": true},
        {"name": "Environment", "value": "Production (yourdomain.com)", "inline": true},
        {"name": "Commit", "value": "`abc1234`", "inline": true},
        {"name": "Image", "value": "ghcr.io/yourusername/shlink-ui-rails:latest", "inline": false}
      ],
      "timestamp": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

#### 3. Email Notifications
Send email notifications using the configured email system.

**Setup**:
```bash
export NOTIFICATION_EMAIL="admin@example.com"
```

### Notification Content

#### Success Notifications
```
🚀 **Deployment Completed**
**Project:** Shlink-UI-Rails
**Environment:** Production (yourdomain.com)
**Commit:** `abc1234` - Feature update
**Image:** `ghcr.io/yourusername/shlink-ui-rails:latest`
**Duration:** 2m 34s
**Health Check:** ✅ Passed
**Time:** 2024-01-01 14:30:00 JST
```

#### Failure Notifications
```
🚨 **Deployment Failed**
**Project:** Shlink-UI-Rails
**Environment:** Production (yourdomain.com)
**Commit:** `abc1234` - Feature update
**Image:** `ghcr.io/yourusername/shlink-ui-rails:latest`
**Duration:** 1m 45s
**Error Stage:** Health Check
**Error:** Health check failed after 10 attempts (HTTP 500)
**Time:** 2024-01-01 14:30:00 JST

**Next Steps:**
- Check application logs: `docker-compose logs app`
- Verify database connectivity
- Review recent changes
```

#### Rollback Notifications
```
🔄 **Automatic Rollback Completed**
**Project:** Shlink-UI-Rails
**Environment:** Production (yourdomain.com)
**Failed Commit:** `abc1234`
**Restored Commit:** `def5678`
**Rollback Duration:** 45s
**Status:** ✅ Service Restored
**Time:** 2024-01-01 14:35:00 JST
```

## ⚙️ Configuration

### GitHub Secrets Configuration (Recommended)

Add these secrets to your GitHub repository settings:

1. Go to GitHub Repository → Settings → Secrets and variables → Actions
2. Add the following secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `SLACK_WEBHOOK_URL` | Slack webhook URL | `https://hooks.slack.com/services/...` |
| `DISCORD_WEBHOOK_URL` | Discord webhook URL | `https://discord.com/api/webhooks/...` |
| `NOTIFICATION_EMAIL` | Admin email address | `admin@yourdomain.com` |

### Server-side Configuration (Optional)

For manual deployments or server-side configuration, add to `.env.production`:

```bash
# Deployment notification settings
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK
NOTIFICATION_EMAIL=admin@example.com
```

**Priority**: GitHub Secrets take precedence over `.env.production` settings.

## 🔧 Webhook Setup

### Slack Webhook Setup
1. Go to your Slack workspace settings
2. Navigate to Apps → Incoming Webhooks
3. Create a new webhook for your desired channel
4. Copy the webhook URL

### Discord Webhook Setup
1. Go to your Discord server
2. Navigate to Channel Settings → Integrations → Webhooks
3. Create a new webhook
4. Copy the webhook URL

## 📊 Application Metrics

### Performance Metrics
```bash
# Response time monitoring
curl -w "@curl-format.txt" -o /dev/null -s https://yourdomain.com/health

# Database query performance
docker exec app rails runner "
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  puts 'Database queries logged above'
"

# Cache hit rates
docker exec app rails runner "puts Rails.cache.stats"
```

### Custom Metrics Collection
```ruby
# In your Rails application
class MetricsCollector
  def self.collect_deployment_metrics
    {
      timestamp: Time.current.iso8601,
      response_time: measure_response_time,
      database_connections: ActiveRecord::Base.connection_pool.stat,
      memory_usage: `ps -o pid,ppid,pmem,rss,vsz,args -p #{Process.pid}`.split("\n")[1],
      cache_stats: Rails.cache.stats
    }
  end

  private

  def self.measure_response_time
    start_time = Time.current
    Net::HTTP.get_response(URI('http://localhost:3000/health'))
    ((Time.current - start_time) * 1000).round(2)
  end
end
```

## 🔍 Log Analysis

### Structured Logging
```ruby
# In your Rails application
Rails.logger.info({
  event: 'deployment_completed',
  commit_sha: ENV['GITHUB_SHA'],
  timestamp: Time.current.iso8601,
  metrics: {
    response_time: 150,
    memory_usage: '256MB',
    cpu_usage: '12%'
  }
}.to_json)
```

### Log Aggregation
```bash
# Centralized logging with journalctl
journalctl -t shlink-ui-rails-deploy -f --output=json

# Application-specific logs
tail -f logs/production.log | jq '.level, .message, .timestamp'

# Error tracking
grep -i error logs/production.log | tail -20
```

## 🚨 Alerting Rules

### Critical Alerts
- Application health check failures (>3 consecutive failures)
- Deployment failures
- Database connection failures
- High error rate (>5% of requests)
- Memory usage >90%
- Disk usage >85%

### Warning Alerts
- Response time >2 seconds
- Memory usage >70%
- Disk usage >70%
- Queue backup (>100 pending jobs)

### Alert Escalation
```bash
# First alert: Slack/Discord notification
# Second alert (15min): Email notification
# Third alert (30min): SMS/Phone notification (if configured)
```

## 🛠️ Custom Monitoring Setup

### External Monitoring Services

#### UptimeRobot Configuration
```bash
# Monitor URLs
https://yourdomain.com/health (every 5 minutes)
https://yourdomain.com/ (every 5 minutes)

# Alert contacts
- Email: admin@yourdomain.com
- Slack: webhook integration
- SMS: +1-555-0123 (for critical alerts)
```

#### Pingdom Setup
```bash
# HTTP check
URL: https://yourdomain.com/health
Interval: 1 minute
Timeout: 10 seconds
Expected response: 200 OK
Content check: "status":"ok"
```

### Self-hosted Monitoring

#### Grafana + Prometheus Setup
```yaml
# docker-compose.monitoring.yml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-storage:/var/lib/grafana

volumes:
  grafana-storage:
```

## 🔗 Integration Examples

### Webhook Testing
```bash
# Test Slack webhook
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test notification from Shlink-UI-Rails"}' \
  YOUR_SLACK_WEBHOOK_URL

# Test Discord webhook
curl -X POST -H 'Content-type: application/json' \
  --data '{"content":"Test notification from Shlink-UI-Rails"}' \
  YOUR_DISCORD_WEBHOOK_URL
```

### Custom Notification Scripts
```bash
#!/bin/bash
# scripts/notify.sh

MESSAGE="$1"
WEBHOOK_URL="$SLACK_WEBHOOK_URL"

if [ -n "$WEBHOOK_URL" ]; then
  curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"$MESSAGE\"}" \
    "$WEBHOOK_URL"
else
  echo "$MESSAGE" | logger -t shlink-ui-rails-deploy
fi
```

## 🔗 Related Documentation

- [CI/CD System](cd-system.md) - Automated deployment system
- [Production Deployment](../deployment/production.md) - Manual deployment guide
- [Configuration Settings](../configuration/settings.md) - Environment configuration
- [Japanese Documentation](monitoring_ja.md) - 日本語版監視ガイド

## 📞 Support

For monitoring setup issues:
1. Verify webhook URLs are correct and accessible
2. Check notification service status (Slack, Discord)
3. Review server logs for notification attempts
4. Test webhooks manually using curl commands
5. Check [GitHub Issues](https://github.com/enjoydarts/shlink-ui-rails/issues) for known issues

---

**Best Practices**: Set up monitoring and alerting before deploying to production. Test notification channels regularly and maintain an escalation plan for critical issues.