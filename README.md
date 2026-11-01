# nurlyhome

Starter implementation of a student housing platform for Kazakhstan. The current UI is bilingual-ready for Russian, Kazakh and English and works without external accounts in a clearly marked **illustrative demo mode**. Demo listings are not real properties and cannot be booked.

## Stack

- Next.js App Router + TypeScript
- Supabase Auth and PostgreSQL with versioned SQL/RLS migration
- CSS design system with persistent browser theme preference

## Local setup

1. Install Node.js 20.9+.
2. Copy `.env.example` to `.env.local`.
3. Run `npm install` and `npm run dev`.
4. Visit `http://localhost:3000` (redirects to `/ru`).

Without Supabase credentials, public pages use conspicuously labelled sample listings; authentication, host submission, persistent listings and booking requests remain unavailable. There is no fake login or fake successful payment.

## Supabase setup

1. Create a Supabase project and configure Auth email confirmation and redirect URLs (`http://localhost:3000/**` plus your production origin).
2. Put the project URL and anon/publishable key into `.env.local` as `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`.
3. Apply every SQL file in `supabase/migrations/` in filename order using Supabase CLI or SQL editor. This includes the initial schema and the review-rating aggregate migration.
4. For the first platform owner only, assign `profiles.role='super_admin'` from the trusted SQL editor after creating that user. Never expose the service-role key in browser code or allow user input to set roles.
5. Configure storage buckets/policies before enabling property photo uploads (upload UI is not enabled yet).

The migrations include profiles, host applications, reviewed dorms, manager membership, floors/rooms/beds, date-overlap-safe booking requests, payment records, review/notification/audit tables, review-derived rating aggregates, and RLS. Booking creation uses a PostgreSQL exclusion constraint so concurrent requests cannot claim overlapping bed dates. Manager/admin state changes use server RPCs with role checks. Apply all migrations to a disposable project first and review them before production.

## What is implemented now

- Responsive home, listing catalog with translated filters (including multi-select amenities, distance, rating and availability), sorting, dorm detail pages and mobile layouts.
- Russian/Kazakh/English interface foundations, saved locale in URL, saved light/dark theme.
- Supabase email/password sign-up/sign-in and server-side session handling when configured. Supabase sends verification email according to project Auth settings.
- Host application submission; platform-owner review RPC creates an approved listing and manager membership atomically.
- Manager dashboard with an atomic basic floor/room/bed generator and booking decision/check-in/check-out actions.
- Student account view with editable profile fields, server-side booking requests, cancellation, and post-checkout verified-stay review submission/display. Payment history displays only real database records; no payment collection is enabled.
- RLS and database constraints keep manager data scoped and prevent self-assigned privileged roles.

This is an initial implementation, not yet the entire requested production service. In particular, there is no verified payment-provider integration, transactional email service integration beyond Supabase Auth email, account deletion/deactivation workflow, photo/document upload, review moderation/reporting UI, complete accessibility audit, or exhaustive platform statistics. Password recovery routes exist but require configured Supabase Auth email to work. Profile fields can be edited, but broader account lifecycle/settings are still incomplete. These should not be represented as live features.

## Payments and legal readiness

No provider has been selected or connected. Kaspi Pay or another Kazakhstan provider must be evaluated for marketplace/connected-account payouts, contracts, merchant onboarding, webhook signing, refund support and settlement semantics. Until credentials, provider agreement, signed webhook verification and reconciliation are implemented and tested, booking requests cannot be paid through Nurlyhome and status must not be treated as paid. Never collect/store card numbers. Cancellation/refund language needs review under Kazakhstan consumer-protection law before launch.

## Email and production readiness

Supabase Auth email verification uses the project's configured SMTP; configure a production SMTP provider, sender domain, templates and rate limits. For transactional notifications, connect a separately configured email provider. Before launch, also configure production secrets, backups, monitoring, privacy/legal copy, retention/account-deletion processes, storage policies, abuse protections and end-to-end tests including concurrent booking attempts and payment webhook replay.
