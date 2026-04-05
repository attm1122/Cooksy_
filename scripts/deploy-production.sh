#!/bin/bash

# Cooksy Production Deployment Script
# Usage: ./scripts/deploy-production.sh [staging|production]

set -e

ENV=${1:-staging}
SUPABASE_PROJECT_REF=${SUPABASE_PROJECT_REF:-""}

echo "🍳 Cooksy Production Deployment"
echo "================================"
echo "Environment: $ENV"
echo ""

# Validate environment
if [ -z "$SUPABASE_PROJECT_REF" ]; then
  echo "❌ Error: SUPABASE_PROJECT_REF not set"
  echo "Set it with: export SUPABASE_PROJECT_REF=your-project-ref"
  exit 1
fi

# Check dependencies
echo "📦 Checking dependencies..."
if ! command -v supabase &> /dev/null; then
  echo "❌ Supabase CLI not found. Install with:"
  echo "   npm install -g supabase"
  exit 1
fi

if ! command -v vercel &> /dev/null; then
  echo "❌ Vercel CLI not found. Install with:"
  echo "   npm install -g vercel"
  exit 1
fi

# Run tests
echo "🧪 Running tests..."
npm test
if [ $? -ne 0 ]; then
  echo "❌ Tests failed"
  exit 1
fi

# Type check
echo "🔍 Running type check..."
npm run typecheck
if [ $? -ne 0 ]; then
  echo "❌ Type check failed"
  exit 1
fi

# Deploy database migrations
echo "🗄️  Deploying database migrations..."
supabase link --project-ref "$SUPABASE_PROJECT_REF"
supabase db push

# Deploy edge functions
echo "⚡ Deploying edge functions..."
supabase functions deploy import-recipe
supabase functions deploy ops-health

# Set edge function secrets (if not already set)
echo "🔐 Checking edge function secrets..."
# Note: Secrets should be set manually first time:
# supabase secrets set SUPABASE_URL=...
# supabase secrets set SUPABASE_ANON_KEY=...
# supabase secrets set SUPABASE_SERVICE_ROLE_KEY=...

# Deploy web app
echo "🌐 Deploying web app to Vercel..."
if [ "$ENV" == "production" ]; then
  vercel --prod
else
  vercel
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Post-deployment checklist:"
echo "   1. Test import flow"
echo "   2. Check monitoring dashboards"
echo "   3. Verify analytics events"
echo "   4. Test error reporting"
echo ""
echo "🔗 Useful links:"
echo "   - Supabase Dashboard: https://app.supabase.com/project/$SUPABASE_PROJECT_REF"
echo "   - Vercel Dashboard: https://vercel.com/dashboard"
