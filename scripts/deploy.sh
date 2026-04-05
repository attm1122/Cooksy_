#!/bin/bash

# Cooksy Vercel Deployment Script
# Usage: ./scripts/deploy.sh [preview|production]

set -e

echo "🚀 Cooksy Deployment Script"
echo "==========================="

# Check if vercel is installed
if ! command -v vercel &> /dev/null; then
    echo "❌ Vercel CLI not found. Installing..."
    npm install -g vercel
fi

# Check if logged in
if ! vercel whoami &> /dev/null; then
    echo "🔑 Please login to Vercel first:"
    echo "   vercel login"
    exit 1
fi

# Determine deployment target
TARGET="${1:-preview}"

if [ "$TARGET" == "production" ] || [ "$TARGET" == "--prod" ]; then
    echo "📦 Building for production..."
    npm run build:web
    
    echo "🚀 Deploying to production..."
    vercel --prod
else
    echo "📦 Building for preview..."
    npm run build:web
    
    echo "🚀 Deploying to preview..."
    vercel
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Check your deployment URL above"
echo "2. Add environment variables in Vercel dashboard if needed"
echo "3. Test the deployed application"
