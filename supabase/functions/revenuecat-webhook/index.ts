/**
 * RevenueCat Webhook Handler
 * Processes subscription events from RevenueCat
 * 
 * Events handled:
 * - INITIAL_PURCHASE: New subscription
 * - RENEWAL: Subscription renewed
 * - CANCELLATION: User cancelled
 * - EXPIRATION: Subscription expired
 * - PRODUCT_CHANGE: Plan upgraded/downgraded
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.8';

interface RevenueCatEvent {
  event: {
    type: string;
    id: string;
    event_timestamp_ms: number;
    app_user_id: string;
    aliases: string[];
    product_id: string;
    entitlement_ids: string[];
    store: 'APP_STORE' | 'PLAY_STORE' | 'STRIPE' | 'AMAZON';
    environment: 'SANDBOX' | 'PRODUCTION';
    
    // Subscription details
    purchased_at_ms: number;
    expiration_at_ms?: number;
    auto_resume_at_ms?: number;
    
    // Cancellation details
    cancellation_reason?: string;
    
    // Transaction details
    transaction_id: string;
    original_transaction_id: string;
    
    // Plan details
    new_product_id?: string;
    
    // For trial conversion
    is_trial_conversion?: boolean;
    
    // Currency
    currency?: string;
    price?: number;
    price_in_purchased_currency?: number;
    takehome_percentage?: number;
    
    // Trial details
    trial_start_at_ms?: number;
    trial_end_at_ms?: number;
    
    // Metadata
    subscriber_attributes?: Record<string, { value: string; updated_at_ms: number }>;
  };
}

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Verify webhook authorization
    const authHeader = req.headers.get('Authorization');
    const expectedAuth = Deno.env.get('REVENUECAT_WEBHOOK_AUTH');
    
    if (expectedAuth && authHeader !== `Bearer ${expectedAuth}`) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Parse webhook payload
    const payload: RevenueCatEvent = await req.json();
    const event = payload.event;

    console.log(`Processing RevenueCat event: ${event.type}`, {
      userId: event.app_user_id,
      productId: event.product_id,
      environment: event.environment,
    });

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Log the event
    await logWebhookEvent(supabase, event);

    // Process based on event type
    switch (event.type) {
      case 'INITIAL_PURCHASE':
      case 'RENEWAL':
      case 'UNCANCELLATION':
      case 'SUBSCRIPTION_EXTENDED':
        await handleSubscriptionActive(supabase, event);
        break;

      case 'CANCELLATION':
        await handleCancellation(supabase, event);
        break;

      case 'EXPIRATION':
        await handleExpiration(supabase, event);
        break;

      case 'PRODUCT_CHANGE':
        await handleProductChange(supabase, event);
        break;

      case 'BILLING_ISSUE':
        await handleBillingIssue(supabase, event);
        break;

      case 'TRANSFER':
        await handleTransfer(supabase, event);
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Webhook processing error:', error);
    
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

// Log webhook event for debugging
async function logWebhookEvent(supabase: any, event: RevenueCatEvent['event']) {
  try {
    await supabase.from('revenuecat_webhook_events').insert({
      event_type: event.type,
      event_id: event.id,
      payload: event,
      processed_at: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Failed to log webhook event:', error);
  }
}

// Handle new subscription or renewal
async function handleSubscriptionActive(supabase: any, event: RevenueCatEvent['event']) {
  const userId = event.app_user_id;
  const planId = event.product_id;
  const isPremium = event.entitlement_ids.includes('premium');
  const platform = mapPlatform(event.store);
  
  // Calculate period dates
  const periodStart = new Date(event.purchased_at_ms).toISOString();
  const periodEnd = event.expiration_at_ms 
    ? new Date(event.expiration_at_ms).toISOString()
    : null;

  // Upsert subscription
  const { error } = await supabase
    .from('user_subscriptions')
    .upsert({
      user_id: userId,
      revenuecat_customer_id: event.app_user_id,
      revenuecat_entitlement_id: isPremium ? 'premium' : null,
      status: 'active',
      plan_id: planId,
      current_period_start: periodStart,
      current_period_end: periodEnd,
      platform: platform,
      is_trial: event.trial_end_at_ms !== undefined && event.trial_end_at_ms > Date.now(),
      updated_at: new Date().toISOString(),
    }, {
      onConflict: 'user_id,revenuecat_entitlement_id',
    });

  if (error) {
    console.error('Failed to update subscription:', error);
    throw error;
  }

  // Track analytics event
  console.log(`Subscription activated for user ${userId}`, {
    plan: planId,
    platform,
    isTrial: event.trial_end_at_ms !== undefined,
  });
}

// Handle cancellation
async function handleCancellation(supabase: any, event: RevenueCatEvent['event']) {
  const userId = event.app_user_id;
  
  // Mark as cancelled but keep access until expiry
  const { error } = await supabase
    .from('user_subscriptions')
    .update({
      status: 'cancelled',
      cancelled_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('user_id', userId)
    .eq('revenuecat_entitlement_id', 'premium');

  if (error) {
    console.error('Failed to handle cancellation:', error);
  }

  console.log(`Subscription cancelled for user ${userId}`, {
    reason: event.cancellation_reason,
  });
}

// Handle expiration
async function handleExpiration(supabase: any, event: RevenueCatEvent['event']) {
  const userId = event.app_user_id;
  
  const { error } = await supabase
    .from('user_subscriptions')
    .update({
      status: 'expired',
      updated_at: new Date().toISOString(),
    })
    .eq('user_id', userId)
    .eq('revenuecat_entitlement_id', 'premium');

  if (error) {
    console.error('Failed to handle expiration:', error);
  }

  console.log(`Subscription expired for user ${userId}`);
}

// Handle plan change (upgrade/downgrade)
async function handleProductChange(supabase: any, event: RevenueCatEvent['event']) {
  const userId = event.app_user_id;
  const newPlanId = event.new_product_id;
  
  if (!newPlanId) return;

  const { error } = await supabase
    .from('user_subscriptions')
    .update({
      plan_id: newPlanId,
      updated_at: new Date().toISOString(),
    })
    .eq('user_id', userId)
    .eq('revenuecat_entitlement_id', 'premium');

  if (error) {
    console.error('Failed to handle product change:', error);
  }

  console.log(`Plan changed for user ${userId}`, {
    newPlan: newPlanId,
  });
}

// Handle billing issue
async function handleBillingIssue(supabase: any, event: RevenueCatEvent['event']) {
  const userId = event.app_user_id;
  
  // Could send notification to user here
  console.log(`Billing issue for user ${userId}`, {
    gracePeriodEnd: event.grace_period_expiration_at_ms,
  });
}

// Handle transfer (restore on new device)
async function handleTransfer(supabase: any, event: RevenueCatEvent['event']) {
  const fromUserId = event.transferred_from?.[0];
  const toUserId = event.app_user_id;
  
  console.log(`Transfer from ${fromUserId} to ${toUserId}`);
  
  // RevenueCat handles the transfer, we just need to ensure the new user gets the entitlement
  await handleSubscriptionActive(supabase, event);
}

// Map store to platform
function mapPlatform(store: string): string {
  switch (store) {
    case 'APP_STORE':
      return 'ios';
    case 'PLAY_STORE':
      return 'android';
    case 'STRIPE':
      return 'stripe';
    case 'AMAZON':
      return 'amazon';
    default:
      return 'unknown';
  }
}
