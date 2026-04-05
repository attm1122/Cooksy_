-- Migration: Subscription system with RevenueCat integration
-- Free tier: 3 uploads, no delete, YouTube only, no books
-- Premium: unlimited, delete allowed, books allowed

-- ============================================
-- 1. ENTITLEMENTS (Feature flags)
-- ============================================

create table if not exists public.entitlements (
    id text primary key,
    name text not null,
    description text,
    created_at timestamp with time zone default now()
);

-- Insert core entitlements
insert into public.entitlements (id, name, description) values
    ('unlimited_uploads', 'Unlimited Uploads', 'Upload unlimited recipes'),
    ('delete_recipes', 'Delete Recipes', 'Ability to delete saved recipes'),
    ('recipe_books', 'Recipe Books', 'Create and manage recipe books'),
    ('tiktok_imports', 'TikTok Imports', 'Import recipes from TikTok'),
    ('instagram_imports', 'Instagram Imports', 'Import recipes from Instagram')
on conflict (id) do nothing;

-- ============================================
-- 2. SUBSCRIPTION PLANS
-- ============================================

create table if not exists public.subscription_plans (
    id text primary key, -- revenuecat_product_id
    name text not null,
    description text,
    interval text not null check (interval in ('monthly', 'yearly', 'lifetime')),
    price_aud integer not null, -- in cents
    is_active boolean default true,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Insert pricing plans (AUD base)
insert into public.subscription_plans (id, name, description, interval, price_aud) values
    ('cooksy_premium_monthly', 'Cooksy Premium Monthly', 'Monthly premium subscription', 'monthly', 599),
    ('cooksy_premium_yearly', 'Cooksy Premium Yearly', 'Yearly premium subscription (17% savings)', 'yearly', 6000)
on conflict (id) do update set
    name = excluded.name,
    description = excluded.description,
    price_aud = excluded.price_aud;

-- ============================================
-- 3. PLAN ENTITLEMENTS MAPPING
-- ============================================

create table if not exists public.plan_entitlements (
    plan_id text references public.subscription_plans(id) on delete cascade,
    entitlement_id text references public.entitlements(id) on delete cascade,
    created_at timestamp with time zone default now(),
    primary key (plan_id, entitlement_id)
);

-- Premium plan gets all entitlements
insert into public.plan_entitlements (plan_id, entitlement_id)
select 'cooksy_premium_monthly', id from public.entitlements
on conflict do nothing;

insert into public.plan_entitlements (plan_id, entitlement_id)
select 'cooksy_premium_yearly', id from public.entitlements
on conflict do nothing;

-- ============================================
-- 4. USER SUBSCRIPTIONS
-- ============================================

create table if not exists public.user_subscriptions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id) on delete cascade not null,
    
    -- RevenueCat integration
    revenuecat_customer_id text,
    revenuecat_entitlement_id text,
    
    -- Subscription status
    status text not null check (status in ('active', 'cancelled', 'expired', 'grace_period', 'paused')),
    plan_id text references public.subscription_plans(id),
    
    -- Dates
    current_period_start timestamp with time zone,
    current_period_end timestamp with time zone,
    cancelled_at timestamp with time zone,
    
    -- Metadata
    platform text check (platform in ('ios', 'android', 'web', 'stripe')),
    is_trial boolean default false,
    
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    
    unique(user_id, revenuecat_entitlement_id)
);

-- Indexes
create index if not exists idx_user_subscriptions_user_id on public.user_subscriptions(user_id);
create index if not exists idx_user_subscriptions_status on public.user_subscriptions(status);
create index if not exists idx_user_subscriptions_revenuecat_customer on public.user_subscriptions(revenuecat_customer_id);

-- ============================================
-- 5. UPLOAD QUOTA TRACKING (for free tier)
-- ============================================

create table if not exists public.user_upload_quota (
    user_id uuid primary key references auth.users(id) on delete cascade,
    uploads_used integer default 0,
    uploads_limit integer default 3, -- Free tier limit
    period_start timestamp with time zone default now(),
    period_end timestamp with time zone default (now() + interval '30 days'),
    updated_at timestamp with time zone default now()
);

-- ============================================
-- 6. REVENUECAT WEBHOOK EVENTS LOG
-- ============================================

create table if not exists public.revenuecat_webhook_events (
    id uuid primary key default gen_random_uuid(),
    event_type text not null,
    event_id text unique not null,
    payload jsonb not null,
    processed_at timestamp with time zone,
    created_at timestamp with time zone default now()
);

create index if not exists idx_revenuecat_events_event_id on public.revenuecat_webhook_events(event_id);
create index if not exists idx_revenuecat_events_processed on public.revenuecat_webhook_events(processed_at);

-- ============================================
-- 7. FUNCTIONS
-- ============================================

-- Check if user has specific entitlement
create or replace function public.user_has_entitlement(p_user_id uuid, p_entitlement text)
returns boolean as $$
begin
    -- Premium users have all entitlements
    return exists (
        select 1 from public.user_subscriptions
        where user_id = p_user_id
        and status = 'active'
        and current_period_end > now()
    );
end;
$$ language plpgsql security definer;

-- Get user's remaining uploads
create or replace function public.get_remaining_uploads(p_user_id uuid)
returns integer as $$
declare
    v_remaining integer;
    v_is_premium boolean;
begin
    -- Check if premium
    select exists (
        select 1 from public.user_subscriptions
        where user_id = p_user_id
        and status = 'active'
        and current_period_end > now()
    ) into v_is_premium;
    
    -- Premium = unlimited
    if v_is_premium then
        return -1; -- unlimited
    end if;
    
    -- Free tier check
    select uploads_limit - uploads_used into v_remaining
    from public.user_upload_quota
    where user_id = p_user_id;
    
    -- No record = full quota
    if v_remaining is null then
        return 3;
    end if;
    
    return greatest(v_remaining, 0);
end;
$$ language plpgsql security definer;

-- Increment upload count
create or replace function public.increment_upload_count(p_user_id uuid)
returns boolean as $$
declare
    v_is_premium boolean;
begin
    -- Check if premium
    select exists (
        select 1 from public.user_subscriptions
        where user_id = p_user_id
        and status = 'active'
        and current_period_end > now()
    ) into v_is_premium;
    
    -- Premium users don't count
    if v_is_premium then
        return true;
    end if;
    
    -- Insert or update quota
    insert into public.user_upload_quota (user_id, uploads_used)
    values (p_user_id, 1)
    on conflict (user_id) do update
    set uploads_used = user_upload_quota.uploads_used + 1,
        updated_at = now();
    
    return true;
end;
$$ language plpgsql security definer;

-- Get user subscription info
create or replace function public.get_user_subscription(p_user_id uuid)
returns jsonb as $$
declare
    v_subscription jsonb;
    v_uploads_remaining integer;
begin
    select get_remaining_uploads(p_user_id) into v_uploads_remaining;
    
    select jsonb_build_object(
        'isPremium', true,
        'plan', plan_id,
        'status', status,
        'currentPeriodEnd', current_period_end,
        'platform', platform,
        'uploadsRemaining', v_uploads_remaining,
        'features', jsonb_build_object(
            'canDelete', true,
            'canCreateBooks', true,
            'unlimitedUploads', true,
            'tiktokImports', true,
            'instagramImports', true
        )
    )
    into v_subscription
    from public.user_subscriptions
    where user_id = p_user_id
    and status = 'active'
    and current_period_end > now()
    limit 1;
    
    -- No active subscription = free tier
    if v_subscription is null then
        return jsonb_build_object(
            'isPremium', false,
            'plan', null,
            'status', 'free',
            'currentPeriodEnd', null,
            'platform', null,
            'uploadsRemaining', v_uploads_remaining,
            'features', jsonb_build_object(
                'canDelete', false,
                'canCreateBooks', false,
                'unlimitedUploads', false,
                'tiktokImports', false,
                'instagramImports', false
            )
        );
    end if;
    
    return v_subscription;
end;
$$ language plpgsql security definer;

-- Reset free tier quotas monthly
create or replace function public.reset_free_quotas()
returns void as $$
begin
    update public.user_upload_quota
    set uploads_used = 0,
        period_start = now(),
        period_end = now() + interval '30 days',
        updated_at = now()
    where period_end < now()
    and not exists (
        select 1 from public.user_subscriptions
        where user_subscriptions.user_id = user_upload_quota.user_id
        and status = 'active'
        and current_period_end > now()
    );
end;
$$ language plpgsql security definer;

-- Sync subscription from RevenueCat
create or replace function public.sync_revenuecat_subscription(
    p_user_id uuid,
    p_is_premium boolean,
    p_plan_id text,
    p_expires_at timestamp with time zone,
    p_will_renew boolean,
    p_platform text,
    p_revenuecat_customer_id text
)
returns void as $$
begin
    if p_is_premium then
        insert into public.user_subscriptions (
            user_id,
            revenuecat_customer_id,
            revenuecat_entitlement_id,
            status,
            plan_id,
            current_period_end,
            platform
        ) values (
            p_user_id,
            p_revenuecat_customer_id,
            'premium',
            case when p_will_renew then 'active' else 'cancelled' end,
            p_plan_id,
            p_expires_at,
            p_platform
        )
        on conflict (user_id, revenuecat_entitlement_id) do update set
            status = case when p_will_renew then 'active' else 'cancelled' end,
            plan_id = p_plan_id,
            current_period_end = p_expires_at,
            platform = p_platform,
            revenuecat_customer_id = p_revenuecat_customer_id,
            updated_at = now();
    else
        -- Mark as expired if not premium
        update public.user_subscriptions
        set status = 'expired',
            updated_at = now()
        where user_id = p_user_id
        and revenuecat_entitlement_id = 'premium';
    end if;
end;
$$ language plpgsql security definer;

-- ============================================
-- 8. TRIGGERS
-- ============================================

-- Update timestamps
create or replace function public.update_subscription_timestamp()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

drop trigger if exists update_subscription_timestamp on public.user_subscriptions;
create trigger update_subscription_timestamp
    before update on public.user_subscriptions
    for each row execute function public.update_subscription_timestamp();

drop trigger if exists update_quota_timestamp on public.user_upload_quota;
create trigger update_quota_timestamp
    before update on public.user_upload_quota
    for each row execute function public.update_subscription_timestamp();

-- ============================================
-- 9. RLS POLICIES
-- ============================================

-- Users can only see their own subscription
alter table public.user_subscriptions enable row level security;

create policy "Users can view own subscription"
    on public.user_subscriptions for select
    using (auth.uid() = user_id);

-- Webhook events only accessible by service role
alter table public.revenuecat_webhook_events enable row level security;

create policy "Service role can manage webhook events"
    on public.revenuecat_webhook_events for all
    using (false); -- Only service role via RPC

-- Upload quota - users see own only
alter table public.user_upload_quota enable row level security;

create policy "Users can view own quota"
    on public.user_upload_quota for select
    using (auth.uid() = user_id);

-- Entitlements and plans are public read-only
alter table public.entitlements enable row level security;
alter table public.subscription_plans enable row level security;
alter table public.plan_entitlements enable row level security;

create policy "Entitlements are public"
    on public.entitlements for select
    using (true);

create policy "Plans are public"
    on public.subscription_plans for select
    using (true);

create policy "Plan entitlements are public"
    on public.plan_entitlements for select
    using (true);

-- ============================================
-- 10. GLOBAL PRICING (Netflix PPP Model)
-- ============================================

create table if not exists public.pricing_by_country (
    country_code text primary key, -- ISO 3166-1 alpha-2
    country_name text not null,
    currency_code text not null, -- ISO 4217
    ppp_adjustment decimal(4,2) not null, -- multiplier from base AUD price
    
    -- Local prices (in cents)
    monthly_price integer not null,
    yearly_price integer not null,
    
    -- Display
    price_display_template text not null, -- e.g., '${price}/month'
    
    is_active boolean default true,
    updated_at timestamp with time zone default now()
);

-- Netflix-style PPP pricing based on purchasing power
-- Source: World Bank PPP conversion factors, approximated
insert into public.pricing_by_country (country_code, country_name, currency_code, ppp_adjustment, monthly_price, yearly_price, price_display_template) values
    -- Tier 1: Premium markets (AUD base)
    ('AU', 'Australia', 'AUD', 1.00, 599, 6000, '${price}/month'),
    ('US', 'United States', 'USD', 1.00, 399, 3999, '${price}/month'),
    ('CA', 'Canada', 'CAD', 1.00, 549, 5499, '${price}/month'),
    ('GB', 'United Kingdom', 'GBP', 1.00, 349, 3499, '${price}/month'),
    ('NZ', 'New Zealand', 'NZD', 1.00, 649, 6499, '${price}/month'),
    ('CH', 'Switzerland', 'CHF', 1.00, 699, 6999, '${price}/month'),
    ('NO', 'Norway', 'NOK', 1.00, 4499, 44999, '${price}/month'),
    ('SE', 'Sweden', 'SEK', 1.00, 4499, 44999, '${price}/month'),
    ('DK', 'Denmark', 'DKK', 1.00, 2999, 29999, '${price}/month'),
    
    -- Tier 2: High income (10-15% discount)
    ('JP', 'Japan', 'JPY', 0.90, 49900, 499000, '¥${price}/月'),
    ('KR', 'South Korea', 'KRW', 0.90, 549000, 5490000, '₩${price}/월'),
    ('SG', 'Singapore', 'SGD', 0.90, 549, 5499, '${price}/month'),
    ('HK', 'Hong Kong', 'HKD', 0.90, 2999, 29999, '${price}/month'),
    ('TW', 'Taiwan', 'TWD', 0.90, 11999, 119999, 'NT${price}/月'),
    ('IL', 'Israel', 'ILS', 0.90, 1499, 14999, '₪${price}/חודש'),
    
    -- Tier 3: Upper middle income (25-35% discount)
    ('DE', 'Germany', 'EUR', 0.75, 449, 4499, '${price}/Monat'),
    ('FR', 'France', 'EUR', 0.75, 449, 4499, '${price}/mois'),
    ('IT', 'Italy', 'EUR', 0.75, 399, 3999, '${price}/mese'),
    ('ES', 'Spain', 'EUR', 0.75, 399, 3999, '${price}/mes'),
    ('NL', 'Netherlands', 'EUR', 0.75, 449, 4499, '${price}/maand'),
    ('BE', 'Belgium', 'EUR', 0.75, 449, 4499, '${price}/mois'),
    ('AT', 'Austria', 'EUR', 0.75, 449, 4499, '${price}/Monat'),
    ('IE', 'Ireland', 'EUR', 0.75, 449, 4499, '${price}/month'),
    ('FI', 'Finland', 'EUR', 0.75, 449, 4499, '${price}/kk'),
    ('PL', 'Poland', 'PLN', 0.70, 1999, 19999, '${price}/miesiąc'),
    ('CZ', 'Czech Republic', 'CZK', 0.70, 12999, 129999, '${price}/měsíc'),
    
    -- Tier 4: Middle income (40-50% discount)
    ('BR', 'Brazil', 'BRL', 0.55, 2499, 24999, 'R$ ${price}/mês'),
    ('MX', 'Mexico', 'MXN', 0.55, 9999, 99999, '${price}/mes'),
    ('AR', 'Argentina', 'ARS', 0.50, 99999, 999999, '${price}/mes'),
    ('CL', 'Chile', 'CLP', 0.55, 399990, 3999990, '${price}/mes'),
    ('CO', 'Colombia', 'COP', 0.55, 199990, 1999990, '${price}/mes'),
    ('ZA', 'South Africa', 'ZAR', 0.55, 9999, 99999, 'R ${price}/month'),
    ('MY', 'Malaysia', 'MYR', 0.55, 1799, 17999, 'RM ${price}/month'),
    ('TH', 'Thailand', 'THB', 0.55, 17999, 179999, '฿${price}/เดือน'),
    ('PH', 'Philippines', 'PHP', 0.55, 29999, 299999, '₱${price}/month'),
    ('ID', 'Indonesia', 'IDR', 0.50, 999990, 9999990, 'Rp ${price}/bulan'),
    ('VN', 'Vietnam', 'VND', 0.50, 1999990, 19999990, '${price}/tháng'),
    ('TR', 'Turkey', 'TRY', 0.50, 24999, 249999, '${price}/ay'),
    
    -- Tier 5: Lower middle income (55-65% discount)
    ('IN', 'India', 'INR', 0.40, 19999, 199999, '₹${price}/month'),
    ('NG', 'Nigeria', 'NGN', 0.35, 299990, 2999990, '₦${price}/month'),
    ('EG', 'Egypt', 'EGP', 0.35, 14999, 149999, 'E£${price}/شهر'),
    ('PK', 'Pakistan', 'PKR', 0.35, 99999, 999999, '₨${price}/month'),
    ('BD', 'Bangladesh', 'BDT', 0.35, 49999, 499999, '৳${price}/মাস'),
    ('KE', 'Kenya', 'KES', 0.35, 59999, 599999, 'KSh ${price}/month')

on conflict (country_code) do update set
    ppp_adjustment = excluded.ppp_adjustment,
    monthly_price = excluded.monthly_price,
    yearly_price = excluded.yearly_price,
    updated_at = now();

-- Function to get pricing for user's country
create or replace function public.get_pricing_for_country(p_country_code text default null)
returns jsonb as $$
declare
    v_country_code text;
    v_pricing jsonb;
begin
    -- Default to AU if not provided
    v_country_code := coalesce(p_country_code, 'AU');
    
    select jsonb_build_object(
        'country', country_code,
        'currency', currency_code,
        'monthly', monthly_price,
        'yearly', yearly_price,
        'monthlyDisplay', format_price(monthly_price, currency_code),
        'yearlyDisplay', format_price(yearly_price, currency_code),
        'yearlySavings', round((1 - (yearly_price::decimal / (monthly_price * 12))) * 100),
        'template', price_display_template
    )
    into v_pricing
    from public.pricing_by_country
    where country_code = v_country_code and is_active = true;
    
    -- Fallback to AU
    if v_pricing is null then
        select jsonb_build_object(
            'country', 'AU',
            'currency', 'AUD',
            'monthly', 599,
            'yearly', 6000,
            'monthlyDisplay', '$5.99/month',
            'yearlyDisplay', '$60/year',
            'yearlySavings', 17,
            'template', '${price}/month'
        )
        into v_pricing;
    end if;
    
    return v_pricing;
end;
$$ language plpgsql security definer;

-- Helper function to format price

create or replace function public.format_price(p_cents integer, p_currency text)
returns text as $$
begin
    return case p_currency
        when 'JPY' then '¥' || (p_cents / 100)
        when 'KRW' then '₩' || (p_cents / 100)
        when 'TWD' then 'NT' || (p_cents / 100)
        when 'INR' then '₹' || (p_cents / 100)
        when 'BRL' then 'R$ ' || round(p_cents / 100.0, 2)
        when 'ARS' then '$' || (p_cents / 100)
        when 'CLP' then '$' || (p_cents / 100)
        when 'COP' then '$' || (p_cents / 100)
        when 'MXN' then '$' || round(p_cents / 100.0, 2)
        when 'ZAR' then 'R ' || round(p_cents / 100.0, 2)
        when 'MYR' then 'RM ' || round(p_cents / 100.0, 2)
        when 'THB' then '฿' || (p_cents / 100)
        when 'PHP' then '₱' || (p_cents / 100)
        when 'IDR' then 'Rp ' || (p_cents / 100)
        when 'VND' then '' || (p_cents / 100) || '₫'
        when 'TRY' then '' || round(p_cents / 100.0, 2) || ' ₺'
        when 'GBP' then '£' || round(p_cents / 100.0, 2)
        when 'EUR' then '' || round(p_cents / 100.0, 2) || ' €'
        when 'CHF' then 'CHF ' || round(p_cents / 100.0, 2)
        when 'NOK' then '' || (p_cents / 100) || ' kr'
        when 'SEK' then '' || (p_cents / 100) || ' kr'
        when 'DKK' then '' || (p_cents / 100) || ' kr'
        when 'PLN' then '' || round(p_cents / 100.0, 2) || ' zł'
        when 'CZK' then '' || (p_cents / 100) || ' Kč'
        when 'ILS' then '₪' || round(p_cents / 100.0, 2)
        when 'NGN' then '₦' || (p_cents / 100)
        when 'EGP' then 'E£' || round(p_cents / 100.0, 2)
        when 'PKR' then '₨' || (p_cents / 100)
        when 'BDT' then '৳' || (p_cents / 100)
        when 'KES' then 'KSh ' || (p_cents / 100)
        else '$' || round(p_cents / 100.0, 2)
    end;
end;
$$ language plpgsql immutable;

comment on table public.pricing_by_country is 'Netflix-style PPP pricing by country. Base currency is AUD.';
comment on table public.user_subscriptions is 'User subscription status synced from RevenueCat';
comment on table public.user_upload_quota is 'Free tier upload quota tracking';
