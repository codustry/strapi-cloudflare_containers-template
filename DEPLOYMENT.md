# Deploying Strapi V5 to Cloudflare Containers

Complete step-by-step guide to deploy your Strapi application to Cloudflare Containers with a custom subdomain.

## Prerequisites

- [x] Node.js 22+ installed
- [x] Docker installed and running
- [x] Cloudflare account
- [x] A domain managed by Cloudflare DNS
- [x] Wrangler CLI installed: `npm install -g wrangler`

## Step 1: Create Your Strapi Project

First, create a new Strapi V5 project:

```bash
# Create new Strapi project
npx create-strapi@latest my-strapi-app

# Follow the prompts:
# - Choose "Custom (manual settings)"
# - Choose "SQLite" for now (we'll change this for production)
# - Skip TypeScript unless you want it

cd my-strapi-app
```

## Step 2: Copy Template Files

Clone and copy the template files into your Strapi project:

```bash
# From your Strapi project directory
cd my-strapi-app

# Clone the template (or download files manually)
git clone https://github.com/codustry/strapi-cloudflare_containers-template.git /tmp/strapi-template

# Copy template files
cp /tmp/strapi-template/Dockerfile .
cp /tmp/strapi-template/docker-compose.yml .
cp /tmp/strapi-template/wrangler.toml .
cp /tmp/strapi-template/.dockerignore .
cp /tmp/strapi-template/.env.production.example .env.production
cp -r /tmp/strapi-template/scripts .

# Clean up
rm -rf /tmp/strapi-template
```

## Step 3: Choose Your Database Strategy

Cloudflare Containers has specific database requirements. Choose one:

### Option A: Cloudflare D1 (SQLite) - Recommended

Best for small to medium applications with serverless architecture.

**1. Update your Strapi database config:**

Edit `config/database.ts` (or `config/database.js`):

```typescript
import path from 'path';

export default ({ env }) => ({
  connection: {
    client: 'better-sqlite3',
    connection: {
      filename: env('DATABASE_FILENAME', path.join(__dirname, '..', '..', '.tmp/data.db')),
    },
    useNullAsDefault: true,
    debug: env.bool('LOG_QUERIES', false),
  },
});
```

**2. Install SQLite dependency:**

```bash
npm install better-sqlite3
```

**3. Update `wrangler.toml`:**

```toml
# ... existing config ...

[vars]
DATABASE_CLIENT = "better-sqlite3"
DATABASE_FILENAME = "/data/production.db"
```

### Option B: External PostgreSQL Database

Best for larger applications or if you need advanced database features.

**Recommended providers:**
- [Neon](https://neon.tech) - Serverless PostgreSQL
- [Supabase](https://supabase.com) - Full PostgreSQL with extras
- [Railway](https://railway.app) - Simple PostgreSQL hosting

**1. Set up database with your chosen provider**

**2. Keep your existing `config/database.ts` (PostgreSQL config)**

**3. Note your connection details for later**

## Step 4: Configure Environment Variables

### Local Environment

```bash
# Copy example
cp .env.production.example .env.production

# Edit .env.production
nano .env.production
```

Update these critical values:

```env
# Your Cloudflare subdomain
PUBLIC_URL=https://api.yourdomain.com

# Database (if using external PostgreSQL)
DATABASE_CLIENT=postgres
DATABASE_HOST=your-db-host.region.provider.com
DATABASE_PORT=5432
DATABASE_NAME=strapi_prod
DATABASE_USERNAME=strapi_user
DATABASE_PASSWORD=your_secure_password
DATABASE_SSL=true

# Cloudflare
CF_ACCOUNT_ID=your_cloudflare_account_id
CF_ZONE_ID=your_zone_id

# CORS - Add your frontend domains
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

### Generate Secrets

```bash
./scripts/generate-secrets.sh
```

Copy the generated secrets to your `.env.production` file.

## Step 5: Update wrangler.toml

Edit `wrangler.toml` to configure your deployment:

```toml
name = "strapi-api"  # Change to your preferred worker name
main = "src/index.js"
compatibility_date = "2024-01-01"

# Container Configuration
[durable_objects]
bindings = [
  { name = "STRAPI_CONTAINER", class_name = "StrapiContainer" }
]

[[durable_objects.bindings]]
name = "STRAPI_CONTAINER"
class_name = "StrapiContainer"

[container]
image = "."
max_instances = 10

[[migrations]]
tag = "v1"
new_sqlite_classes = ["StrapiContainer"]

# Public environment variables
[vars]
NODE_ENV = "production"
HOST = "0.0.0.0"
PORT = "1337"
PUBLIC_URL = "https://api.yourdomain.com"  # UPDATE THIS
DATABASE_CLIENT = "better-sqlite3"  # Or "postgres"

# Optional: R2 for file uploads
# [[r2_buckets]]
# binding = "STRAPI_UPLOADS"
# bucket_name = "strapi-uploads"
```

## Step 6: Set Cloudflare Secrets

Secrets should NEVER be in `wrangler.toml` or committed to git. Set them using Wrangler:

```bash
# Authenticate with Cloudflare
wrangler login

# Set all secrets
wrangler secret put JWT_SECRET
# Paste your generated secret when prompted

wrangler secret put ADMIN_JWT_SECRET
wrangler secret put API_TOKEN_SALT
wrangler secret put TRANSFER_TOKEN_SALT
wrangler secret put APP_KEYS

# If using external database
wrangler secret put DATABASE_PASSWORD

# If using email service
wrangler secret put SENDGRID_API_KEY

# If using Cloudflare API
wrangler secret put CF_API_TOKEN
```

## Step 7: Configure Cloudflare DNS (Subdomain)

Before deploying, set up your subdomain DNS:

### Option 1: Manual DNS Configuration

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Select your domain
3. Go to **DNS** → **Records**
4. Add a **CNAME** record:
   - **Type:** CNAME
   - **Name:** api (or your preferred subdomain)
   - **Target:** Your worker URL (will be provided after first deploy)
   - **Proxy status:** Proxied (orange cloud)

### Option 2: Use Cloudflare Workers Custom Domain

After deployment, you can bind a custom domain:

```bash
# After first deployment
wrangler deployments view

# Add custom domain
wrangler domains add api.yourdomain.com
```

## Step 8: Test Build Locally

Before deploying, test your Docker build:

```bash
# Build the image
docker build -t strapi-test .

# Run locally to test
docker run -p 1337:1337 --env-file .env.production strapi-test

# Test in browser
open http://localhost:1337/admin
```

If everything works, stop the container (Ctrl+C).

## Step 9: Deploy to Cloudflare

### First Deployment

```bash
# Make sure Docker is running
docker info

# Deploy to Cloudflare
wrangler deploy

# This will:
# 1. Build your Docker image
# 2. Push to Cloudflare Container Registry
# 3. Deploy your Worker
# 4. Configure Durable Objects
```

**Important:** After first deployment, wait 5-10 minutes for the container to be ready.

### Monitor Deployment

```bash
# Check deployment status
wrangler deployments list

# View container status
wrangler containers list

# View logs (in real-time)
wrangler tail
```

## Step 10: Configure Custom Domain

After deployment completes:

```bash
# Get your worker URL
wrangler deployments view

# Add your custom subdomain
wrangler domains add api.yourdomain.com

# Verify domain is active
wrangler domains list
```

## Step 11: Access Your Strapi Admin

Once deployed and domain is configured:

1. Visit: `https://api.yourdomain.com/admin`
2. Create your first admin user
3. Start building your content types!

## Troubleshooting

### Issue: "Container not ready"

**Solution:** Wait 5-10 minutes after first deployment. Containers take time to initialize.

```bash
# Check status
wrangler containers list

# View logs
wrangler tail
```

### Issue: "Database connection failed"

**For external PostgreSQL:**
- Verify connection details in secrets
- Ensure SSL is enabled if required
- Check firewall rules allow Cloudflare IPs

**For SQLite:**
- Verify `DATABASE_CLIENT=better-sqlite3` in vars
- Check file path is correct

### Issue: "Build fails"

**Solution:** Ensure all dependencies are in `package.json`:

```bash
# In your Strapi project
npm install better-sqlite3  # If using SQLite
npm install pg              # If using PostgreSQL

# Verify build locally first
docker build -t test .
```

### Issue: "Cannot access admin panel"

**Checklist:**
1. Is `PUBLIC_URL` set correctly in wrangler.toml?
2. Is custom domain configured and active?
3. Are CORS origins set correctly?
4. Check browser console for errors

```bash
# View live logs
wrangler tail

# Check if worker is responding
curl https://api.yourdomain.com/_health
```

### Issue: "File uploads not working"

**Solution:** Configure Cloudflare R2 for storage:

```bash
# Create R2 bucket
wrangler r2 bucket create strapi-uploads

# Update wrangler.toml
[[r2_buckets]]
binding = "STRAPI_UPLOADS"
bucket_name = "strapi-uploads"

# Redeploy
wrangler deploy
```

## Updating Your Deployment

When you make changes:

```bash
# 1. Test locally
docker-compose up

# 2. Commit changes
git add .
git commit -m "Update: description"

# 3. Deploy
wrangler deploy

# 4. Monitor
wrangler tail
```

## Environment-Specific Deployments

### Staging Environment

```bash
# Create staging config
cp wrangler.toml wrangler.staging.toml

# Update name
# name = "strapi-api-staging"

# Deploy to staging
wrangler deploy --config wrangler.staging.toml

# Set staging secrets
wrangler secret put JWT_SECRET --config wrangler.staging.toml
```

### Production Environment

Use the main `wrangler.toml` for production.

## Performance Optimization

### 1. Enable Caching

Add to `wrangler.toml`:

```toml
[vars]
CACHE_ENABLED = "true"
RESPONSE_CACHE_TIME = "3600"
```

### 2. Use R2 for File Uploads

Configure R2 instead of local storage:

```toml
[[r2_buckets]]
binding = "STRAPI_UPLOADS"
bucket_name = "strapi-production-uploads"
```

### 3. Configure Rate Limiting

In `.env.production`:

```env
RATE_LIMIT_ENABLED=true
RATE_LIMIT_MAX_REQUESTS=100
RATE_LIMIT_DURATION=60000
```

## Security Checklist

Before going live:

- [ ] All secrets set via `wrangler secret put`
- [ ] `PUBLIC_URL` set to actual domain
- [ ] CORS configured for specific origins (not `*`)
- [ ] Admin path changed from default `/admin`
- [ ] Rate limiting enabled
- [ ] Database password is strong (20+ characters)
- [ ] SSL/TLS enabled for database connection
- [ ] GraphQL playground disabled
- [ ] API documentation disabled
- [ ] Environment is set to `production`

## Monitoring & Maintenance

### View Logs

```bash
# Real-time logs
wrangler tail

# Filter for errors only
wrangler tail --format pretty | grep ERROR
```

### Check Metrics

Go to [Cloudflare Dashboard](https://dash.cloudflare.com):
- Workers & Pages → Your Worker
- View requests, errors, and performance

### Backup Database

**For SQLite (D1):**
```bash
# Export D1 database
wrangler d1 export <DATABASE_NAME> --output backup.sql
```

**For External PostgreSQL:**
Use your provider's backup tools or:
```bash
pg_dump -h hostname -U username -d database > backup.sql
```

## Cost Estimation

### Cloudflare Workers Free Tier
- 100,000 requests/day
- 10ms CPU time per request

### Cloudflare Workers Paid ($5/month)
- 10M requests/month included
- Additional $0.50 per million requests

### Additional Costs
- **R2 Storage:** $0.015/GB/month
- **Database:** Varies by provider
  - Neon: Free tier available
  - Supabase: Free tier available
  - Railway: ~$5-20/month

## Need Help?

- **Strapi Documentation:** https://docs.strapi.io
- **Cloudflare Containers Docs:** https://developers.cloudflare.com/containers/
- **Wrangler CLI Docs:** https://developers.cloudflare.com/workers/wrangler/
- **Template Issues:** https://github.com/codustry/strapi-cloudflare_containers-template/issues

## Next Steps

After deployment:
1. Set up SSL certificates (automatic with Cloudflare)
2. Configure CDN caching rules
3. Set up monitoring and alerts
4. Implement CI/CD pipeline
5. Configure backup strategy
6. Set up staging environment

Congratulations! Your Strapi application is now running on Cloudflare Containers! 🎉
