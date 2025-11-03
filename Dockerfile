# Multi-stage Dockerfile for Strapi V5 Production
# Optimized for Cloudflare Containers (linux/amd64)

# ===================================
# Stage 1: Build Stage
# ===================================
FROM node:22-alpine AS builder

# Install build dependencies for sharp (image processing library)
RUN apk add --no-cache \
    build-base \
    gcc \
    autoconf \
    automake \
    libtool \
    nasm \
    libpng-dev \
    vips-dev

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY yarn.lock* ./

# Install dependencies
RUN yarn install --frozen-lockfile || npm ci

# Copy source code
COPY . .

# Set NODE_ENV to production
ENV NODE_ENV=production

# Build Strapi admin panel and optimize
RUN yarn build || npm run build

# ===================================
# Stage 2: Production Stage
# ===================================
FROM node:22-alpine AS production

# Install runtime dependencies
RUN apk add --no-cache \
    vips-dev \
    vips

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY yarn.lock* ./

# Install only production dependencies
RUN yarn install --production --frozen-lockfile || npm ci --only=production

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public
COPY --from=builder /app/.strapi ./.strapi

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S strapi -u 1001 && \
    chown -R strapi:nodejs /app

USER strapi

# Expose Strapi port
EXPOSE 1337

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:1337/_health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start Strapi in production mode
CMD ["node", "node_modules/@strapi/strapi/bin/strapi.js", "start"]
