# Shlink UI Rails

<img width="1920" height="793" alt="localhost_3000_account" src="https://github.com/user-attachments/assets/b74e1bba-c9fe-4c89-b8c9-41f1910088d8" />

A modern web application built with Ruby on Rails 8 that provides a user-friendly interface for [Shlink](https://shlink.io/), the self-hosted URL shortener. This application allows users to create, manage, and track their shortened URLs with a beautiful, responsive interface.

## ✨ Features

### 🔗 URL Shortening
- **Easy URL Creation**: Convert long URLs into short, manageable links
- **Custom Slugs**: Optional custom short codes for branded links
- **QR Code Generation**: Automatic QR code creation for each shortened URL
- **One-click Copy**: Instant clipboard copying with visual feedback
- **Gmail-style Tag Input**: Modern in-field tag display with Enter key confirmation and visual feedback
- **Advanced Options**: Access to expiration dates, visit limits, and tagging features

### 👤 User Management & Security
- **User Authentication**: Secure registration and login system powered by Devise
- **Google OAuth Integration**: Quick sign-in with Google accounts
- **Email Confirmation**: Secure account verification process
- **CAPTCHA Protection**: Cloudflare Turnstile bot attack prevention
- **Two-Factor Authentication (2FA)**: TOTP (RFC 6238) time-based authentication
- **WebAuthn/FIDO2**: Passwordless authentication and security key support
- **Backup Codes**: Single-use 2FA recovery codes
- **Role-based Access**: Proper admin and normal user role permissions

### 🔧 Admin Panel Features (NEW!)
- **Admin Dashboard**: System-wide statistics, server resource monitoring, and error status checks
- **Independent Login System**: Dedicated admin login separate from normal users
- **Comprehensive User Management**: Full user listing, search, permission changes, and account deletion
- **Real-time Statistics**: All users' short URLs, access patterns, and system health status
- **Dynamic System Configuration**: Real-time CAPTCHA, rate limiting, and email settings management
- **Server Monitoring**: Real-time memory, CPU, and disk usage monitoring
- **Settings Test Features**: One-click testing for email and CAPTCHA configurations
- **Intuitive Admin UI**: Responsive Tailwind CSS-designed dedicated admin interface

### 📊 My Page Dashboard
- **Personal URL Library**: View all your shortened URLs in one organized place
- **Advanced Statistics Dashboard**: Comprehensive analytics with interactive Chart.js visualizations
- **Overall Statistics**: Total URLs, visits, and active links with real-time data from Shlink API
- **Individual URL Analytics**: Detailed statistics per URL including daily/hourly visits, browser stats, country distribution, and referrer analysis
- **Interactive Charts**: Daily access trends, URL status distribution, and monthly creation patterns
- **Period Filtering**: View statistics for 7 days, 1 month, 3 months, or 1 year periods
- **Searchable URL Selection**: Gmail-style search for finding specific URLs by title, short URL, or long URL
- **Quick Analysis Access**: Direct analysis buttons on each URL card for instant insights
- **Search & Filter**: Find specific URLs quickly with built-in search functionality
- **Pagination**: Organized display with 10 URLs per page for easy browsing
- **Real-time Sync**: Manual synchronization with Shlink API to update statistics
- **Soft Delete Management**: Deleted URLs are hidden from view but preserved in database
- **URL Management**: Edit, delete, and organize your links with confirmation dialogs
- **Responsive Tag Display**: Optimized tag layout for mobile and desktop viewing
- **Status Indicators**: Clear visual feedback for URL status and tag information

### 🎨 Modern UI/UX
- **Mobile-First Design**: Enhanced mobile browser support with optimized compatibility settings
- **Responsive Design**: Works perfectly on desktop, tablet, and mobile devices with mobile-optimized navigation
- **Hamburger Menu**: Clean mobile navigation with slide-down menu for compact screens
- **Gmail-style Tag Input**: Tags display within input field with visual separation and smooth interactions
- **Glass-morphism Design**: Modern, translucent interface elements with blur effects
- **Clean Interface**: Removed excessive gradients for better readability and accessibility
- **Smooth Animations**: Fade-in effects and hover interactions
- **Status Indicators**: Visual feedback for active, expired, and limited URLs
- **Modal Dialogs**: Clean confirmation dialogs for destructive actions
- **Tag Visualization**: Distinct tag design with responsive layout optimization

### 🔧 Technical Features
- **Shlink API Integration**: Full integration with Shlink REST API v3 with comprehensive visit statistics
- **Advanced Analytics**: Real-time data processing with Shlink visit endpoints for detailed insights
- **Background Processing**: Async operations with Solid Queue
- **High Performance Caching**: Solid Cache with MySQL backend for optimal statistics response times
- **Interactive Data Visualization**: Chart.js integration for dynamic, responsive charts
- **Real-time Updates**: Live data synchronization and updates from Shlink API
- **Comprehensive Error Handling**: User-friendly error messages and recovery
- **Advanced Security**: CSRF protection, secure headers, 2FA, FIDO2/WebAuthn, and Cloudflare Turnstile CAPTCHA
- **Anti-Bot Protection**: Cloudflare Turnstile CAPTCHA integration for login and registration

## 🛠 Technology Stack

### Backend
- **Ruby 3.4.5** with YJIT enabled for enhanced performance
- **Rails 8.0.2.1** with the latest features and improvements
- **MySQL 8.4** for reliable and scalable data storage
- **Devise** for authentication and user session management
- **Faraday** for HTTP API communication with Shlink
- **Config gem** for centralized configuration management
- **Ridgepole** for database schema management
- **ROTP & RQRCode** for TOTP-based two-factor authentication
- **WebAuthn** for FIDO2/hardware security key authentication
- **MailerSend** for production email delivery

### Frontend
- **Hotwire (Turbo + Stimulus)** for SPA-like interactive experiences
- **Chart.js 4.4.0** for interactive and responsive data visualizations
- **Tailwind CSS v4** for modern, utility-first styling
- **Advanced Stimulus Controllers** for statistics charts, individual analysis, and tab navigation
- **Responsive Design** optimized for all device types
- **Progressive Enhancement** ensuring accessibility and performance

### Development & Testing
- **RSpec** for comprehensive behavior-driven testing
- **RuboCop Rails Omakase** for consistent code quality
- **Factory Bot** for test data generation
- **WebMock & VCR** for reliable API testing
- **SimpleCov** for test coverage analysis (80.8%+ coverage)
- **Docker Compose** for consistent development environments

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- A running Shlink server instance with API access

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/enjoydarts/shlink-ui-rails.git
   cd shlink-ui-rails
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your Shlink API credentials
   ```

3. **Configure your Shlink settings**
   ```env
   SHLINK_BASE_URL=https://your-shlink-server.com
   SHLINK_API_KEY=your-api-key-here
   GOOGLE_CLIENT_ID=your-google-client-id (optional)
   GOOGLE_CLIENT_SECRET=your-google-client-secret (optional)
   TURNSTILE_SITE_KEY=your-turnstile-site-key (optional)
   TURNSTILE_SECRET_KEY=your-turnstile-secret-key (optional)
   ```

4. **Start the application**
   ```bash
   # Using Makefile (recommended)
   make setup                    # First time setup with everything
   make up                       # Subsequent runs

   # Or using Docker Compose directly
   docker-compose up --build     # First time setup
   docker-compose up             # Subsequent runs
   ```

5. **Access the application**
   - Web interface: http://localhost:3000
   - Database: MySQL on port 3307
   - Email preview: http://localhost:3000/letter_opener (development)

## 🚀 Production Deployment

For production deployment, we support multiple deployment options:

### 📋 Initial Setup Guides
- **[Setup Guide (English)](SETUP_EN.md)** - Complete production setup instructions
- **[セットアップガイド (日本語)](SETUP_JA.md)** - 本番環境セットアップ手順

These guides cover initial admin account setup, system configuration, email settings, CAPTCHA, and security settings.

### 🚢 Production Deployment Guides
- **[Production Deployment Guide (English)](docs/deployment.md)** - Comprehensive deployment instructions for OCI/Docker
- **[本番デプロイ手順書 (日本語)](docs/deployment_ja.md)** - OCI/Docker環境での詳細なデプロイ手順

**Deployment Architecture:**
- **Server:** OCI Ampere A1 instances (ARM64)
- **Web Server:** Caddy with automatic HTTPS
- **Application:** Docker-containerized Rails app
- **Database:** External managed MySQL
- **Cache:** Upstash Redis
- **CI/CD:** GitHub Actions with automated deployment
- **Domain:** Custom domain with Cloudflare DNS
- **Monitoring:** Comprehensive logging and health checks

**Key Features:**
- Multi-platform Docker builds (AMD64/ARM64)
- Automated CI/CD with GitHub Actions
- Secure deployment with dedicated system users
- Comprehensive backup and monitoring setup
- Production-ready security configuration

## 📱 Application Features

### Homepage
- Clean, modern landing page with URL shortening form
- Real-time validation and error handling
- Interactive tag input with Enter key confirmation and visual tag management
- Advanced options including expiration dates and visit limits
- Immediate QR code generation for created URLs
- One-click copy functionality with visual feedback

### User Dashboard (My Page)
- Complete overview of all user's shortened URLs
- **Advanced Analytics Dashboard** with Chart.js-powered interactive visualizations
- **Tabbed Interface** with seamless navigation between URL list, overall statistics, and individual URL analysis
- **Overall Statistics**: Daily access trends, URL status distribution, monthly creation patterns
- **Individual URL Analytics**: Detailed insights including hourly visits, browser statistics, country distribution, and referrer analysis
- **Intelligent URL Search**: Gmail-style searchable interface for finding URLs by title, short code, or full URL
- **Quick Analysis Access**: Direct analysis buttons on URL cards for instant insights
- Advanced search and filtering capabilities
- Pagination for large URL collections
- Statistics display (total URLs, visits, active links)
- Manual sync button to update data from Shlink API
- Responsive tag visualization optimized for mobile and desktop
- Mobile-friendly tag layout with vertical stacking on small screens
- Soft delete functionality that hides deleted URLs from view

### URL Management
- Individual URL editing and customization
- Bulk operations for multiple URLs
- Modal confirmation dialogs for destructive actions
- Status indicators (active, expired, visit limit reached)
- QR code viewing and downloading

## 🔌 API Integration

### Supported Shlink API Endpoints
- **URL Creation**: `POST /rest/v3/short-urls`
- **URL Listing**: `GET /rest/v3/short-urls` (with pagination and search)
- **URL Deletion**: `DELETE /rest/v3/short-urls/{shortCode}`
- **QR Code Generation**: `GET /rest/v3/short-urls/{shortCode}/qr-code`
- **Statistics Retrieval**: `GET /rest/v3/short-urls/{shortCode}/visits` for detailed analytics
- **Global Statistics**: Real-time visit count tracking and comprehensive analytics

### Service Architecture
- **Shlink::BaseService**: Foundation class with Faraday HTTP client setup
- **Shlink::CreateShortUrlService**: Handles URL creation with validation
- **Shlink::ListShortUrlsService**: Manages URL retrieval with filtering
- **Shlink::SyncShortUrlsService**: Synchronizes user data with Shlink API
- **Shlink::DeleteShortUrlService**: Manages URL deletion operations
- **Shlink::GetQrCodeService**: Handles QR code generation and caching
- **Shlink::GetUrlVisitsService**: Retrieves detailed visit statistics for individual URLs
- **Statistics::OverallDataService**: Generates comprehensive statistics with caching
- **Statistics::IndividualUrlDataService**: Processes detailed analytics for specific URLs

## 🧪 Development

### Quick Commands with Makefile

This project includes a comprehensive Makefile for streamlined development:

```bash
# View all available commands
make help

# Development workflow
make up                       # Start services
make console                 # Open Rails console
make test                    # Run all tests
make lint                    # Run RuboCop
make lint-fix                # Auto-fix RuboCop issues

# Database operations
make db-reset                # Reset database (create + migrate)
make db-migrate              # Run development migrations
make db-migrate-test         # Run test migrations

# Specific test types
make test-system             # System tests only
make test-models             # Model tests only
make test-coverage           # Tests with coverage report

# CSS management
make css-build               # Build Tailwind CSS
make css-watch               # Watch CSS changes

# Utilities
make logs                    # View all service logs
make clean                   # Clean temporary files
make status                  # Check service status
```

### Running Tests
```bash
# Using Makefile (recommended)
make test                    # Run all tests (426+ examples with 80.8%+ coverage)
make test-file FILE=spec/path/to/file_spec.rb  # Run specific test file
make test-coverage           # Run tests with coverage report

# Using Docker Compose directly
docker-compose exec web bundle exec rspec
docker-compose exec web bundle exec rspec spec/path/to/file_spec.rb
docker-compose exec web bundle exec rspec --format documentation
```

### Code Quality
```bash
# Using Makefile (recommended)
make lint                    # Run RuboCop linter (Rails Omakase configuration)
make lint-fix                # Auto-fix violations
make security                # Security analysis with Brakeman

# Using Docker Compose directly
docker-compose exec web bundle exec rubocop
docker-compose exec web bundle exec rubocop --autocorrect
docker-compose exec web bundle exec brakeman
```

### Database Operations
```bash
# Using Makefile (recommended)
make db-reset                # Reset database completely
make db-migrate              # Apply schema changes with Ridgepole (development)
make db-migrate-test         # Apply schema changes with Ridgepole (test)

# Using Docker Compose directly
docker-compose exec web bundle exec ridgepole -c config/database.yml -E development --apply -f db/schemas/Schemafile
docker-compose exec web bin/rails console
docker-compose exec web bin/rails routes
```

### CSS Development
```bash
# Using Makefile (recommended)
make css-build               # Build CSS manually
make css-watch               # Watch Tailwind CSS changes

# Using Docker Compose directly
docker-compose exec web bin/rails tailwindcss:watch
docker-compose exec web bin/rails tailwindcss:build
```

## 🏗 Architecture

### Security Features
- **User Isolation**: Users can only access and modify their own URLs
- **CSRF Protection**: Built-in Rails Cross-Site Request Forgery protection
- **Input Validation**: Comprehensive form validation with ShortenForm objects
- **Secure Headers**: Security-focused HTTP headers configuration
- **Multi-Factor Authentication**: TOTP-based 2FA and FIDO2/WebAuthn hardware keys
- **Anti-Bot Protection**: Cloudflare Turnstile CAPTCHA for automated attack prevention
- **Secure Sessions**: Session-based 2FA flow with proper challenge-response validation
- **Authentication**: Devise-powered user management with email confirmation

### Performance Optimizations
- **YJIT**: Ruby 3.4+ Just-In-Time compiler for improved performance
- **Caching**: Solid Cache for database query optimization
- **Background Jobs**: Solid Queue for async processing
- **Asset Pipeline**: Optimized asset delivery with Propshaft
- **Database Indexing**: Proper indexing for fast query performance

### Code Organization
```
app/
├── controllers/
│   ├── application_controller.rb     # CAPTCHA and base functionality
│   ├── short_urls_controller.rb      # URL creation and QR codes
│   ├── mypage_controller.rb          # User dashboard and management
│   ├── pages_controller.rb           # Static pages
│   ├── accounts_controller.rb        # Account settings and security
│   ├── statistics/
│   │   ├── overall_controller.rb     # Overall statistics API
│   │   └── individual_controller.rb  # Individual URL analytics API
│   └── users/
│       ├── sessions_controller.rb            # Login with 2FA support
│       ├── registrations_controller.rb       # Registration with CAPTCHA
│       ├── omniauth_callbacks_controller.rb  # OAuth authentication
│       ├── two_factor_authentications_controller.rb  # 2FA management
│       └── webauthn_credentials_controller.rb        # FIDO2/WebAuthn
├── forms/
│   └── shorten_form.rb               # URL validation form object
├── models/
│   ├── user.rb                       # User model with Devise, 2FA, and WebAuthn
│   ├── short_url.rb                  # Short URL model with validations
│   └── webauthn_credential.rb        # FIDO2/WebAuthn security keys
├── services/
│   ├── shlink/
│   │   ├── base_service.rb               # HTTP client foundation
│   │   ├── create_short_url_service.rb   # URL creation logic
│   │   ├── list_short_urls_service.rb    # URL retrieval and pagination
│   │   ├── sync_short_urls_service.rb    # Data synchronization
│   │   ├── delete_short_url_service.rb   # URL deletion handling
│   │   ├── get_qr_code_service.rb        # QR code generation
│   │   └── get_url_visits_service.rb     # Visit statistics retrieval
│   ├── statistics/
│   │   ├── overall_data_service.rb       # Overall analytics processing
│   │   └── individual_url_data_service.rb # Individual URL analytics
│   ├── totp_service.rb                   # Two-factor authentication service
│   ├── webauthn_service.rb               # FIDO2/WebAuthn service
│   └── captcha_verification_service.rb  # Cloudflare Turnstile CAPTCHA
├── javascript/controllers/
│   ├── statistics_charts_controller.js    # Overall statistics charts
│   ├── individual_analysis_controller.js  # Individual URL analysis
│   ├── mypage_tabs_controller.js          # Tab navigation
│   ├── account_tabs_controller.js         # Account settings tabs
│   └── webauthn_controller.js             # FIDO2/WebAuthn operations
└── views/
    ├── layouts/
    ├── short_urls/
    ├── mypage/
    ├── accounts/                          # Account settings and security
    ├── users/
    │   └── two_factor_authentications/    # 2FA setup and verification
    └── pages/
```

## 🚢 Deployment

### Production Setup
1. **Environment Configuration**
   ```env
   RAILS_ENV=production
   SHLINK_BASE_URL=https://your-production-shlink.com
   SHLINK_API_KEY=your-production-api-key
   DATABASE_URL=mysql2://user:password@host:port/database
   SECRET_KEY_BASE=your-secret-key-base
   ```

2. **Asset Compilation**
   ```bash
   docker-compose exec web bin/rails assets:precompile
   docker-compose exec web bin/rails tailwindcss:build
   ```

3. **Database Setup**
   ```bash
   # Apply database schema with Ridgepole
   docker-compose exec web bundle exec ridgepole -c config/database.yml -E production --apply -f db/Schemafile
   ```

### Docker Deployment
The application is containerized and ready for deployment with Docker Compose or Kubernetes.

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write comprehensive tests for your changes
4. Ensure all tests pass (`bundle exec rspec`)
5. Run RuboCop and fix any issues (`bundle exec rubocop`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request with a detailed description

### Development Guidelines
- Follow Rails conventions and best practices
- Maintain test coverage above 90%
- Use RuboCop Rails Omakase configuration
- Write clear, descriptive commit messages
- Update documentation for new features

## 🆘 Troubleshooting

### Common Issues

**CSS not updating?**
```bash
# Rebuild Tailwind CSS
docker-compose exec web bin/rails tailwindcss:build
```

**Database connection errors?**
```bash
# Check database container status
docker-compose ps db
# View database logs
docker-compose logs db
```

**Shlink API errors?**
- Verify `SHLINK_BASE_URL` and `SHLINK_API_KEY` in `.env`
- Check Shlink server accessibility
- Review application logs: `docker-compose logs web`

**JavaScript not working?**
```bash
# Check importmap status
docker-compose exec web bin/rails importmap:outdated
```

### Performance Tips
- Monitor YJIT status in Ruby logs for optimal performance
- Use browser dev tools to identify unused CSS classes
- Leverage Hotwire caching for better user experience

## 🚀 Production Deployment

### Using Docker Compose (Recommended)

This application includes a comprehensive production setup with Solid Queue background job processing.

**Prerequisites:**
- Docker and Docker Compose installed
- `.env.production` file configured with production settings

**Quick Deployment:**
```bash
# Run the automated deployment script
./scripts/deploy-production.sh
```

**Manual Deployment:**
```bash
# 1. Stop any existing containers
docker-compose -f docker-compose.prod.yml down --remove-orphans

# 2. Build production images
docker-compose -f docker-compose.prod.yml build --no-cache

# 3. Start all services (app + background jobs)
docker-compose -f docker-compose.prod.yml up -d

# 4. Verify services are running
docker-compose -f docker-compose.prod.yml ps
```

**Service Architecture:**
- **app**: Main Rails application server (port 3000)
- **jobs**: Solid Queue background job worker
- **Shared volumes**: logs, tmp, storage directories

**Background Jobs:**
The application uses Solid Queue for reliable background job processing:
- Email delivery (password resets, notifications)
- URL synchronization with Shlink API
- Maintenance tasks

**Monitoring:**
- Access Solid Queue dashboard at `/admin/solid_queue`
- Monitor container logs: `docker logs shlink-ui-rails-app`
- Check job worker: `docker logs shlink-ui-rails-jobs`

**Environment Variables:**
Essential production environment variables in `.env.production`:
```bash
RAILS_ENV=production
DATABASE_URL=mysql2://user:password@host:3306/database
SHLINK_BASE_URL=https://your-shlink-instance.com
SHLINK_API_KEY=your-api-key
EMAIL_SMTP_ADDRESS=smtp.your-provider.com
EMAIL_SMTP_USER_NAME=your-email@domain.com
EMAIL_SMTP_PASSWORD=your-app-password
SECRET_KEY_BASE=your-secret-key
```

## 📚 Documentation

Comprehensive documentation is available in the `/docs` directory:

### 🚀 Getting Started
- [Development Setup](docs/setup/development.md) - Set up your development environment
- [日本語版開発環境セットアップ](docs/setup/development_ja.md) - 開発環境セットアップ（日本語）

### 🚢 Deployment
- [Production Deployment](docs/deployment/production.md) - Complete production deployment guide
- [本番デプロイガイド](docs/deployment/production_ja.md) - 本番環境デプロイ手順（日本語）

### ⚙️ Configuration
- [Configuration Settings](docs/configuration/settings.md) - Detailed configuration options
- [設定ガイド](docs/configuration/settings_ja.md) - 詳細な設定オプション（日本語）

### 🔧 Operations
- [CI/CD System](docs/operations/cd-system.md) - Automated deployment and testing
- [Monitoring & Alerting](docs/operations/monitoring.md) - Application monitoring setup
- [CI/CDシステム](docs/operations/cd-system_ja.md) - 自動デプロイとテスト（日本語）
- [監視・アラート](docs/operations/monitoring_ja.md) - アプリケーション監視設定（日本語）

### 📋 Quick Reference
- **Development**: `make setup` → `make up` → http://localhost:3000
- **Testing**: `make test` (RSpec), `make lint` (RuboCop)
- **Production**: Docker Compose + Caddy + External MySQL + Redis
- **CI/CD**: GitHub Actions with automated deployment to production

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Shlink](https://shlink.io/) - The powerful, self-hosted URL shortener
- [Ruby on Rails](https://rubyonrails.org/) - The robust web application framework
- [Tailwind CSS](https://tailwindcss.com/) - The utility-first CSS framework
- [Hotwire](https://hotwired.dev/) - The modern approach to building web applications
- [Devise](https://github.com/heartcombo/devise) - Flexible authentication solution

---

Built with ❤️ using Ruby on Rails

**Author**: enjoydarts
**Last Updated**: September 16, 2025
**Version**: 1.2.0

## 🎯 Implemented Features List

### Basic Features
- ✅ URL shortening creation
- ✅ Custom slug configuration
- ✅ Automatic QR code generation
- ✅ One-click copy
- ✅ Tag management (advanced options)
- ✅ Expiration date & visit limit settings

### User Management & Security
- ✅ User registration & login
- ✅ Google OAuth integration
- ✅ Email confirmation
- ✅ Role-based access control
- ✅ Cloudflare Turnstile CAPTCHA protection
- ✅ TOTP two-factor authentication (QR generation, backup codes)
- ✅ WebAuthn/FIDO2 security key support
- ✅ Sensitive data encryption (2FA secrets, backup codes)

### Admin Panel Features
- ✅ Admin dashboard with system statistics
- ✅ Independent admin login system
- ✅ Comprehensive user management
- ✅ Real-time system monitoring
- ✅ Dynamic system configuration
- ✅ Settings test functionality
- ✅ Background job monitoring
- ✅ Server resource monitoring
- ✅ Admin-only access controls

### My Page Features
- ✅ Personal URL listing
- ✅ Search & filtering
- ✅ Pagination (10 per page)
- ✅ Statistics display
- ✅ Shlink API synchronization
- ✅ URL deletion (with modal confirmation)
- ✅ Tag display & visualization
- ✅ Mobile-responsive tag layout

### UI/UX
- ✅ Responsive design
- ✅ Glass-morphism UI
- ✅ Smooth animations
- ✅ Status badges
- ✅ Modal dialogs
- ✅ Clean interface (gradient adjustments)
- ✅ Tag visual design

### Technical Features
- ✅ Rails 8.0 + Hotwire
- ✅ Tailwind CSS v4
- ✅ MySQL 8.4
- ✅ Docker environment
- ✅ Comprehensive testing (80.8%+ coverage, 1010 examples ALL GREEN)
- ✅ RuboCop quality management
- ✅ CI/CD GitHub Actions
- ✅ Advanced security measures (CAPTCHA, 2FA, WebAuthn)
