# Shlink UI Rails

A modern web application built with Ruby on Rails 8 that provides a user-friendly interface for [Shlink](https://shlink.io/), the self-hosted URL shortener. This application allows users to create, manage, and track their shortened URLs with a beautiful, responsive interface.

## ✨ Features

### 🔗 URL Shortening
- **Easy URL Creation**: Convert long URLs into short, manageable links
- **Custom Slugs**: Optional custom short codes for branded links
- **QR Code Generation**: Automatic QR code creation for each shortened URL
- **One-click Copy**: Instant clipboard copying with visual feedback

### 👤 User Management
- **User Authentication**: Secure registration and login system powered by Devise
- **Google OAuth Integration**: Quick sign-in with Google accounts
- **Email Confirmation**: Secure account verification process
- **Role-based Access**: Admin and normal user roles with proper permissions

### 📊 My Page Dashboard
- **Personal URL Library**: View all your shortened URLs in one organized place
- **Statistics Tracking**: Monitor click counts and engagement metrics
- **Search & Filter**: Find specific URLs quickly with built-in search functionality
- **Pagination**: Organized display with 10 URLs per page for easy browsing
- **Real-time Sync**: Manual synchronization with Shlink API to update statistics
- **URL Management**: Edit, delete, and organize your links with confirmation dialogs

### 🎨 Modern UI/UX
- **Responsive Design**: Works perfectly on desktop, tablet, and mobile devices
- **Glass-morphism Design**: Modern, translucent interface elements with blur effects
- **Gradient Backgrounds**: Beautiful color transitions throughout the interface
- **Smooth Animations**: Fade-in effects and hover interactions
- **Status Indicators**: Visual feedback for active, expired, and limited URLs
- **Modal Dialogs**: Clean confirmation dialogs for destructive actions

### 🔧 Technical Features
- **Shlink API Integration**: Full integration with Shlink REST API v3
- **Background Processing**: Async operations with Solid Queue
- **High Performance**: Solid Cache for optimal response times
- **Real-time Updates**: Live data synchronization and updates
- **Comprehensive Error Handling**: User-friendly error messages and recovery
- **Security**: CSRF protection, secure headers, and input validation

## 🛠 Technology Stack

### Backend
- **Ruby 3.4.5** with YJIT enabled for enhanced performance
- **Rails 8.0.2.1** with the latest features and improvements
- **MySQL 8.4** for reliable and scalable data storage
- **Devise** for authentication and user session management
- **Faraday** for HTTP API communication with Shlink
- **Ridgepole** for database schema management

### Frontend
- **Hotwire (Turbo + Stimulus)** for SPA-like interactive experiences
- **Tailwind CSS v4** for modern, utility-first styling
- **Responsive Design** optimized for all device types
- **Progressive Enhancement** ensuring accessibility and performance

### Development & Testing
- **RSpec** for comprehensive behavior-driven testing
- **RuboCop Rails Omakase** for consistent code quality
- **Factory Bot** for test data generation
- **WebMock & VCR** for reliable API testing
- **SimpleCov** for test coverage analysis (93%+ coverage)
- **Docker Compose** for consistent development environments

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- A running Shlink server instance with API access

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/shlink-ui-rails.git
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
   ```

4. **Start the application**
   ```bash
   # First time setup (builds containers and sets up database)
   docker-compose up --build
   
   # Subsequent runs
   docker-compose up
   ```

5. **Access the application**
   - Web interface: http://localhost:3000
   - Database: MySQL on port 3307
   - Email preview: http://localhost:3000/letter_opener (development)

## 📱 Application Features

### Homepage
- Clean, modern landing page with URL shortening form
- Real-time validation and error handling
- Immediate QR code generation for created URLs
- One-click copy functionality with visual feedback

### User Dashboard (My Page)
- Complete overview of all user's shortened URLs
- Advanced search and filtering capabilities
- Pagination for large URL collections
- Statistics display (total URLs, visits, active links)
- Manual sync button to update data from Shlink API

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
- **Statistics Retrieval**: Real-time visit count tracking

### Service Architecture
- **Shlink::BaseService**: Foundation class with Faraday HTTP client setup
- **Shlink::CreateShortUrlService**: Handles URL creation with validation
- **Shlink::ListShortUrlsService**: Manages URL retrieval with filtering
- **Shlink::SyncShortUrlsService**: Synchronizes user data with Shlink API
- **Shlink::DeleteShortUrlService**: Manages URL deletion operations
- **Shlink::GetQrCodeService**: Handles QR code generation and caching

## 🧪 Development

### Running Tests
```bash
# Run all tests (230+ examples with 93%+ coverage)
docker-compose exec web bundle exec rspec

# Run specific test file
docker-compose exec web bundle exec rspec spec/path/to/file_spec.rb

# Run tests with detailed output
docker-compose exec web bundle exec rspec --format documentation
```

### Code Quality
```bash
# Run RuboCop linter (Rails Omakase configuration)
docker-compose exec web bundle exec rubocop

# Auto-fix violations
docker-compose exec web bundle exec rubocop --autocorrect

# Security analysis with Brakeman
docker-compose exec web bundle exec brakeman
```

### Database Operations
```bash
# Apply schema changes with Ridgepole
docker-compose exec web bundle exec ridgepole -c config/database.yml -E development --apply -f db/Schemafile

# Access Rails console
docker-compose exec web bin/rails console

# View application routes
docker-compose exec web bin/rails routes
```

### CSS Development
```bash
# Watch Tailwind CSS changes (automatic in development)
docker-compose exec web bin/rails tailwindcss:watch

# Build CSS manually
docker-compose exec web bin/rails tailwindcss:build
```

## 🏗 Architecture

### Security Features
- **User Isolation**: Users can only access and modify their own URLs
- **CSRF Protection**: Built-in Rails Cross-Site Request Forgery protection
- **Input Validation**: Comprehensive form validation with ShortenForm objects
- **Secure Headers**: Security-focused HTTP headers configuration
- **Authentication**: Devise-powered user management with confirmation

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
│   ├── application_controller.rb
│   ├── short_urls_controller.rb      # URL creation and QR codes
│   ├── mypage_controller.rb          # User dashboard and management
│   ├── pages_controller.rb           # Static pages
│   └── users/
│       └── omniauth_callbacks_controller.rb
├── forms/
│   └── shorten_form.rb               # URL validation form object
├── models/
│   ├── user.rb                       # User model with Devise
│   └── short_url.rb                  # Short URL model with validations
├── services/shlink/
│   ├── base_service.rb               # HTTP client foundation
│   ├── create_short_url_service.rb   # URL creation logic
│   ├── list_short_urls_service.rb    # URL retrieval and pagination
│   ├── sync_short_urls_service.rb    # Data synchronization
│   ├── delete_short_url_service.rb   # URL deletion handling
│   └── get_qr_code_service.rb        # QR code generation
└── views/
    ├── layouts/
    ├── short_urls/
    ├── mypage/
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
**Last Updated**: September 2025  
**Version**: 1.0.0