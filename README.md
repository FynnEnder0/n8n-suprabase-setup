# 🐳 Docker n8n + Supabase Setup

Complete Docker setup with n8n and Supabase sharing a PostgreSQL database via a common Docker network.

## 🏗️ Modular Architecture with Dual Deployment Options

This project supports **two deployment methods**:

### **Option 1: Unified Deployment (Hostinger Git/One-Command)**
```
docker-compose.yml    ← All services in one file (for Hostinger/quick deploy)
```
Use `docker-compose up -d` or deploy via Hostinger Git integration.

### **Option 2: Modular Deployment (SSH/Advanced)**
```
docker-compose.postgres.yml  ← PostgreSQL + shared network
docker-compose.n8n.yml       ← n8n workflow automation
docker-compose.supabase.yml  ← Supabase services
```
Use individual files with `./start-all.sh` for granular control.

**Why Both?**
- ✅ **Hostinger compatibility**: Single file works with Git deployment
- ✅ **Modularity**: Separate files for independent service management
- ✅ **Flexibility**: Choose the approach that fits your workflow
- ✅ **No duplication**: Both use the same configurations

## 🚀 Quick Start

### Method 1: Hostinger Git Deployment (Easiest)

1. **Create the network manually first:**
   ```bash
   ssh root@srv1097337.hstgr.cloud
   docker network create shared-network
   ```

2. **Deploy via Hostinger Panel:**
   - Connect to GitHub: `https://github.com/FynnEnder0/n8n-suprabase-setup.git`
   - Configure environment variables in panel
   - Click Deploy

3. **Initialize databases:**
   ```bash
   ssh root@srv1097337.hstgr.cloud
   cd /path/to/deployment
   ./post-deploy.sh
   ```

**📖 See [HOSTINGER_GIT_DEPLOY.md](HOSTINGER_GIT_DEPLOY.md) for detailed instructions**

### Method 2: SSH with Unified File

```bash
# SSH into VPS
ssh root@srv1097337.hstgr.cloud

# Clone or upload files
cd /opt/n8n-supabase

# Create network
docker network create shared-network

# Copy and configure environment
cp .env.example .env
nano .env

# Deploy all services at once
docker-compose up -d
```

### Method 3: SSH with Modular Files (Advanced)

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
```

### Method 4: Automated VPS Deployment

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

## 📦 What's Included

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

After setup:

- **n8n**: `https://your-domain:5678`
- **Supabase Studio**: `http://your-domain:3000`
- **Supabase API**: `http://your-domain:8000`

## 📋 Requirements

- Docker 20.10+
- Docker Compose 2.0+
- 2GB RAM minimum
- 10GB disk space

## 🔧 Management

### Using Unified File
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View status
docker-compose ps

# View logs
docker-compose logs -f n8n
docker-compose logs -f supabase-studio

# Restart a specific service
docker-compose restart n8n
```

### Using Modular Files
```bash
# Start all services (uses modular files)
./start-all.sh

# Stop all services
./stop-all.sh

# Or manage individually:
docker-compose -f docker-compose.postgres.yml up -d
docker-compose -f docker-compose.n8n.yml up -d
docker-compose -f docker-compose.supabase.yml up -d

# Restart just n8n
docker-compose -f docker-compose.n8n.yml restart

# Create backups
./backup.sh
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

## 📁 Project Structure

```
.
├── docker-compose.yml              # All services (for Hostinger/unified deployment)
├── docker-compose.postgres.yml     # PostgreSQL only (modular)
├── docker-compose.n8n.yml          # n8n only (modular)
├── docker-compose.supabase.yml     # Supabase services (modular)
├── .env                            # Environment configuration
├── setup.sh                        # Automated modular setup
├── start-all.sh                    # Start all modular services
├── stop-all.sh                     # Stop all services
├── deploy-to-vps.sh               # Full VPS deployment automation
├── pre-deploy.sh                   # Pre-deployment hook
├── post-deploy.sh                  # Post-deployment hook (DB init)
└── setup-ssl.sh                    # SSL/HTTPS setup
```

## 🔄 Which Method Should I Use?

| Deployment Method | Use Case | Pros | Cons |
|------------------|----------|------|------|
| **Hostinger Git** | Automated CI/CD | Auto-deploy on git push | Less granular control |
| **Unified SSH** | Quick VPS setup | Simple, one command | All-or-nothing |
| **Modular SSH** | Production, development | Granular control, restart individual services | More commands |
| **deploy-to-vps.sh** | First-time setup | Installs everything | One-time use |

## 💡 Tips

- **Development**: Use modular files for flexibility
- **Production on Hostinger**: Use Git deployment with unified file
- **Production on other VPS**: Use `deploy-to-vps.sh` then modular files
- **CI/CD**: Hostinger Git deployment with webhooks

## 📝 License

MIT License - see LICENSE file

## 🤝 Contributing

Contributions welcome! Please open an issue or PR.
