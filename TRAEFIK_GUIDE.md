# 🔀 Traefik Reverse Proxy Integration

This project now includes Traefik as an automatic reverse proxy with Let's Encrypt SSL certificates.

## 🎯 What Traefik Does

- **Automatic SSL/TLS**: Let's Encrypt certificates for all services
- **Automatic routing**: Services are accessible via subdomains
- **HTTP to HTTPS redirect**: Automatic upgrade to secure connections
- **Dashboard**: Monitor all routes and services
- **No manual Nginx configuration needed**

## 🌐 Service URLs

After deployment with proper DNS configuration:

- **n8n**: `https://n8n.srv1097337.hstgr.cloud`
- **Supabase Studio**: `https://supabase.srv1097337.hstgr.cloud`
- **Supabase API**: `https://api.srv1097337.hstgr.cloud`
- **Traefik Dashboard**: `http://srv1097337.hstgr.cloud:8080`

## 📋 DNS Configuration Required

In your Hostinger DNS panel, add these A records:

```
Type: A    Host: n8n         Points to: YOUR_VPS_IP
Type: A    Host: supabase    Points to: YOUR_VPS_IP
Type: A    Host: api         Points to: YOUR_VPS_IP
Type: A    Host: traefik     Points to: YOUR_VPS_IP (optional, for dashboard)
```

## 🔧 How It Works

### Service Discovery
Traefik automatically discovers services through Docker labels:

**Example from n8n:**
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.n8n.rule=Host(`n8n.${DOMAIN_NAME}`)"
  - "traefik.http.routers.n8n.entrypoints=websecure"
  - "traefik.http.routers.n8n.tls.certresolver=letsencrypt"
```

### Automatic SSL
- Traefik requests certificates from Let's Encrypt automatically
- Certificates are stored in `./volumes/traefik/letsencrypt/acme.json`
- Auto-renewal happens before expiration

### No Port Exposure Needed
Services only need to expose ports internally:
```yaml
expose:
  - "5678"  # Internal only, Traefik handles external access
```

## 🚀 Deployment

### Standard Deployment
```bash
./setup.sh
```

This will:
1. Start Traefik first
2. Start all services
3. Traefik automatically detects services via labels
4. Request SSL certificates from Let's Encrypt
5. Route traffic to the correct service

### Manual Start
```bash
# Start Traefik first
docker-compose -f docker-compose.traefik.yml up -d

# Then start other services
docker-compose -f docker-compose.postgres.yml up -d
docker-compose -f docker-compose.n8n.yml up -d
docker-compose -f docker-compose.supabase.yml up -d
```

### Or Use Orchestrator
```bash
docker-compose up -d
```

## 🔒 Security Features

### HTTPS Enforcement
All HTTP traffic is automatically redirected to HTTPS.

### Dashboard Protection (Optional)
To password-protect the Traefik dashboard, generate a password hash:

```bash
# Install htpasswd (if not available)
apt install apache2-utils

# Generate password hash
echo $(htpasswd -nb admin yourpassword) | sed -e s/\\$/\\$\\$/g
```

Then uncomment and update in `docker-compose.traefik.yml`:
```yaml
labels:
  - "traefik.http.routers.traefik-dashboard.middlewares=dashboard-auth"
  - "traefik.http.middlewares.dashboard-auth.basicauth.users=admin:$$apr1$$..."
```

## 📊 Monitoring

### Traefik Dashboard
Access the dashboard at: `http://your-domain:8080`

Features:
- View all active routers and services
- Check SSL certificate status
- Monitor request metrics
- Debug routing issues

### Check Certificates
```bash
# View certificate info
docker exec traefik cat /letsencrypt/acme.json | jq

# Check certificate expiration
openssl s_client -connect n8n.srv1097337.hstgr.cloud:443 -servername n8n.srv1097337.hstgr.cloud 2>/dev/null | openssl x509 -noout -dates
```

## 🐛 Troubleshooting

### SSL Certificate Not Issued

**Check logs:**
```bash
docker logs traefik -f
```

**Common issues:**
- DNS not propagated yet (wait 5-10 minutes)
- Port 80 not accessible (Let's Encrypt uses HTTP challenge)
- Domain doesn't point to your server

**Force certificate renewal:**
```bash
docker-compose -f docker-compose.traefik.yml down
rm volumes/traefik/letsencrypt/acme.json
touch volumes/traefik/letsencrypt/acme.json
chmod 600 volumes/traefik/letsencrypt/acme.json
docker-compose -f docker-compose.traefik.yml up -d
```

### Service Not Accessible

**Check if Traefik sees the service:**
```bash
# Check Traefik logs
docker logs traefik | grep n8n

# Check container labels
docker inspect n8n | grep -A 10 Labels
```

**Verify routing:**
- Open Traefik dashboard: `http://your-domain:8080`
- Check "HTTP Routers" section
- Ensure service is listed with correct rule

### Connection Refused

**Check network connectivity:**
```bash
# Verify all services are on shared-network
docker network inspect shared-network

# Test internal connectivity
docker exec traefik ping n8n
```

## 🔄 Adding New Services

To add a new service with automatic SSL:

1. Add to your service definition:
```yaml
services:
  myservice:
    image: myimage:latest
    expose:
      - "8080"
    networks:
      - shared-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`myservice.${DOMAIN_NAME}`)"
      - "traefik.http.routers.myservice.entrypoints=websecure"
      - "traefik.http.routers.myservice.tls.certresolver=letsencrypt"
      - "traefik.http.services.myservice.loadbalancer.server.port=8080"
```

2. Add DNS record for `myservice.your-domain.com`

3. Start service:
```bash
docker-compose -f docker-compose.myservice.yml up -d
```

Traefik will automatically:
- Detect the new service
- Request SSL certificate
- Start routing traffic

## 📁 File Structure

```
volumes/
  traefik/
    letsencrypt/
      acme.json          # SSL certificates (auto-managed)
    logs/               # Access logs
```

## 🔧 Configuration Options

### Custom SSL Email
Set in `.env`:
```env
SSL_EMAIL=your-email@example.com
```

### Staging Certificates (Testing)
To test without hitting Let's Encrypt rate limits, use staging:

```yaml
# In docker-compose.traefik.yml
- "--certificatesresolvers.letsencrypt.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
```

### Custom Middleware
Add rate limiting, compression, or other features:

```yaml
labels:
  # Rate limiting
  - "traefik.http.middlewares.ratelimit.ratelimit.average=100"
  - "traefik.http.middlewares.ratelimit.ratelimit.burst=50"
  - "traefik.http.routers.n8n.middlewares=ratelimit"
  
  # Compression
  - "traefik.http.middlewares.compress.compress=true"
  - "traefik.http.routers.n8n.middlewares=compress"
```

## ✅ Benefits Over Manual Nginx Setup

| Feature | Traefik | Manual Nginx |
|---------|---------|--------------|
| Automatic SSL | ✅ Yes | ❌ Manual certbot |
| Service Discovery | ✅ Automatic | ❌ Manual config |
| Auto-renewal | ✅ Yes | ⚠️ Cron job needed |
| Dashboard | ✅ Built-in | ❌ None |
| Docker Integration | ✅ Native | ⚠️ Manual setup |
| Zero-downtime updates | ✅ Yes | ⚠️ Requires reload |

## 🚀 Migration from Nginx

If you previously used the `setup-ssl.sh` script with Nginx:

1. Stop Nginx:
```bash
systemctl stop nginx
systemctl disable nginx
```

2. Remove Nginx configurations:
```bash
rm /etc/nginx/sites-enabled/n8n
rm /etc/nginx/sites-enabled/supabase
```

3. Deploy with Traefik:
```bash
./setup.sh
```

Traefik will automatically handle everything Nginx did, plus automatic SSL management.

## 📞 Support

- **Traefik Docs**: https://doc.traefik.io/traefik/
- **Let's Encrypt**: https://letsencrypt.org/docs/
- **Rate Limits**: https://letsencrypt.org/docs/rate-limits/

