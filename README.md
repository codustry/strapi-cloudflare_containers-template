# Strapi V5 Docker Template for Cloudflare Containers

Production-ready Docker deployment template for Strapi V5, optimized for Cloudflare Containers with custom subdomain support.

## 🚀 Ready to Deploy?

- **[QUICKSTART.md](./QUICKSTART.md)** - Deploy in ~30 minutes
- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Complete deployment guide with troubleshooting

## Features

- Multi-stage Docker build for optimized production images
- PostgreSQL database with Docker Compose
- Health checks and security best practices
- Non-root user execution
- Cloudflare Containers ready
- Environment-based configuration
- Volume management for data persistence

## Prerequisites

- Docker and Docker Compose installed
- Node.js 22+ (for local development)
- Cloudflare account (for Cloudflare deployment)
- Wrangler CLI (for Cloudflare deployment)

## Quick Start

### 1. Create Your Strapi Project

First, create a new Strapi V5 project:

```bash
npx create-strapi@latest my-strapi-project
cd my-strapi-project
```

### 2. Copy Template Files

Copy all files from this template to your Strapi project:

```bash
cp /path/to/template/* /path/to/my-strapi-project/
```

### 3. Configure Environment Variables

This template includes environment configurations for different scenarios:

- `.env.example` - Complete reference with all options
- `.env.local.example` - Local development (SQLite, debug mode)
- `.env.production.example` - Production deployment (Cloudflare)

**For Local Development:**

```bash
cp .env.local.example .env
# Edit .env and set your subdomain/domain
```

**For Production:**

```bash
cp .env.production.example .env.production
# Edit and configure for your Cloudflare setup
```

**Generate Secure Secrets:**

Use the included script to generate all required secrets:

```bash
./scripts/generate-secrets.sh
```

Or manually generate them:

```bash
# Generate individual secrets
openssl rand -base64 32

# Run 4 times for APP_KEYS and comma-separate them
openssl rand -base64 32
```

**Important:** Update these values in your `.env` file:
- `PUBLIC_URL` - Set to your subdomain (e.g., `https://api.yourdomain.com`)
- `CORS_ORIGINS` - Add your frontend domains
- Database credentials
- All generated secrets

### 4. Local Development with Docker Compose

Start the application with PostgreSQL:

```bash
docker-compose up -d
```

Access Strapi at: http://localhost:1337

View logs:

```bash
docker-compose logs -f strapi
```

Stop services:

```bash
docker-compose down
```

## Cloudflare Containers Deployment

### Prerequisites

1. Install Wrangler CLI:

```bash
npm install -g wrangler
```

2. Authenticate with Cloudflare:

```bash
wrangler login
```

3. Ensure Docker is running locally:

```bash
docker info
```

### Deployment Steps

#### 1. Configure Database

Cloudflare Containers requires special database configuration. You have two options:

**Option A: Use Cloudflare D1 (SQLite)**

Update your `config/database.ts` to use SQLite:

```typescript
export default {
  connection: {
    client: 'better-sqlite3',
    connection: {
      filename: path.join(__dirname, '..', '..', '.tmp/data.db'),
    },
    useNullAsDefault: true,
  },
};
```

**Option B: Use External PostgreSQL**

Use a managed PostgreSQL service (Neon, Supabase, etc.) and configure the connection in your environment variables.

#### 2. Set Cloudflare Secrets

Set sensitive environment variables as secrets:

```bash
wrangler secret put JWT_SECRET
wrangler secret put ADMIN_JWT_SECRET
wrangler secret put API_TOKEN_SALT
wrangler secret put TRANSFER_TOKEN_SALT
wrangler secret put APP_KEYS
```

For external database:

```bash
wrangler secret put DATABASE_HOST
wrangler secret put DATABASE_PASSWORD
```

#### 3. Deploy to Cloudflare

```bash
wrangler deploy
```

This will:
1. Build your Docker image using the Dockerfile
2. Push the image to Cloudflare's Container Registry
3. Deploy your Worker
4. Configure Durable Objects

#### 4. Wait for Activation

After first deployment, wait several minutes for the container to be ready.

#### 5. Verify Deployment

Check container status:

```bash
wrangler containers list
```

View deployed images:

```bash
wrangler containers images list
```

### Important Cloudflare Considerations

1. **Architecture**: Images must support `linux/amd64`
2. **Storage**: Consider using Cloudflare R2 for file uploads
3. **Database**: Use Cloudflare D1 or external managed database
4. **Secrets**: Never commit secrets to version control
5. **Cold Starts**: First requests may be slower as containers spin up
6. **Max Instances**: Configured in `wrangler.toml` (default: 10)

## File Structure

```
.
├── Dockerfile                    # Multi-stage production Dockerfile
├── docker-compose.yml            # Local development orchestration
├── wrangler.toml                # Cloudflare Containers configuration
├── .dockerignore                # Docker build exclusions
├── .gitignore                   # Git exclusions
├── .env.example                 # Complete environment variables reference
├── .env.local.example           # Local development environment
├── .env.production.example      # Production environment template
├── scripts/
│   └── generate-secrets.sh      # Secret generation utility
├── README.md                    # This file
├── QUICKSTART.md                # Quick deployment guide (~30 min)
└── DEPLOYMENT.md                # Complete deployment guide
```

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `NODE_ENV` | Application environment | `production` |
| `DATABASE_CLIENT` | Database type | `postgres` or `better-sqlite3` |
| `DATABASE_HOST` | Database host | `postgres` |
| `DATABASE_PORT` | Database port | `5432` |
| `DATABASE_NAME` | Database name | `strapi` |
| `DATABASE_USERNAME` | Database user | `strapi` |
| `DATABASE_PASSWORD` | Database password | `secure_password` |
| `JWT_SECRET` | JWT signing key | Generate with openssl |
| `ADMIN_JWT_SECRET` | Admin JWT key | Generate with openssl |
| `APP_KEYS` | Session keys (comma-separated) | Generate 4 keys |
| `API_TOKEN_SALT` | API token salt | Generate with openssl |
| `TRANSFER_TOKEN_SALT` | Transfer token salt | Generate with openssl |

### Important for Cloudflare Subdomain Setup

| Variable | Description | Example |
|----------|-------------|---------|
| `PUBLIC_URL` | Full public URL with subdomain | `https://api.yourdomain.com` |
| `CORS_ORIGINS` | Allowed CORS origins (comma-separated) | `https://yourdomain.com,https://www.yourdomain.com` |
| `CF_ACCOUNT_ID` | Cloudflare Account ID | Found in dashboard |
| `CF_ZONE_ID` | Cloudflare Zone ID for your domain | Found in domain settings |
| `CF_API_TOKEN` | Cloudflare API token | Create with Workers/DNS permissions |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `HOST` | Server host | `0.0.0.0` |
| `PORT` | Server port | `1337` |
| `ADMIN_PATH` | Admin panel path | `/admin` |
| `RATE_LIMIT_ENABLED` | Enable rate limiting | `true` |
| `MAX_FILE_SIZE` | Max upload size in bytes | `104857600` (100MB) |
| `LOG_LEVEL` | Logging level | `info` |

### Environment Files Reference

See the example files for complete documentation:
- `.env.example` - All available options with detailed comments
- `.env.local.example` - Optimized for local development
- `.env.production.example` - Production-ready with security best practices

## Docker Commands

### Build Production Image

```bash
docker build -t strapi-v5:latest .
```

### Run Container

```bash
docker run -p 1337:1337 --env-file .env strapi-v5:latest
```

### View Logs

```bash
docker logs -f strapi-app
```

### Execute Commands in Container

```bash
docker exec -it strapi-app sh
```

## Troubleshooting

### Database Connection Issues

If Strapi can't connect to the database:

1. Ensure PostgreSQL is running: `docker-compose ps`
2. Check database logs: `docker-compose logs postgres`
3. Verify environment variables in `.env`

### Build Failures

If Docker build fails:

1. Ensure all dependencies are in `package.json`
2. Check Node.js version compatibility
3. Verify build logs for missing packages

### Cloudflare Deployment Issues

1. **Docker not running**: Run `docker info` to verify
2. **Authentication failed**: Run `wrangler login` again
3. **Image architecture**: Ensure you're building for `linux/amd64`
4. **Container not ready**: Wait several minutes after first deployment

### Health Check Failures

If health checks fail:

1. Check if Strapi is listening on port 1337
2. Verify the health endpoint is accessible
3. Check container logs for errors

## Security Best Practices

1. Never commit `.env` files to version control
2. Use strong, randomly generated secrets
3. Run containers as non-root user (already configured)
4. Keep dependencies updated
5. Use managed database services for production
6. Enable SSL/TLS for database connections
7. Regularly backup your database

## Performance Optimization

1. Use multi-stage builds (already implemented)
2. Minimize image size by excluding unnecessary files
3. Use production dependencies only in final image
4. Configure appropriate resource limits
5. Enable caching layers in Cloudflare
6. Use CDN for static assets

## Database Backup

### Local PostgreSQL Backup

```bash
docker exec strapi-db pg_dump -U strapi strapi > backup.sql
```

### Restore from Backup

```bash
docker exec -i strapi-db psql -U strapi strapi < backup.sql
```

## Updating Strapi

1. Update `package.json` with new version
2. Rebuild Docker image
3. Test locally with docker-compose
4. Deploy to Cloudflare

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Support

- Strapi Documentation: https://docs.strapi.io
- Strapi GitHub: https://github.com/strapi/strapi
- Cloudflare Containers Docs: https://developers.cloudflare.com/containers/
- Docker Documentation: https://docs.docker.com

## License

This template is provided as-is for use with Strapi V5 projects.
