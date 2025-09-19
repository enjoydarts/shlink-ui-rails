# Shlink UI Rails

<img width="1920" height="793" alt="localhost_3000_account" src="https://github.com/user-attachments/assets/b74e1bba-c9fe-4c89-b8c9-41f1910088d8" />

A modern web application built with Ruby on Rails 8 that provides a user-friendly interface for [Shlink](https://shlink.io/), the self-hosted URL shortener. This application allows users to create, manage, and track their shortened URLs with a beautiful, responsive interface.

## ✨ Features

### 🔗 URL Management
- **Easy URL Creation**: Convert long URLs into short, manageable links
- **Custom Slugs**: Optional custom short codes for branding
- **QR Code Generation**: Automatic QR codes for each shortened URL
- **Advanced Options**: Expiration dates, visit limits, and tagging
- **Bulk Operations**: Manage multiple URLs efficiently

### 👤 User Experience
- **Intuitive Dashboard**: Clean, responsive interface optimized for all devices
- **Real-time Analytics**: Comprehensive visit statistics and insights
- **Smart Search**: Gmail-style search across URLs, titles, and tags
- **Mobile-first Design**: Seamless experience on phones, tablets, and desktops

### 🔐 Security & Authentication
- **Multi-factor Authentication**: TOTP (app-based) + WebAuthn/FIDO2 security keys
- **OAuth Integration**: Google Sign-In with intelligent 2FA handling
- **Role-based Access**: User and admin roles with appropriate permissions
- **CAPTCHA Protection**: Cloudflare Turnstile integration for spam prevention
- **Rate Limiting**: Configurable limits for API and authentication endpoints

### 🛡️ Admin Features
- **System Dashboard**: Real-time monitoring and statistics
- **User Management**: Comprehensive user administration tools
- **Dynamic Configuration**: Live system settings without restarts
- **Background Job Monitoring**: SolidQueue job tracking and management
- **Health Monitoring**: System resource and service health checks

## 🛠 Technology Stack

**Backend:**
- Ruby 3.4.5 + Rails 8.0.2
- MySQL 8.4 with Ridgepole for schema management
- Redis for caching and sessions
- SolidQueue for background jobs

**Frontend:**
- Hotwire (Turbo + Stimulus) for reactive interactions
- Tailwind CSS 4 for styling
- Importmap for modern JavaScript without build steps

**Infrastructure:**
- Docker Compose for development and production
- Caddy for reverse proxy and SSL termination
- GitHub Actions for CI/CD

## 🚀 Quick Start

### Development Setup

```bash
# Clone the repository
git clone https://github.com/enjoydarts/shlink-ui-rails.git
cd shlink-ui-rails

# Start with Docker (recommended)
make setup
# This will: start services, set up database, seed data

# Access the application
open http://localhost:3000
```

**Default credentials:**
- Email: `admin@example.com`
- Password: `password`

### Essential Commands
```bash
make up        # Start services
make down      # Stop services
make test      # Run tests (RSpec)
make lint      # Code quality (RuboCop)
make console   # Rails console
```

## 🚢 Production Deployment

**Quick Production Setup:**
```bash
# Configure environment
cp .env.example .env.production
# Edit .env.production with your settings

# Deploy with Docker Compose
docker-compose -f docker-compose.prod.yml up -d
```

**Key Requirements:**
- External MySQL database
- Redis instance
- Domain with SSL (automatic with Caddy)
- SMTP or MailerSend for emails

## 📚 Documentation

Comprehensive guides are available in the `/docs` directory:

- **[Development Setup](docs/setup/development.md)** - Complete development environment guide
- **[Production Deployment](docs/deployment/production.md)** - Production deployment and configuration
- **[Configuration Settings](docs/configuration/settings.md)** - Detailed configuration options
- **[CI/CD System](docs/operations/cd-system.md)** - Automated deployment and testing
- **[Monitoring Guide](docs/operations/monitoring.md)** - Application monitoring and alerting

**日本語ドキュメント** (Japanese documentation) also available for all guides.

## 🔌 API Integration

Integrates with Shlink REST API v3 for:
- URL creation, editing, and deletion
- Visit statistics and analytics
- QR code generation
- Bulk operations and synchronization

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests: `make test && make lint`
5. Commit changes (`git commit -m 'Add amazing feature'`)
6. Push to branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Shlink](https://shlink.io/) - The powerful, self-hosted URL shortener
- [Ruby on Rails](https://rubyonrails.org/) - The robust web application framework
- [Tailwind CSS](https://tailwindcss.com/) - The utility-first CSS framework
- [Hotwire](https://hotwired.dev/) - The modern approach to building web applications

---

Built with ❤️ using Ruby on Rails

**Author**: enjoydarts
**Version**: 1.2.0