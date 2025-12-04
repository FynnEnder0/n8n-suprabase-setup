# 🐳 Docker n8n + Supabase Setup with Traefik

Complete Docker setup with n8n and Supabase sharing a PostgreSQL database via a common Docker network, with Traefik as an automatic reverse proxy with SSL.

## 🏗️ Modular Architecture

This project uses a **modular Docker Compose architecture** for maximum flexibility:

```
docker-compose.yml              ← Main orchestrator (includes all modules)
├── docker-compose.postgres.yml  ← PostgreSQL + shared network
├── docker-compose.n8n.yml       ← n8n workflow automation
├── docker-compose.supabase.yml  ← Supabase services
└── docker-compose.traefik.yml   ← Traefik reverse proxy (automatic SSL)
```

**Why Modular?**
- ✅ Start/stop services independently
- ✅ Easy to add new services
- ✅ Clear separation of concerns
- ✅ Simplified maintenance
- ✅ Automatic SSL with Traefik

**How It Works:**
- All services communicate via `shared-network` (created by postgres compose)
- Traefik provides automatic HTTPS with Let's Encrypt
- Main `docker-compose.yml` uses Docker Compose's `include` directive
- Each module can be managed individually or as a whole

## 🚀 Quick Start

### Option 1: Local Development

```bash
# Clone the repository
git clone https://github.com/yourusername/docker-n8n-supabase.git
cd docker-n8n-supabase

# Copy environment file
cp .env.example .env

# Edit .env with your passwords
nano .env

# Run setup (starts all modules together)
chmod +x setup.sh
./setup.sh
```

**Or start modules individually:**
```bash
# Create network first
docker network create shared-network

# Start only what you need
docker-compose -f docker-compose.postgres.yml up -d
docker-compose -f docker-compose.n8n.yml up -d
docker-compose -f docker-compose.supabase.yml up -d

# Or use the main orchestrator
docker-compose up -d
```

### Option 2: Deploy to Hostinger VPS (or any Ubuntu VPS)

```bash
# On your local machine, upload files to VPS
rsync -avz -e "ssh" ./ root@your-vps-ip:/opt/n8n-supabase/

# SSH into your VPS
ssh root@your-vps-ip

# Navigate to the directory
cd /opt/n8n-supabase

# Run the VPS deployment script (installs Docker, configures firewall, etc.)
chmod +x deploy-to-vps.sh
sudo ./deploy-to-vps.sh
```

**📖 For detailed VPS deployment instructions, see [HOSTINGER_GIT_DEPLOY.md](HOSTINGER_GIT_DEPLOY.md)**

## 📦 What's Included

- **Traefik**: Reverse proxy with automatic SSL (Let's Encrypt)
- **n8n**: Workflow automation tool
- **Supabase**: Complete backend-as-a-service
  - Kong API Gateway
  - GoTrue Authentication
  - PostgREST API
  - Realtime subscriptions
  - Storage with image transformations
  - Studio UI
- **PostgreSQL**: Shared database for all services

## 🌐 Access URLs

After setup with DNS configured:

- **n8n**: `https://n8n.your-domain.com` (automatic SSL)
- **Supabase Studio**: `https://supabase.your-domain.com` (automatic SSL)
- **Supabase API**: `https://api.your-domain.com` (automatic SSL)
- **Traefik Dashboard**: `http://your-domain:8080`

**📖 See [TRAEFIK_GUIDE.md](TRAEFIK_GUIDE.md) for detailed Traefik configuration and troubleshooting**

## 📋 Requirements

- Docker 20.10+
- Docker Compose 2.0+
- 2GB RAM minimum
- 10GB disk space

## 🔧 Management Scripts

```bash
# Start all services (uses all compose files)
./start-all.sh

# Stop all services
./stop-all.sh

# Or manage individually:
docker-compose -f docker-compose.postgres.yml up -d
docker-compose -f docker-compose.n8n.yml up -d
docker-compose -f docker-compose.supabase.yml up -d

# Or use the main orchestrator:
docker-compose up -d        # Start all
docker-compose down         # Stop all
docker-compose ps           # Check status

# Create backups
./backup.sh

# View logs
docker-compose logs -f n8n
docker-compose logs -f supabase-studio
```

## 🔒 Security

Before production use:

1. Change all passwords in `.env`
2. Generate new JWT secret: `openssl rand -base64 32`
3. Generate Supabase API keys: [Supabase Docs](https://supabase.com/docs/guides/hosting/docker#generate-api-keys)
4. Setup SSL certificates
5. Configure firewall rules

## 📚 Documentation

- [n8n Documentation](https://docs.n8n.io/)
- [Supabase Documentation](https://supabase.com/docs)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 🐛 Troubleshooting

### Container won't start

```bash
docker logs container-name
docker ps -a
```

### Database connection issues

```bash
docker exec shared-postgres pg_isready -U postgres
```

### Port conflicts

```bash
sudo netstat -tulpn | grep :5678
```

## 🔄 Adding More Services

Thanks to the modular design, adding new services is easy:

1. Create a new compose file: `docker-compose.yourservice.yml`

```yaml
services:
  yourservice:
    image: your-image
    container_name: your-service
    restart: unless-stopped
    environment:
      DB_HOST: shared-postgres
      DB_PORT: 5432
      DB_NAME: yourdb
      DB_USER: postgres
      DB_PASSWORD: ${POSTGRES_PASSWORD}
    networks:
      - shared-network

networks:
  shared-network:
    external: true
    name: shared-network
```

2. Add to main orchestrator:

```yaml
# docker-compose.yml
include:
  - docker-compose.postgres.yml
  - docker-compose.n8n.yml
  - docker-compose.supabase.yml
  - docker-compose.yourservice.yml  # Add your new service
```

3. Start it:
```bash
docker-compose up -d
# Or individually:
docker-compose -f docker-compose.yourservice.yml up -d
```

## 📝 License

MIT License - see LICENSE file

## 🤝 Contributing

Contributions welcome! Please open an issue or PR.
