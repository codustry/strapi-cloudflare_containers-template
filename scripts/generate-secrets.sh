#!/bin/bash

################################################################################
# Strapi V5 Secrets Generator
################################################################################
# This script generates secure random secrets for Strapi V5
# Usage: ./scripts/generate-secrets.sh
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if openssl is available
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}Error: openssl is not installed${NC}"
    echo "Please install openssl first:"
    echo "  macOS: brew install openssl"
    echo "  Ubuntu/Debian: sudo apt-get install openssl"
    echo "  CentOS/RHEL: sudo yum install openssl"
    exit 1
fi

# Print header
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Strapi V5 Security Secrets Generator              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to generate a secure random string
generate_secret() {
    openssl rand -base64 32 | tr -d '\n'
}

# Generate secrets
echo -e "${YELLOW}Generating secure secrets...${NC}"
echo ""

JWT_SECRET=$(generate_secret)
ADMIN_JWT_SECRET=$(generate_secret)
API_TOKEN_SALT=$(generate_secret)
TRANSFER_TOKEN_SALT=$(generate_secret)
APP_KEY1=$(generate_secret)
APP_KEY2=$(generate_secret)
APP_KEY3=$(generate_secret)
APP_KEY4=$(generate_secret)
DATABASE_PASSWORD=$(openssl rand -base64 24 | tr -d '\n')

# Print secrets in format ready for .env file
echo -e "${GREEN}✓ Secrets generated successfully!${NC}"
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Copy the following to your .env file:${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

cat << EOF
# Generated Security Secrets - $(date)
JWT_SECRET=${JWT_SECRET}
ADMIN_JWT_SECRET=${ADMIN_JWT_SECRET}
API_TOKEN_SALT=${API_TOKEN_SALT}
TRANSFER_TOKEN_SALT=${TRANSFER_TOKEN_SALT}
APP_KEYS=${APP_KEY1},${APP_KEY2},${APP_KEY3},${APP_KEY4}
DATABASE_PASSWORD=${DATABASE_PASSWORD}
EOF

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Option to save to file
read -p "$(echo -e ${YELLOW}Do you want to save these to .env.secrets? [y/N]:${NC} )" -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    cat > .env.secrets << EOF
# Generated Security Secrets - $(date)
# IMPORTANT: Keep this file secure and never commit to version control!
JWT_SECRET=${JWT_SECRET}
ADMIN_JWT_SECRET=${ADMIN_JWT_SECRET}
API_TOKEN_SALT=${API_TOKEN_SALT}
TRANSFER_TOKEN_SALT=${TRANSFER_TOKEN_SALT}
APP_KEYS=${APP_KEY1},${APP_KEY2},${APP_KEY3},${APP_KEY4}
DATABASE_PASSWORD=${DATABASE_PASSWORD}

# To use these secrets:
# 1. Copy them to your .env file, OR
# 2. For Cloudflare deployment, set them using wrangler:
#    wrangler secret put JWT_SECRET
#    wrangler secret put ADMIN_JWT_SECRET
#    wrangler secret put API_TOKEN_SALT
#    wrangler secret put TRANSFER_TOKEN_SALT
#    wrangler secret put APP_KEYS
#    wrangler secret put DATABASE_PASSWORD
EOF

    chmod 600 .env.secrets
    echo -e "${GREEN}✓ Secrets saved to .env.secrets${NC}"
    echo -e "${RED}⚠ Keep this file secure! It's added to .gitignore${NC}"
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Copy the secrets above to your .env file"
echo "2. For Cloudflare deployment, use: wrangler secret put <KEY_NAME>"
echo "3. Update other environment variables (database, domain, etc.)"
echo ""
echo -e "${BLUE}Security Reminders:${NC}"
echo "✓ Never commit .env or .env.secrets to version control"
echo "✓ Use different secrets for each environment"
echo "✓ Store production secrets in a secure secrets manager"
echo "✓ Rotate secrets periodically"
echo ""
