# Django Deployment with Docker & Nginx Tutorial

## 📋 Table of Contents (Outline)

1. [Overview](#overview)
2. [Architecture & How It Works](#architecture--how-it-works)
3. [Prerequisites](#prerequisites)
4. [Project Structure](#project-structure)
5. [Configuration Files Explained](#configuration-files-explained)
6. [Environment Setup](#environment-setup)
7. [Step-by-Step Deployment](#step-by-step-deployment)
8. [Testing & Verification](#testing--verification)
9. [Troubleshooting](#troubleshooting)
10. [Production Best Practices](#production-best-practices)
11. [Useful Commands](#useful-commands)

---

## Overview

บทความนี้จะแนะนำวิธีการ Deploy Django Application โดยใช้ Docker และ Nginx เป็น Reverse Proxy พร้อมกับ PostgreSQL Database การ Setup นี้เหมาะสำหรับ Production Environment และสามารถ Scale ได้ง่าย

### สิ่งที่จะได้เรียนรู้:
- การใช้ Docker Compose จัดการ Multi-Container Application
- การตั้งค่า Nginx เป็น Reverse Proxy
- การจัดการ Static Files และ Media Files
- การเชื่อมต่อ Django กับ PostgreSQL
- การใช้ Environment Variables เพื่อความปลอดภัย

---

## Architecture & How It Works

### สถาปัตยกรรมระบบ

```
[Client] 
    ↓ HTTP Request (Port 80/443)
[Nginx Container] 
    ↓ Proxy Pass (Port 8000)
[Django Container] 
    ↓ Database Connection (Port 5432)
[PostgreSQL Container]
```

### หลักการทำงาน

1. **Client Request**: ผู้ใช้เข้าถึงเว็บไซต์ผ่าน Browser
2. **Nginx Reverse Proxy**: 
   - รับ Request จาก Client
   - Serve Static Files (CSS, JS, Images) โดยตรง
   - Forward Dynamic Requests ไปยัง Django
3. **Django Application**: 
   - ประมวลผล Business Logic
   - เชื่อมต่อกับ Database
   - Return Response กลับผ่าน Nginx
4. **PostgreSQL Database**: เก็บข้อมูลของ Application

### ข้อดีของ Architecture นี้

- **Performance**: Nginx serve static files ได้เร็วกว่า Django
- **Scalability**: สามารถเพิ่ม Django containers ได้ง่าย
- **Security**: Nginx ทำหน้าที่เป็น Security Layer
- **Load Balancing**: Nginx สามารถกระจาย Load ได้
- **SSL Termination**: Nginx จัดการ HTTPS ได้

---

## Prerequisites

### Software Requirements
- Docker (version 20.0+)
- Docker Compose (version 2.0+)
- Git
- Text Editor (VS Code, Sublime Text, etc.)

### Knowledge Requirements
- พื้นฐาน Django Framework
- พื้นฐาน Docker และ Containerization
- พื้นฐาน Linux Commands
- การใช้งาน Command Line

### การติดตั้ง Docker

**Ubuntu/Debian:**
```bash
# Update package index
sudo apt update

# Install Docker
sudo apt install docker.io docker-compose

# Add user to docker group
sudo usermod -aG docker $USER

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker
```

**macOS:**
- ดาวน์โหลด Docker Desktop จาก https://www.docker.com/products/docker-desktop

**Windows:**
- ดาวน์โหลด Docker Desktop จาก https://www.docker.com/products/docker-desktop

---

## Project Structure

```
djangocker/
│
├── djangocker/                 # Django Project Directory
│   ├── __init__.py
│   ├── settings.py            # Django Settings
│   ├── urls.py                # URL Configuration
│   ├── wsgi.py                # WSGI Configuration
│   └── asgi.py                # ASGI Configuration
│
├── nginx/                     # Nginx Configuration
│   └── default.conf           # Nginx Server Configuration
│
├── media/                     # User Uploaded Files (Created automatically)
├── staticfiles/               # Static Files (Created automatically)
│
├── .env                       # Environment Variables (Secret)
├── .env.example               # Environment Variables Template
├── .dockerignore              # Docker Ignore File
├── .gitignore                 # Git Ignore File
├── build_files.sh             # Build Script
├── docker-compose.yml         # Docker Compose Configuration
├── Dockerfile                 # Docker Image Configuration
├── manage.py                  # Django Management Script
├── requirements.txt           # Python Dependencies
└── README.md                  # Documentation
```

### คำอธิบาย Directory

- **djangocker/**: Core Django application
- **nginx/**: Nginx configuration files
- **media/**: Directory สำหรับ user uploaded files
- **staticfiles/**: Directory สำหรับ static files (CSS, JS, Images)

---

## Configuration Files Explained

### 1. docker-compose.yml

```yaml
services:
  web:                          # Django Service
    build: .                    # Build from Dockerfile in current directory
    command: /djangocker/build_files.sh  # Run build script
    volumes:
      - ./media:/djangocker/media              # Mount media files
      - ./staticfiles:/djangocker/staticfiles  # Mount static files
    env_file:
      - .env                    # Load environment variables
    depends_on:
      - db                      # Wait for database service
    ports:
      - "8000:8000"            # Expose port 8000

  nginx:                        # Nginx Service
    image: nginx:latest         # Use official Nginx image
    ports:
      - "${NGINX_PORT}:80"      # Expose port from environment variable
    depends_on:
      - web                     # Wait for web service
    volumes:
      - ./staticfiles:/djangocker/staticfiles  # Mount static files
      - ./media:/djangocker/media              # Mount media files
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro  # Mount config

  db:                           # PostgreSQL Service
    image: postgres:15          # Use PostgreSQL 15
    restart: always             # Always restart on failure
    volumes:
      - pgdata:/var/lib/postgresql/data  # Persistent data storage
    environment:
      POSTGRES_DB: ${POSTGRES_DB}           # Database name
      POSTGRES_USER: ${POSTGRES_USER}       # Database user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}  # Database password

volumes:
  pgdata:                       # Named volume for database persistence
```

### 2. Dockerfile

```dockerfile
FROM python:3.13.2-slim        # Base image with Python 3.13
ENV PYTHONDONTWRITEBYTECODE=1   # Don't write .pyc files
ENV PYTHONUNBUFFERED=1          # Don't buffer stdout/stderr
WORKDIR /djangocker             # Set working directory
COPY requirements.txt ./        # Copy requirements first (Docker layer caching)
RUN pip install --upgrade pip && pip install -r requirements.txt
COPY . ./                       # Copy all project files
COPY build_files.sh ./          # Copy build script
RUN chmod +x ./build_files.sh   # Make build script executable
```

### 3. nginx/default.conf

```nginx
server {
    listen 80;                  # Listen on port 80
    server_name _;              # Accept all hostnames

    # Serve static files directly
    location /static/ {
        alias /djangocker/staticfiles/;
        access_log off;         # Disable access logging for static files
        expires 30d;            # Cache static files for 30 days
    }

    # Serve media files directly
    location /media/ {
        alias /djangocker/media/;
        access_log off;         # Disable access logging for media files
        expires 30d;            # Cache media files for 30 days
    }

    # Forward all other requests to Django
    location / {
        proxy_pass http://web:8000;  # Forward to Django container
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 4. build_files.sh

```bash
#!/bin/bash
# Build script for Django application

# Collect static files
python manage.py collectstatic --noinput

# Run database migrations
python manage.py migrate

# Start Django development server
python manage.py runserver 0.0.0.0:8000
```

---

## Environment Setup

### 1. สร้าง .env file

Copy จาก .env.example และแก้ไขค่าต่างๆ:

```bash
cp .env.example .env
```

### 2. แก้ไข .env file

```env
# Django Settings
DEBUG=False
SECRET_KEY=your-super-secret-key-here
ALLOWED_HOSTS=localhost,127.0.0.1,your-domain.com

# Database Settings
POSTGRES_DB=djangocker_db
POSTGRES_USER=djangocker_user
POSTGRES_PASSWORD=your-strong-password-here
DB_HOST=db
DB_PORT=5432

# Nginx Settings
NGINX_PORT=80

# Email Settings (Optional)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
```

### 3. สร้าง requirements.txt

```txt
asgiref==3.8.1
Django==5.1.7
sqlparse==0.5.3
tzdata==2025.1
gunicorn
psycopg2-binary
```

### 4. แก้ไข Django settings.py

```python
from pathlib import Path
import os

# Security
SECRET_KEY = os.environ.get("SECRET_KEY", 'secret-key')
# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.environ.get("DEBUG", 'True')
ALLOWED_HOSTS = os.getenv("ALLOWED_HOSTS", "").split(",")

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('POSTGRES_DB'),
        'USER': os.environ.get('POSTGRES_USER'),
        'PASSWORD': os.environ.get('POSTGRES_PASSWORD'),
        'HOST': os.environ.get('POSTGRES_HOST'),  # <<< service name
        'PORT': os.environ.get('POSTGRES_PORT'),
    }
}

# Static Files
STATIC_URL = '/static/'
STATICFILES_DIRS = [Path.joinpath(BASE_DIR, 'statics')]
STATIC_ROOT = Path.joinpath(BASE_DIR, 'staticfiles')

# Media Files
MEDIA_URL = '/media/'
MEDIA_ROOT = Path.joinpath(BASE_DIR, 'media')

```

---

## Step-by-Step Deployment

### Step 1: Clone และ Setup Project

```bash
# Clone project
git clone https://github.com/Apisit250aps/djangocker.git
cd djangocker

# Copy environment file
cp .env.example .env

# Edit environment variables
nano .env  # หรือใช้ editor ที่ชอบ
```

### Step 2: Build และ Start Services

```bash
# Build และ start all services
docker-compose up --build

# หรือรันใน background
docker-compose up --build -d
```

### Step 3: Monitor Logs

```bash
# ดู logs ทั้งหมด
docker-compose logs

# ดู logs เฉพาะ service
docker-compose logs web
docker-compose logs nginx
docker-compose logs db

# Follow logs realtime
docker-compose logs -f
```

### Step 4: Create Superuser (Optional)

```bash
# เข้าไปใน Django container
docker-compose exec web bash

# สร้าง superuser
python manage.py createsuperuser

# Exit container
exit
```

### Step 5: Test Application

เปิด browser และทดสอบ:
- http://localhost (หรือ port ที่ตั้งไว้ใน NGINX_PORT)
- http://localhost/admin (Django Admin)

---

## Testing & Verification

### 1. ตรวจสอบ Services Status

```bash
# ดู running containers
docker-compose ps

# ดู resource usage
docker stats

# ตรวจสอบ networks
docker network ls
```

### 2. ทดสอบ Database Connection

```bash
# เข้าไปใน database container
docker-compose exec db psql -U djangocker_user -d djangocker_db

# ใน PostgreSQL shell
\dt  # ดู tables
\q   # exit
```

### 3. ทดสอบ Static Files

```bash
# ตรวจสอบ static files
docker-compose exec web python manage.py collectstatic --dry-run

# ดู static files directory
docker-compose exec web ls -la /djangocker/staticfiles/
```

### 4. Health Checks

```bash
# Test Django endpoint
curl http://localhost:8000/

# Test through Nginx
curl http://localhost/

# Test static files
curl http://localhost/static/admin/css/base.css
```

---

## Troubleshooting

### Common Issues และ Solutions

#### 1. Port Already in Use

**Error**: `Port 80 is already in use`

**Solution**:
```bash
# หา process ที่ใช้ port 80
sudo lsof -i :80

# Stop process หรือเปลี่ยน port ใน .env
NGINX_PORT=8080
```

#### 2. Database Connection Error

**Error**: `django.db.utils.OperationalError: could not connect to server`

**Solution**:
```bash
# ตรวจสอบ database service
docker-compose logs db

# Restart database
docker-compose restart db

# ตรวจสอบ environment variables
docker-compose exec web env | grep POSTGRES
```

#### 3. Static Files Not Loading

**Error**: Static files return 404

**Solution**:
```bash
# Run collectstatic
docker-compose exec web python manage.py collectstatic

# ตรวจสอบ nginx config
docker-compose exec nginx nginx -t

# Restart nginx
docker-compose restart nginx
```

#### 4. Permission Denied

**Error**: `Permission denied` เมื่อ build

**Solution**:
```bash
# เปลี่ยน ownership
sudo chown -R $USER:$USER .

# เปลี่ยน permissions
chmod +x build_files.sh
```

#### 5. Memory Issues

**Error**: Container ถูก killed หรือ out of memory

**Solution**:
```bash
# เพิ่ม memory limit ใน docker-compose.yml
services:
  web:
    mem_limit: 512m
    
# หรือ cleanup unused containers/images
docker system prune -a
```

### Debug Commands

```bash
# เข้าไปใน container เพื่อ debug
docker-compose exec web bash
docker-compose exec nginx bash
docker-compose exec db bash

# ดู container details
docker inspect djangocker_web_1

# ดู logs แบบ realtime
docker-compose logs -f web

# ตรวจสอบ network connectivity
docker-compose exec web ping db
docker-compose exec web ping nginx
```

---

## Production Best Practices

### 1. Security

```yaml
# docker-compose.prod.yml
services:
  web:
    environment:
      - DEBUG=False
    restart: always
    
  nginx:
    volumes:
      - ./nginx/ssl:/etc/nginx/ssl:ro  # SSL certificates
      
  db:
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password
```

### 2. SSL/HTTPS Setup

```nginx
# nginx/default.conf for production
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    
    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}
```

### 3. Performance Optimization

```python
# settings.py for production
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': '/djangocker/logs/django.log',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}

# Cache Configuration
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'redis://redis:6379/1',
    }
}
```

### 4. Monitoring และ Backup

```bash
# Backup script
#!/bin/bash
# backup.sh

# Database backup
docker-compose exec -T db pg_dump -U djangocker_user djangocker_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Media files backup
tar -czf media_backup_$(date +%Y%m%d_%H%M%S).tar.gz ./media/
```

### 5. Auto-scaling with Docker Swarm

```yaml
# docker-compose.swarm.yml
version: '3.8'
services:
  web:
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
```

---

## Useful Commands

### Docker Compose Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Rebuild and start
docker-compose up --build

# Scale services
docker-compose up --scale web=3

# View logs
docker-compose logs -f web

# Execute commands in container
docker-compose exec web python manage.py shell

# Update services
docker-compose pull && docker-compose up -d
```

### Django Management Commands

```bash
# Inside web container
docker-compose exec web python manage.py makemigrations
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py createsuperuser
docker-compose exec web python manage.py collectstatic
docker-compose exec web python manage.py shell
```

### Maintenance Commands

```bash
# Cleanup unused Docker resources
docker system prune -a

# Backup database
docker-compose exec db pg_dump -U djangocker_user djangocker_db > backup.sql

# Restore database
cat backup.sql | docker-compose exec -T db psql -U djangocker_user djangocker_db

# Monitor resource usage
docker stats
```

---

## Conclusion

การ Deploy Django ด้วย Docker และ Nginx ให้ประโยชน์มากมาย:

- **Consistency**: Environment เหมือนกันทุกที่
- **Scalability**: สามารถ scale ได้ง่าย
- **Maintainability**: จัดการและ update ง่าย
- **Security**: Nginx ทำหน้าที่เป็น Security Layer

การ Setup นี้เหมาะสำหรับ Production และสามารถปรับแต่งเพิ่มเติมได้ตามความต้องการ เช่น การเพิ่ม Redis สำหรับ Caching, การใช้ CDN สำหรับ Static Files, หรือการ Setup Load Balancer

สำหรับข้อสงสัยหรือปัญหาเพิ่มเติม สามารถ refer back มายัง documentation นี้หรือตรวจสอบ logs เพื่อ debug ปัญหาได้

**Happy Deploying! 🚀**

---
[Apisit250aps](https://github.com/Apisit250aps)