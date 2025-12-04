# 🚀 Hostinger Git Deployment Guide

Guide for deploying from GitHub to Hostinger VPS using their Docker/Git integration.

## 📋 Prerequisites

1. Your GitHub repository: `https://github.com/FynnEnder0/n8n-suprabase-setup.git`
2. Hostinger VPS with Docker support
3. DNS configured (if using SSL)

## 🏗️ Modular Architecture

This setup uses a **modular approach** with separate Docker Compose files:

- **`docker-compose.yml`** - Main orchestrator (uses `include` directive)
- **`docker-compose.postgres.yml`** - PostgreSQL database (creates shared network)
- **`docker-compose.n8n.yml`** - n8n workflow automation
- **`docker-compose.supabase.yml`** - All Supabase services

All services communicate via the `shared-network` Docker network. This keeps each application isolated and independently manageable while allowing communication.

### Benefits of This Approach:
✅ Each application can be started/stopped independently
✅ Easy to add new services (just create a new compose file)
✅ Clear separation of concerns
✅ Works with Hostinger's Git deployment (via include directive)
✅ Maintains modularity without sacrificing functionality

## 📊 Monitoring & Maintenance

Regularly check logs and performance:

```bash
# Container stats
docker stats

# System resources
htop
df -h
```

## 🔐 Security Notes

1. **Never commit sensitive data**:
   - The `.env` file in the repo should only have placeholders
   - Real values should be in Hostinger's panel

2. **Update default keys**:
   - Change `ANON_KEY` and `SERVICE_ROLE_KEY` for production
   - Generate proper JWT tokens

3. **Firewall**:
   - Configure in Hostinger panel or via SSH
   - Only open necessary ports

4. **Regular Updates**:
   - Update Docker images regularly
   - Monitor security advisories

## 📚 Additional Resources

- [Hostinger VPS Docker Guide](https://www.hostinger.com/tutorials/vps/docker)
- [n8n Documentation](https://docs.n8n.io/)
- [Supabase Self-Hosting](https://supabase.com/docs/guides/hosting/docker)

## ✅ Deployment Checklist

- [ ] Repository pushed to GitHub
- [ ] `docker-compose.yml` in repository root
- [ ] Environment variables configured in Hostinger panel
- [ ] Secure passwords generated
- [ ] Application deployed via Hostinger
- [ ] Databases created
- [ ] Services accessible
- [ ] DNS configured (if using SSL)
- [ ] SSL certificates obtained (if using HTTPS)
- [ ] Backups configured

## 🆘 Getting Help

If you encounter issues:

1. Check Hostinger application logs in the panel
2. SSH into VPS and check Docker logs
3. Verify environment variables are set correctly
4. Check GitHub repository structure
5. Contact Hostinger support for platform-specific issues
