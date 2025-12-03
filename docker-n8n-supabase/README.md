# 🐳 Docker n8n + Supabase Setup

Complete Docker setup with n8n and Supabase sharing a PostgreSQL database via a common Docker network.

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/docker-n8n-supabase.git
cd docker-n8n-supabase

# Copy environment file
cp .env.example .env

# Edit .env with your passwords
nano .env

# Run setup
chmod +x setup.sh
./setup.sh
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

## 🔧 Management Scripts

```bash
# Start all services
./start-all.sh

# Stop all services
./stop-all.sh

# Create backups
./backup.sh

# View logs
docker-compose -f docker-compose.n8n.yml logs -f
docker-compose -f docker-compose.supabase.yml logs -f
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

Create a new `docker-compose.yourservice.yml`:

```yaml
services:
  yourservice:
    image: your-image
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
```

## 📝 License

MIT License - see LICENSE file

## 🤝 Contributing

Contributions welcome! Please open an issue or PR.
