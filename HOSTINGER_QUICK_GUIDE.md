# 🚀 Quick Deployment Guide for srv1097337.hstgr.cloud

This is your customized deployment guide for Hostinger VPS.

## 📋 Your Configuration

- **VPS Domain**: srv1097337.hstgr.cloud
- **n8n Subdomain**: n8n.srv1097337.hstgr.cloud
- **Timezone**: Europe/Berlin
- **SSL Email**: user@srv1097337.hstgr.cloud

## 🔧 Step 1: DNS Configuration (Do This First!)

In your Hostinger DNS management panel, add these A records:

```
Type: A    Host: n8n         Points to: YOUR_VPS_IP    TTL: 3600
Type: A    Host: supabase    Points to: YOUR_VPS_IP    TTL: 3600
Type: A    Host: api         Points to: YOUR_VPS_IP    TTL: 3600
```

To find your VPS IP:
```bash
ssh root@srv1097337.hstgr.cloud
curl ifconfig.me
```

**⏰ Wait 5-10 minutes for DNS propagation before continuing!**

Test DNS propagation:
```bash
nslookup n8n.srv1097337.hstgr.cloud
nslookup supabase.srv1097337.hstgr.cloud
nslookup api.srv1097337.hstgr.cloud
```

## 🚀 Step 2: Upload Files to VPS

From your local machine:

```bash
# Navigate to your project directory
cd /Users/fynn-lauridsender/WebstormProjects/n8n-suprabase-setup

# Upload to VPS
rsync -avz -e "ssh" --exclude 'volumes/' --exclude '.git/' ./ root@srv1097337.hstgr.cloud:/opt/n8n-supabase/
```

## 🔨 Step 3: Deploy on VPS

SSH into your VPS and run the automated deployment:

```bash
# Connect to VPS
ssh root@srv1097337.hstgr.cloud

# Navigate to directory
cd /opt/n8n-supabase

# Make scripts executable
chmod +x *.sh

# Run deployment (installs Docker, configures everything)
sudo ./deploy-to-vps.sh
```

This will:
- ✅ Install Docker & Docker Compose
- ✅ Configure firewall
- ✅ Generate secure passwords
- ✅ Start all services
- ✅ Create databases

**IMPORTANT**: Save the credentials displayed at the end!

## 🌐 Step 4: Initial Access (HTTP)

After deployment completes, access your services:

- **n8n**: http://srv1097337.hstgr.cloud:5678
- **Supabase Studio**: http://srv1097337.hstgr.cloud:3000
- **Supabase API**: http://srv1097337.hstgr.cloud:8000

Login to n8n with:
- Username: `admin`
- Password: (shown during deployment, also in `.env` file)

## 🔒 Step 5: Enable HTTPS (Recommended)

After DNS is fully propagated:

```bash
cd /opt/n8n-supabase
sudo ./setup-ssl.sh
```

This will:
- ✅ Install Nginx reverse proxy
- ✅ Obtain Let's Encrypt SSL certificates
- ✅ Configure HTTPS for all services
- ✅ Auto-renew certificates

After SSL setup, access via:
- **n8n**: https://n8n.srv1097337.hstgr.cloud
- **Supabase Studio**: https://supabase.srv1097337.hstgr.cloud
- **Supabase API**: https://api.srv1097337.hstgr.cloud

## 📊 Management Commands

```bash
# Start all services
./start-all.sh

# Stop all services
./stop-all.sh

# Backup data
./backup.sh

# View logs
docker logs n8n -f
docker logs supabase-studio -f

# Check status
docker ps

# Restart everything
./stop-all.sh && ./start-all.sh
```

## 🔧 Configuration Files

Your configuration is in `.env`:

```bash
# View current configuration
cat .env

# Edit configuration
nano .env

# After editing, restart services
./stop-all.sh && ./start-all.sh
```

## 🔥 Firewall Status

Check which ports are open:
```bash
sudo ufw status
```

Current configuration:
- Port 22 (SSH)
- Port 80 (HTTP)
- Port 443 (HTTPS)
- Port 5678 (n8n direct)
- Port 3000 (Supabase Studio direct)
- Port 8000 (Supabase API direct)

## 🐛 Troubleshooting

### Services won't start
```bash
docker logs container-name
docker ps -a
```

### Can't access via domain
```bash
# Check DNS
nslookup n8n.srv1097337.hstgr.cloud

# Check Nginx
sudo systemctl status nginx
sudo nginx -t

# Check firewall
sudo ufw status
```

### Database issues
```bash
# Check PostgreSQL
docker exec shared-postgres pg_isready -U postgres

# Connect to database
docker exec -it shared-postgres psql -U postgres
```

### Reset everything
```bash
cd /opt/n8n-supabase
./stop-all.sh
docker system prune -a --volumes
rm -rf volumes/*
./deploy-to-vps.sh
```

## 📁 File Locations

- **Application**: `/opt/n8n-supabase/`
- **Data volumes**: `/opt/n8n-supabase/volumes/`
- **Backups**: `/opt/n8n-supabase/backups/`
- **Nginx configs**: `/etc/nginx/sites-available/`
- **SSL certificates**: `/etc/letsencrypt/live/`

## 🔐 Security Checklist

- ✅ Strong passwords generated automatically
- ✅ Firewall configured
- ✅ SSL/HTTPS enabled
- ✅ Basic authentication on n8n
- ✅ Regular backups scheduled
- ⚠️ Consider: Change SSH port from 22
- ⚠️ Consider: Setup fail2ban for SSH protection
- ⚠️ Consider: Enable 2FA on Hostinger account

## 📈 Monitoring

### Check resource usage
```bash
# Overall system
htop

# Docker containers
docker stats

# Disk usage
df -h
```

### View logs
```bash
# All containers
docker-compose -f docker-compose.n8n.yml logs -f
docker-compose -f docker-compose.supabase.yml logs -f

# Specific container
docker logs n8n --tail 100 -f
```

## 🔄 Updates

```bash
cd /opt/n8n-supabase

# Pull latest images
docker-compose -f docker-compose.n8n.yml pull
docker-compose -f docker-compose.supabase.yml pull
docker-compose -f docker-compose.postgres.yml pull

# Restart with new images
./stop-all.sh
./start-all.sh
```

## 💾 Backups

Automated backup script:
```bash
# Run manual backup
./backup.sh

# Backups are stored in: ./backups/
```

Setup automatic daily backups:
```bash
# Add to crontab
crontab -e

# Add this line (runs daily at 2 AM)
0 2 * * * cd /opt/n8n-supabase && ./backup.sh
```

## 📞 Support

- n8n Documentation: https://docs.n8n.io/
- Supabase Documentation: https://supabase.com/docs
- Hostinger Support: https://www.hostinger.com/tutorials/

## ✅ Quick Reference

| Service | HTTP URL | HTTPS URL (after SSL) |
|---------|----------|----------------------|
| n8n | http://srv1097337.hstgr.cloud:5678 | https://n8n.srv1097337.hstgr.cloud |
| Supabase Studio | http://srv1097337.hstgr.cloud:3000 | https://supabase.srv1097337.hstgr.cloud |
| Supabase API | http://srv1097337.hstgr.cloud:8000 | https://api.srv1097337.hstgr.cloud |

**Default credentials**: Check `.env` file for auto-generated passwords

