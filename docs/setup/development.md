# 🚀 Development Environment Setup Guide

This guide provides step-by-step instructions for setting up Shlink-UI-Rails in a development environment.

## 🎯 Prerequisites

- Docker and Docker Compose
- Git
- Ruby 3.4.5 (optional, for local development without Docker)
- MySQL 8.4+ (optional, for local development without Docker)

## 📋 Quick Start with Docker (Recommended)

### 1. Clone the Repository
```bash
git clone https://github.com/enjoydarts/shlink-ui-rails.git
cd shlink-ui-rails
```

### 2. Initial Setup
```bash
# Start services and set up the database
make setup

# Or manually:
# docker compose up -d
# docker compose exec web bundle exec ridgepole -c config/database.yml -E development --apply -f db/schemas/Schemafile
# docker compose exec web rails db:seed
```

### 3. Access the Application
- **Web Application**: http://localhost:3000
- **Admin Account**:
  - Email: `admin@example.com`
  - Password: `password`

⚠️ **Security Note**: Change the admin password after first login in development

## 🔧 Development Commands

### Essential Commands
```bash
# Start services
make up

# Stop services
make down

# Run tests
make test

# Run linter
make lint

# Fix linting issues automatically
make lint-fix

# View logs
make logs

# Open Rails console
make console

# Run migrations (uses Ridgepole)
make db-migrate
```

### Manual Docker Commands
```bash
# Build and start services
docker compose up -d

# View application logs
docker compose logs -f web

# Execute commands in web container
docker compose exec web bash
docker compose exec web rails console
docker compose exec web bundle exec rspec

# Database operations
docker compose exec web bundle exec ridgepole -c config/database.yml -E development --apply -f db/schemas/Schemafile
```

## 🏗️ Local Development Setup (Without Docker)

If you prefer to run the application locally without Docker:

### 1. Install Dependencies
```bash
# Install Ruby dependencies
bundle install
```

### 2. Database Setup
```bash
# Start MySQL server (ensure MySQL 8.0+ is running)
# Create database and apply schema
bundle exec ridgepole -c config/database.yml -E development --apply -f db/schemas/Schemafile

# Seed initial data
rails db:seed
```

### 3. Start Services
```bash
# Start Rails server
rails server

# In another terminal, start Tailwind CSS compilation
rails tailwindcss:watch

# Or use foreman if available
foreman start -f Procfile.dev
```

## 🛠️ Configuration

### Environment Variables for Development
Create a `.env.development` file:

```bash
# Database
DATABASE_URL=mysql2://root@localhost:3306/shlink_ui_rails_development

# Shlink API (for testing with real Shlink instance)
SHLINK_BASE_URL=http://localhost:8080
SHLINK_API_KEY=your_api_key

# Redis (optional, for caching)
REDIS_URL=redis://localhost:6379/0

# Email settings (for testing)
EMAIL_ADAPTER=letter_opener  # Opens emails in browser

# OAuth (optional)
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret

# WebAuthn (for security key testing)
WEBAUTHN_RP_ID=localhost
WEBAUTHN_ORIGIN=http://localhost:3000
```

### Development Features
- **Letter Opener**: Emails open in browser instead of being sent
- **Tailwind CSS Watch**: CSS changes are automatically recompiled
- **Debug Mode**: Detailed error pages and logging
- **Test Data**: Sample URLs and users for testing
- **Importmap**: Modern JavaScript without Node.js build step
- **Hotwire**: Turbo + Stimulus for reactive frontend

## 🧪 Testing

### Running Tests
```bash
# All tests
make test

# Specific test files
docker compose exec web rspec spec/models/user_spec.rb
docker compose exec web rspec spec/system/

# With coverage
COVERAGE=true make test
```

### Test Database
Tests use a separate test database that is automatically created and managed.

## 🔍 Development Tools

### Debugging
- **byebug**: Add `byebug` in your code for breakpoints
- **Rails console**: `make console` or `rails console`
- **Logs**: `make logs` or `tail -f log/development.log`

### Code Quality
- **RuboCop**: `make lint` - Ruby code style checker
- **Brakeman**: `make security` - Security vulnerability scanner
- **RSpec**: Test framework with Capybara for system testing
- **Ridgepole**: Schema management tool

## 🆘 Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Find process using port 3000
lsof -ti:3000
# Kill the process
kill -9 <process_id>
```

#### Database Connection Issues
```bash
# Reset database
docker compose exec web bundle exec ridgepole -c config/database.yml -E development --drop --apply -f db/schemas/Schemafile
docker compose exec web rails db:seed
```

#### Permission Issues (Linux)
```bash
# Fix file permissions
sudo chown -R $USER:$USER .
```

#### CSS Compilation Issues
```bash
# Rebuild CSS
docker compose exec web rails tailwindcss:build

# Or restart CSS watch service
docker compose restart css
```

### Logs and Debugging
```bash
# Application logs
docker compose logs -f web

# Database logs
docker compose logs -f db

# All services
docker compose logs -f
```

## 📚 Next Steps

After setting up your development environment:

1. **Explore the Code**: Start with `app/controllers/` and `app/models/`
2. **Read the Configuration Guide**: [Configuration Settings](../configuration/settings.md)
3. **Check the Deployment Guide**: [Production Deployment](../deployment/production.md)
4. **Review the Operations Guide**: [CI/CD System](../operations/cd-system.md)

## 🔗 Additional Resources

- [Main README](../../README.md) - Project overview and features
- [Japanese Documentation](development_ja.md) - 日本語版開発環境セットアップ
- [Production Setup](../deployment/production.md) - Production deployment guide
- [Configuration Guide](../configuration/settings.md) - Detailed configuration options

---

**Need Help?**
- Check the [Issues](https://github.com/enjoydarts/shlink-ui-rails/issues) page
- Review existing [Pull Requests](https://github.com/enjoydarts/shlink-ui-rails/pulls)
- Read the troubleshooting section above