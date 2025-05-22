# Django Docker Deployment with Nginx & PostgreSQL

This project demonstrates how to deploy a Django application using Docker Compose with Nginx as a reverse proxy and PostgreSQL as the database.

## 🏗️ Architecture

The application consists of three main services:

- **Web (Django)**: Django application running with Gunicorn WSGI server
- **Nginx**: Reverse proxy server handling static files and forwarding requests
- **Database**: PostgreSQL database for data persistence

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    Nginx    │───▶│   Django    │───▶│ PostgreSQL  │
│   Port 80   │    │  Port 8000  │    │  Database   │
└─────────────┘    └─────────────┘    └─────────────┘
```

## 📁 Project Structure

```
djangocker/
├── docker-compose.yml          # Docker Compose configuration
├── build_files.sh             # Build script for migrations and static files
├── requirements.txt           # Python dependencies
├── nginx/
│   └── default.conf          # Nginx configuration
├── djangocker/
│   ├── settings.py           # Django settings
│   ├── urls.py              # URL configuration
│   ├── wsgi.py              # WSGI application
│   └── asgi.py              # ASGI application
├── manage.py                 # Django management script
├── staticfiles/              # Collected static files (auto-generated)
├── media/                    # User uploaded media files
└── .env                      # Environment variables
```

## 🚀 Quick Start

### Prerequisites

- Docker
- Docker Compose

### 1. Clone the Repository

```bash
git clone <repository-url>
cd djangocker
```

### 2. Create Environment File

Create a `.env` file in the root directory:

```env
# Django Settings
SECRET_KEY=your-super-secret-key-here
DEBUG=False
ALLOWED_HOSTS=localhost,127.0.0.1,your-domain.com

# PostgreSQL Database
POSTGRES_DB=djangocker_db
POSTGRES_USER=django_user
POSTGRES_PASSWORD=your-strong-password
POSTGRES_HOST=db
POSTGRES_PORT=5432
```

### 3. Build and Run

```bash
# Build and start all services
docker-compose up --build

# Or run in detached mode
docker-compose up -d --build
```

### 4. Access the Application

- **Application**: http://localhost
- **Django Admin**: http://localhost/admin/

## 🔧 Development Commands

### Create Superuser

```bash
docker-compose exec web python manage.py createsuperuser
```

### Run Migrations

```bash
docker-compose exec web python manage.py migrate
```

### Collect Static Files

```bash
docker-compose exec web python manage.py collectstatic --noinput
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f nginx
docker-compose logs -f db
```

### Stop Services

```bash
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

## 📝 Services Configuration

### Django Web Service

- **Framework**: Django 5.1.7
- **WSGI Server**: Gunicorn
- **Port**: 8000 (internal)
- **Volumes**: 
  - `./media:/djangocker/media` - Media files
  - `./staticfiles:/djangocker/staticfiles` - Static files

### Nginx Service

- **Image**: nginx:latest
- **Port**: 80 (external)
- **Purpose**: 
  - Reverse proxy to Django
  - Serve static and media files
  - Load balancing (if scaled)

### PostgreSQL Service

- **Image**: postgres:15
- **Port**: 5432 (internal)
- **Volume**: `pgdata:/var/lib/postgresql/data`
- **Auto-restart**: enabled

## 🔒 Security Considerations

### For Production Deployment:

1. **Environment Variables**: 
   - Use strong, unique SECRET_KEY
   - Set DEBUG=False
   - Configure proper ALLOWED_HOSTS

2. **Database Security**:
   - Use strong passwords
   - Consider database access restrictions

3. **Nginx Configuration**:
   - Add SSL/TLS certificates
   - Configure security headers
   - Set up rate limiting

4. **Docker Security**:
   - Use non-root user in containers
   - Keep images updated
   - Scan for vulnerabilities

## 🐛 Troubleshooting

### Common Issues

**Database Connection Error**:
```bash
# Check if database service is running
docker-compose ps

# Check database logs
docker-compose logs db
```

**Static Files Not Loading**:
```bash
# Rebuild and collect static files
docker-compose exec web python manage.py collectstatic --noinput
```

**Permission Issues**:
```bash
# Fix file permissions
chmod +x build_files.sh
```

### Useful Commands

```bash
# Enter Django container shell
docker-compose exec web bash

# Enter PostgreSQL shell
docker-compose exec db psql -U django_user -d djangocker_db

# Restart specific service
docker-compose restart web
```

## 📦 Dependencies

### Python Packages
- Django 5.1.7
- Gunicorn (WSGI server)
- psycopg2-binary (PostgreSQL adapter)

### System Requirements
- Docker Engine 20.10+
- Docker Compose 2.0+

## 🚀 Production Deployment

For production deployment, consider:

1. **Environment Variables**: Use Docker secrets or external secret management
2. **SSL/HTTPS**: Configure SSL certificates in Nginx
3. **Domain Configuration**: Update Nginx server_name and Django ALLOWED_HOSTS
4. **Database Backup**: Implement regular PostgreSQL backups
5. **Monitoring**: Add health checks and monitoring solutions
6. **Scaling**: Use Docker Swarm or Kubernetes for multi-instance deployment

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

For more information about Django deployment, visit the [official Django documentation](https://docs.djangoproject.com/en/5.1/howto/deployment/).