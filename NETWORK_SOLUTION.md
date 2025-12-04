# 🚀 Hostinger Deployment - Network Conflict Solution

## Problem
When deploying via Hostinger's Docker/Git integration, you may encounter:
```
networks.shared-network conflicts with imported resource
```

This happens because the network is defined in multiple compose files or already exists.

## Solution

All compose files now reference the network as **external**, meaning it must exist before deployment.

### Option 1: Manual Network Creation (Recommended for Hostinger)

Before deploying via Hostinger panel, create the network manually:

```bash
# SSH into your VPS
ssh root@srv1097337.hstgr.cloud

# Create the network
docker network create shared-network

# Verify it exists
docker network ls | grep shared-network
```

Now deploy via Hostinger panel - it should work!

### Option 2: Use Pre-Deployment Hook

If Hostinger supports pre-deployment hooks, use the provided script:

1. The `pre-deploy.sh` script creates the network before deployment
2. Configure in Hostinger panel to run before docker-compose

### Option 3: Deploy via SSH (Automated)

Use the automated deployment script which handles everything:

```bash
# From your local machine
rsync -avz -e "ssh" ./ root@srv1097337.hstgr.cloud:/opt/n8n-supabase/

# SSH into VPS
ssh root@srv1097337.hstgr.cloud

# Run automated deployment
cd /opt/n8n-supabase
sudo ./deploy-to-vps.sh
```

This script:
- ✅ Creates the network
- ✅ Installs Docker if needed
- ✅ Configures firewall
- ✅ Generates secure passwords
- ✅ Starts all services

## Understanding the Network Configuration

```yaml
# All compose files now use:
networks:
  shared-network:
    external: true
    name: shared-network
```

This means:
- The network **must exist** before running docker-compose
- The network is **managed externally** (manually or by script)
- Multiple compose files can safely reference the same network
- No conflicts when using docker-compose's include directive

## Post-Deployment

After successful deployment, initialize databases:

```bash
# Run the post-deployment script
./post-deploy.sh

# Or manually:
docker exec shared-postgres psql -U postgres -c "CREATE DATABASE n8n;"
docker exec shared-postgres psql -U postgres -c "CREATE DATABASE supabase;"
docker exec shared-postgres psql -U postgres -d supabase -c "CREATE SCHEMA IF NOT EXISTS auth;"
docker exec shared-postgres psql -U postgres -d supabase -c "CREATE SCHEMA IF NOT EXISTS storage;"
docker exec shared-postgres psql -U postgres -d supabase -c "CREATE SCHEMA IF NOT EXISTS realtime;"
```

## Troubleshooting

### Network already exists but deployment still fails

```bash
# Remove and recreate the network
docker network rm shared-network
docker network create shared-network
```

### Check network status

```bash
# List networks
docker network ls

# Inspect network
docker network inspect shared-network

# See which containers are using it
docker network inspect shared-network | grep -A 10 Containers
```

### Clean slate (removes all containers and networks)

```bash
# Stop everything
docker-compose down

# Remove all containers
docker ps -aq | xargs docker rm -f

# Remove network
docker network rm shared-network

# Recreate network
docker network create shared-network

# Redeploy
docker-compose up -d
```

## Files Created

- ✅ `pre-deploy.sh` - Creates network before deployment
- ✅ `post-deploy.sh` - Initializes databases after deployment
- ✅ Updated all compose files to use external network

## Recommended Workflow

1. **First time setup:**
   ```bash
   ssh root@srv1097337.hstgr.cloud
   docker network create shared-network
   ```

2. **Deploy via Hostinger panel:**
   - Connect GitHub repository
   - Deploy (network already exists)

3. **Initialize databases:**
   ```bash
   ssh root@srv1097337.hstgr.cloud
   cd /path/to/deployment
   ./post-deploy.sh
   ```

4. **Access your services:**
   - n8n: `http://srv1097337.hstgr.cloud:5678`
   - Supabase: `http://srv1097337.hstgr.cloud:3000`

## Summary

The network conflict is now resolved by:
1. Making the network external in all compose files
2. Creating the network before deployment (manually or via script)
3. Providing pre/post deployment hooks for automation

Choose the deployment method that works best with Hostinger's platform!

