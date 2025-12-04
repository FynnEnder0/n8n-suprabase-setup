# 🚀 Hostinger VPS Deployment Guide

Complete guide to deploy this n8n + Supabase setup on a Hostinger VPS.

## 📋 Prerequisites

- Hostinger VPS with Ubuntu 20.04/22.04 or later
- Root or sudo access
- At least 2GB RAM (4GB recommended)
- 20GB disk space

## 🔧 Step 1: Initial VPS Setup

### Connect to your VPS via SSH

```bash
ssh root@your-vps-ip
```

### Update system packages

```bash
apt update && apt upgrade -y
```

### Install Docker

```bash
# Install required packages
apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Verify installation
docker --version
```

### Install Docker Compose

```bash
# Download Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### Install additional tools

```bash
apt install -y git nano ufw
```

## 🔒 Step 2: Configure Firewall

```bash
# Allow SSH (important!)
ufw allow 22/tcp

# Allow HTTP and HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Allow n8n (optional if you want direct access)
ufw allow 5678/tcp

# Allow Supabase Studio
ufw allow 3000/tcp

# Allow Supabase API
ufw allow 8000/tcp

# Enable firewall
ufw --force enable

# Check status
ufw status
```

## 📦 Step 3: Deploy the Application

### Clone or upload the repository

```bash
# Option 1: If your code is in a Git repository
cd /opt
git clone https://github.com/yourusername/docker-n8n-supabase.git
cd docker-n8n-supabase

# Option 2: If uploading from local machine
# On your local machine, run:
# rsync -avz -e "ssh" /path/to/n8n-suprabase-setup/ root@your-vps-ip:/opt/n8n-supabase/
```

### Create and configure .env file

```bash
cd /opt/n8n-supabase  # or wherever you placed the files

# Copy example env file
cp .env.example .env

# Generate a secure JWT secret
JWT_SECRET=$(openssl rand -base64 32)
echo $JWT_SECRET

# Edit .env file
nano .env
```

**Important: Update these values in .env:**

```env
# Use strong passwords!
POSTGRES_PASSWORD=YourStrongPassword123!

# Use your VPS IP or domain
DOMAIN_NAME=123.45.67.89
# Or if you have a domain:
# DOMAIN_NAME=yourdomain.com

# n8n credentials
N8N_USER=admin
N8N_PASSWORD=YourStrongN8nPassword123!

# Generate encryption key
N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)

# Use the JWT secret you generated
JWT_SECRET=paste-the-generated-jwt-secret-here

# Generate proper Supabase keys (see below)
ANON_KEY=your-generated-anon-key
SERVICE_ROLE_KEY=your-generated-service-role-key
```

### Generate Supabase API Keys

For production, generate proper JWT keys:

```bash
# Install jq if not available
apt install -q jq -y

# Generate keys using the JWT_SECRET from your .env
# Replace 'your-jwt-secret' with your actual JWT_SECRET
JWT_SECRET="your-jwt-secret"

# Generate ANON_KEY
echo '{
  "role": "anon",
  "iss": "supabase",
  "iat": 1641769200,
  "exp": 1957345200
}' | jq -c | openssl enc -base64 -A -K "$(echo -n $JWT_SECRET | xxd -p)" -iv 0

# Generate SERVICE_ROLE_KEY
echo '{
  "role": "service_role",
  "iss": "supabase",
  "iat": 1641769200,
  "exp": 1957345200
}' | jq -c | openssl enc -base64 -A -K "$(echo -n $JWT_SECRET | xxd -p)" -iv 0
```

Or use the online tool: https://supabase.com/docs/guides/self-hosting/docker#api-keys

### Make scripts executable

```bash
chmod +x setup.sh start-all.sh stop-all.sh backup.sh
```

### Run the setup

```bash
./setup.sh
```

## 🌐 Step 4: Access Your Services

After successful deployment, access your services:

- **n8n**: `http://YOUR_VPS_IP:5678`
- **Supabase Studio**: `http://YOUR_VPS_IP:3000`
- **Supabase API**: `http://YOUR_VPS_IP:8000`

Login to n8n with the credentials you set in `.env` (N8N_USER and N8N_PASSWORD).

## 🔐 Step 5: Setup SSL (Recommended for Production)

### Option 1: Using Nginx Reverse Proxy with Let's Encrypt

```bash
# Install Nginx and Certbot
apt install -y nginx certbot python3-certbot-nginx

# Create Nginx configuration for n8n
cat > /etc/nginx/sites-available/n8n << 'EOF'
server {
    listen 80;
    server_name n8n.yourdomain.com;

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Create Nginx configuration for Supabase
cat > /etc/nginx/sites-available/supabase << 'EOF'
server {
    listen 80;
    server_name supabase.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable sites
ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/supabase /etc/nginx/sites-enabled/

# Test Nginx configuration
nginx -t

# Reload Nginx
systemctl reload nginx

# Get SSL certificates (replace with your actual domains)
certbot --nginx -d n8n.yourdomain.com
certbot --nginx -d supabase.yourdomain.com
certbot --nginx -d api.yourdomain.com
```

### Option 2: Update firewall after SSL setup

```bash
# Remove direct port access if using reverse proxy
ufw delete allow 5678/tcp
ufw delete allow 3000/tcp
ufw delete allow 8000/tcp
```

## 📊 Step 6: Verify Installation

### Check all containers are running

```bash
docker ps
```

You should see containers:
- shared-postgres
- n8n
- supabase-kong
- supabase-auth
- supabase-rest
- supabase-realtime
- supabase-storage
- supabase-imgproxy
- supabase-meta
- supabase-studio

### Check logs

```bash
# n8n logs
docker logs n8n -f

# Supabase logs
docker logs supabase-studio -f

# PostgreSQL logs
docker logs shared-postgres -f
```

## 🔄 Step 7: Maintenance

### Start services

```bash
cd /opt/n8n-supabase
./start-all.sh
```

### Stop services

```bash
./stop-all.sh
```

### Backup data

```bash
./backup.sh
```

Backups will be stored in `./backups/` directory.

### Update services

```bash
# Pull latest images
docker-compose -f docker-compose.n8n.yml pull
docker-compose -f docker-compose.supabase.yml pull

# Restart services
./stop-all.sh
./start-all.sh
```

### View resource usage

```bash
docker stats
```

## 🔧 Troubleshooting

### Container won't start

```bash
# Check logs
docker logs container-name

# Check all containers
docker ps -a
```

### Port conflicts

```bash
# Check what's using a port
netstat -tulpn | grep :5678
# or
ss -tulpn | grep :5678
```

### Database connection issues

```bash
# Check if PostgreSQL is ready
docker exec shared-postgres pg_isready -U postgres

# Connect to PostgreSQL
docker exec -it shared-postgres psql -U postgres
```

### Reset everything (WARNING: deletes all data)

```bash
./stop-all.sh
docker system prune -a --volumes
rm -rf ./volumes/*
./setup.sh
```

## 🔒 Security Best Practices

1. **Change all default passwords** in `.env`
2. **Use SSL certificates** (Let's Encrypt is free)
3. **Keep firewall enabled** and only open necessary ports
4. **Regular backups** - run `./backup.sh` daily
5. **Update regularly** - keep Docker images up to date
6. **Monitor logs** - check for suspicious activity
7. **Use strong JWT secrets** - generate with `openssl rand -base64 32`
8. **Restrict PostgreSQL port** - don't expose 5432 publicly
9. **Enable 2FA** on your VPS provider
10. **Use SSH keys** instead of passwords

## 📈 Performance Optimization

### For VPS with 2GB RAM

```bash
# Edit docker-compose.postgres.yml to reduce memory usage
nano docker-compose.postgres.yml

# Change shared_buffers to 128MB
# Change max_connections to 100
```

### For VPS with 4GB+ RAM

Keep default settings or increase:
- shared_buffers=512MB
- max_connections=300

### Monitor and set resource limits

Add to your docker-compose files:

```yaml
deploy:
  resources:
    limits:
      cpus: '0.5'
      memory: 512M
```

## 🆘 Getting Help

- Check logs first: `docker logs container-name`
- Verify .env configuration
- Check firewall rules: `ufw status`
- Test network connectivity: `docker network inspect shared-network`
- Restart services: `./stop-all.sh && ./start-all.sh`

## 📝 Auto-start on Boot

To ensure services start automatically after VPS reboot:

```bash
# Create systemd service
cat > /etc/systemd/system/n8n-supabase.service << 'EOF'
[Unit]
Description=n8n and Supabase Docker Services
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/n8n-supabase
ExecStart=/opt/n8n-supabase/start-all.sh
ExecStop=/opt/n8n-supabase/stop-all.sh
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable service
systemctl enable n8n-supabase.service

# Test it
systemctl start n8n-supabase.service
systemctl status n8n-supabase.service
```

## ✅ Deployment Checklist

- [ ] VPS created with Ubuntu
- [ ] SSH access configured
- [ ] Docker and Docker Compose installed
- [ ] Firewall configured
- [ ] Code uploaded to VPS
- [ ] .env file created and configured
- [ ] Strong passwords set
- [ ] JWT secret generated
- [ ] Supabase API keys generated
- [ ] Setup script executed successfully
- [ ] All containers running
- [ ] Services accessible via browser
- [ ] SSL certificates installed (production)
- [ ] Backup script tested
- [ ] Auto-start service configured
- [ ] Monitoring set up
# PostgreSQL Configuration
POSTGRES_PASSWORD=changeme123

# Domain Configuration
DOMAIN_NAME=your-vps-ip-or-domain.com

# n8n Configuration
N8N_USER=admin
N8N_PASSWORD=changeme123
N8N_ENCRYPTION_KEY=

# JWT Secret (generate with: openssl rand -base64 32)
JWT_SECRET=your-jwt-secret-here

# Supabase API Keys (generate at: https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys)
# Or use these default development keys (CHANGE IN PRODUCTION!)
ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvY2FsaG9zdCIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNjQxNzY5MjAwLCJleHAiOjE5NTczNDUyMDB9.dc6hdXnl1_lfzxj7qF_xHlKDfmxN4rjfmC0UToQrPKg
SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvY2FsaG9zdCIsInJvbGUiOiJzZXJ2aWNlX3JvbGUiLCJpYXQiOjE2NDE3NjkyMDAsImV4cCI6MTk1NzM0NTIwMH0.rB0kN9gVGR5xPPKJXRHP8KWEfXP_T7sKZXO0LGqkfjo

