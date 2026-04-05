# Cooksy Auth Branding Setup

Cooksy now supports:

- `Continue with Apple`
- `Continue with Google`
- `Email code` fallback

To make the fallback email feel premium, update Supabase Auth in the dashboard.

## Redirect URLs

Add these redirect URLs in Supabase Auth:

- `https://cooksy-six.vercel.app/auth`
- `cooksy://auth`

When you move to a custom production domain, add:

- `https://your-domain.com/auth`

## Email Template

In Supabase:

1. Open `Authentication`
2. Open `Templates`
3. Edit the email OTP / magic link template
4. Use `{{ .Token }}` in the body so Cooksy users can enter the 6-digit code directly
5. Keep `{{ .ConfirmationURL }}` as the CTA link so the email still works when tapped

Suggested Cooksy email template:

```html
<div style="margin:0;padding:0;background:#fffdf7;font-family:-apple-system,BlinkMacSystemFont,'Inter','Segoe UI',sans-serif;color:#111111;">
  <div style="max-width:560px;margin:0 auto;padding:40px 24px;">
    <div style="display:flex;align-items:center;gap:12px;margin-bottom:24px;">
      <div style="width:44px;height:44px;border-radius:999px;background:#f5c400;color:#111111;font-weight:800;font-size:24px;line-height:44px;text-align:center;">8</div>
      <div style="font-size:28px;font-weight:800;letter-spacing:-0.02em;">Cooksy</div>
    </div>

    <div style="background:#ffffff;border:1px solid #efe5c8;border-radius:28px;padding:32px;box-shadow:0 20px 60px rgba(17,17,17,0.06);">
      <div style="font-size:14px;font-weight:700;letter-spacing:0.08em;text-transform:uppercase;color:#8a8478;margin-bottom:14px;">Create your profile</div>
      <h1 style="margin:0 0 12px 0;font-size:36px;line-height:1.05;letter-spacing:-0.04em;color:#111111;">Finish signing in to Cooksy</h1>
      <p style="margin:0 0 24px 0;font-size:17px;line-height:1.7;color:#5c5a55;">
        Save recipes to your account, sync across web and mobile, and keep your cooking history attached to you.
      </p>

      <div style="margin:0 0 24px 0;padding:18px 20px;border-radius:22px;background:#fff6cc;">
        <div style="font-size:13px;font-weight:700;letter-spacing:0.08em;text-transform:uppercase;color:#8a6b00;margin-bottom:8px;">Your Cooksy code</div>
        <div style="font-size:36px;font-weight:800;letter-spacing:0.18em;color:#111111;">{{ .Token }}</div>
      </div>

      <a href="{{ .ConfirmationURL }}" style="display:inline-block;background:#111111;color:#ffffff;text-decoration:none;padding:16px 24px;border-radius:999px;font-size:16px;font-weight:700;">
        Open Cooksy
      </a>

      <p style="margin:24px 0 0 0;font-size:14px;line-height:1.8;color:#7a766d;">
        If the button doesn’t work, copy the 6-digit code into Cooksy manually. This code is only for your account and will expire shortly.
      </p>
    </div>
  </div>
</div>
```

## Provider Setup

For launch-quality auth, configure these providers in Supabase:

- Apple
- Google

Cooksy uses Supabase as the identity source of truth and RevenueCat uses the Supabase user id for subscription identity.
