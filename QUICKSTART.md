# Quick Start: Deploy Strapi V5 to Cloudflare Containers

**Time to deploy:** ~30 minutes

## TL;DR

```bash
# 1. Create Strapi project
npx create-strapi@latest my-strapi-app
cd my-strapi-app

# 2. Clone template files
git clone https://github.com/codustry/strapi-cloudflare_containers-template.git /tmp/template
cp /tmp/template/{Dockerfile,docker-compose.yml,wrangler.toml,.dockerignore,.env.production.example} .
cp -r /tmp/template/scripts .
rm -rf /tmp/template

# 3. Generate secrets
chmod +x scripts/generate-secrets.sh
./scripts/generate-secrets.sh

# 4. Configure environment
cp .env.production.example .env.production
# Edit: PUBLIC_URL, database settings, CORS

# 5. Install SQLite for Cloudflare D1
npm install better-sqlite3

# 6. Update database config (config/database.ts)
# Use SQLite configuration (see DEPLOYMENT.md)

# 7. Set up Wrangler
npm install -g wrangler
wrangler login

# 8. Update wrangler.toml
# Set: name, PUBLIC_URL

# 9. Set secrets
wrangler secret put JWT_SECRET
wrangler secret put ADMIN_JWT_SECRET
wrangler secret put API_TOKEN_SALT
wrangler secret put TRANSFER_TOKEN_SALT
wrangler secret put APP_KEYS

# 10. Deploy!
docker info  # Make sure Docker is running
wrangler deploy

# 11. Configure domain
wrangler domains add api.yourdomain.com

# 12. Access admin
# https://api.yourdomain.com/admin
```

## Minimal Configuration

### config/database.ts (for SQLite)

```typescript
import path from 'path';

export default ({ env }) => ({
  connection: {
    client: 'better-sqlite3',
    connection: {
      filename: env('DATABASE_FILENAME', path.join(__dirname, '..', '..', '.tmp/data.db')),
    },
    useNullAsDefault: true,
  },
});
```

### wrangler.toml (minimum config)

```toml
name = "my-strapi-api"
main = "src/index.js"
compatibility_date = "2024-01-01"

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

[vars]
NODE_ENV = "production"
HOST = "0.0.0.0"
PORT = "1337"
PUBLIC_URL = "https://api.yourdomain.com"
DATABASE_CLIENT = "better-sqlite3"
DATABASE_FILENAME = "/data/production.db"
```

### .env.production (minimum)

```env
NODE_ENV=production
PUBLIC_URL=https://api.yourdomain.com

DATABASE_CLIENT=better-sqlite3
DATABASE_FILENAME=/data/production.db

# Secrets (use generated values)
JWT_SECRET=your_generated_secret
ADMIN_JWT_SECRET=your_generated_secret
API_TOKEN_SALT=your_generated_secret
TRANSFER_TOKEN_SALT=your_generated_secret
APP_KEYS=key1,key2,key3,key4

CORS_ORIGINS=https://yourdomain.com
```

## Common Issues

### "gh not found" or "wrangler not found"
```bash
npm install -g wrangler
brew install gh  # macOS
```

### "Docker daemon not running"
```bash
# Start Docker Desktop
open -a Docker

# Wait for Docker to start, then:
docker info
```

### "Permission denied: ./scripts/generate-secrets.sh"
```bash
chmod +x scripts/generate-secrets.sh
```

### "Module not found: better-sqlite3"
```bash
npm install better-sqlite3
```

### Container not responding after deploy
Wait 5-10 minutes after first deployment. Check status:
```bash
wrangler tail
wrangler containers list
```

## Using External PostgreSQL Instead

If you prefer PostgreSQL over SQLite:

```bash
# 1. Set up database with Neon, Supabase, or Railway

# 2. Update wrangler.toml vars:
[vars]
DATABASE_CLIENT = "postgres"

# 3. Set secrets:
wrangler secret put DATABASE_HOST
wrangler secret put DATABASE_PORT
wrangler secret put DATABASE_NAME
wrangler secret put DATABASE_USERNAME
wrangler secret put DATABASE_PASSWORD

# 4. Keep existing config/database.ts (already configured for PostgreSQL)
```

## Next Steps

- Read full [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed instructions
- Set up monitoring and alerts
- Configure R2 for file uploads
- Add custom domain SSL (automatic with Cloudflare)
- Set up CI/CD pipeline

## Getting Help

- Full deployment guide: [DEPLOYMENT.md](./DEPLOYMENT.md)
- Template issues: https://github.com/codustry/strapi-cloudflare_containers-template/issues
- Strapi docs: https://docs.strapi.io
- Cloudflare docs: https://developers.cloudflare.com/containers/
