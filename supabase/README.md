# Cooksy Supabase Hardening

The Supabase security warning showed two critical issues in project
`qirjjbmrgtailifhmakp`:

- `rls_disabled_in_public`
- `sensitive_columns_exposed`

`migrations/20260603000000_enable_rls_and_owner_policies.sql` was applied to
the live Supabase project on 3 June 2026. It enables and forces Row Level
Security on public tables, removes broad anonymous table access, and adds
owner-based policies for Cooksy user data.

Supabase Security Advisor now confirms the two critical issues are gone. The
remaining notices are warnings for signed-in GraphQL visibility on recipe tables
and leaked password protection.
