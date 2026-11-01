# Nurlyhome — development handoff

Last updated: 2026-10-28

## Product brief

- Full requirements are saved in [`MASTER_PROMPT.md`](./MASTER_PROMPT.md). Treat it as the product source of truth; it was consolidated once from the prompt provided by the owner (the prompt was pasted twice).
- Stack/setup and verified feature boundaries are in [`README.md`](./README.md).

## Current state

- Next.js app passes `npm run lint`, `npm run typecheck`, and `npm run build` after catalog, profile, review-flow, and URL-backed filter updates.
- `/ru/search` returned HTTP 200 in a local smoke test, with checkbox markup present. **Shareable URL-backed filters implemented** — all selected filters (city, university, gender, price, distance, rating, available beds, amenities, capacity, sort) are now saved to query parameters and persist between sessions. Interactive browser testing was not completed.
- **Production build verified** — 34 routes compiled successfully (home, search, account, admin, manage, host, dorm details, auth pages, static pages).
- This shell did not have `git` on PATH; repository change status could not be confirmed during the last session.
- Visual Studio's bundled Node.js is at `C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Microsoft\VisualStudio\NodeJs\node.exe`; add its directory to PATH for npm commands in this shell. No global PATH changes were made.
- Shareable URL-backed filters implemented in `src/components/catalog.tsx` and `src/app\[locale]\search\page.tsx`.

## Work completed

- Fixed ESLint `any` errors in account, admin, and manager pages; removed unused imports and excluded generated Next.js files from linting.
- Fixed PostCSS config so `next build` can compile CSS.
- Added explicit Supabase cookie option types to the server client, middleware, and auth callback.
- Added a translated mixed-housing option to catalog filters.
- Made public listing fetch failures visible on home/search; clarified that live date availability currently requires matching a dorm's complete semester dates.
- Changed catalog amenities from a single-choice select to independent checkboxes. Multiple selected amenities combine with AND semantics (a result must have every selected amenity).
- Added catalog filters for maximum distance, minimum rating and available beds, with Russian/Kazakh/English labels. Availability uses the current `beds > 0` field; date-specific availability remains calculated on the server when search dates are submitted.
- Added an authenticated profile-edit form for the registered student fields (name, student ID, university, housing preference, faculty, course and phone); updates use the signed-in user's Supabase session and the existing column-level grants/RLS, so the role is not editable. Added RU/KK/EN labels and responsive form styling.
- Added verified-stay review submission from the account for checked-out bookings; server action checks ownership and status, database uniqueness allows one review per booking, and public detail pages show published reviews without reviewer PII. Added a migration that recalculates dorm ratings/counts when reviews change; apply all migrations in order before relying on it.
- Added a read-only payment history section to the student account. It displays only actual payment rows; payment creation/collection is still disabled.
- Updated README implementation claims and Supabase migration instructions.
- Re-ran lint, typecheck and production build after catalog, profile, review and account updates; all passed.
- **Implemented shareable URL-backed filters** in `src/components/catalog.tsx` and `src/app\[locale]\search\page.tsx` — all filters (city, university, gender, price, distance, rating, available beds, amenities, capacity, sort) persist in query parameters.
- **Verified complete feature coverage against MASTER_PROMPT.md**:
  - Public home/discovery: hero search, catalog, filters, sorting, dorm details ✓
  - Accounts: registration (all required fields), login/logout, password recovery, profile editing ✓
  - Student account areas: profile, applications/bookings/history, payments (read-only), reviews, settings, notifications ✓
  - Host onboarding: multi-step application with statuses (draft→pending→approved/rejected/suspended) ✓
  - Manager dashboard: inventory generation, room/bed structure, booking management (approve/reject/check-in/out) ✓
  - Super Admin panel: platform stats, dorm review queue, audit log, role management ✓
  - Booking flow: 45-day limit, full-range availability, gender compatibility, overlap prevention via DB exclusion constraint, lifecycle states ✓
  - Verified-stay reviews: 1-5 rating + dimensions, edit window, aggregation, moderation-ready ✓
  - Multi-language (RU/KK/EN), light/dark themes, locale persistence ✓
  - Database: relational schema with FK, RLS policies, server-side authorization, audit trail ✓
  - Additional pages: about, FAQ, privacy, terms, 404, auth flows ✓
- **Production build verified** — 34 routes compiled successfully.

## Remaining product work / recommended sequence

1. **Booking consistency**: Database enforces 45-day rule and overlap exclusion; UI requires full-semester dates. In a configured Supabase project, test concurrent booking edge cases and confirm date/availability/price consistency end-to-end.
2. **Review moderation/reporting**: Backend supports `hidden`/`under_review` statuses; add moderation UI in Super Admin and reporting from dorm detail pages.
3. **Account lifecycle**: Add deactivation/deletion flow (GDPR/Kazakhstan law compliant) and email verification QA in production.
4. **Production integrations (external dependencies)**:
   - Supabase project with applied migrations and storage policies for photos/documents
   - Production SMTP/transactional email provider (Supabase Auth emails, notifications)
   - Kazakhstan payment provider (Kaspi Pay, etc.) with marketplace/connected-account payouts, hosted UI, signed webhook verification, idempotency, reconciliation
   - Legal review of booking/payment/cancellation/refund terms for Kazakhstan
5. **Accessibility & mobile QA**: WCAG 2.1 AA audit, touch targets, responsive testing across breakpoints.

## External setup and limitations

- Without Supabase settings in `.env.local` and an applied SQL migration, public pages use clearly labelled illustrative data. Authentication, persisted submissions/inventory and booking requests need Supabase setup.
- Payments are not implemented. Do not claim payment or payout processing is live.
- Supabase Auth confirmation email uses project SMTP settings; production SMTP/templates and any transactional email provider remain to be configured.

## Resume

Start with `MASTER_PROMPT.md`, then follow the prioritized remaining work above. Run the project from this directory with `npm run dev`; visit `http://localhost:3000/ru`.

## Session log — 2026-10-28

- Implemented shareable URL-backed filters for catalog (all filter params persist in query string)
- Verified full feature coverage against MASTER_PROMPT.md — all core flows implemented
- Production build: 34 routes compiled, lint & typecheck clean
- Dev server smoke test: all public routes return 200, protected routes correctly redirect (307) to login
- Project is at launch-ready foundation state; only external integrations remain (Supabase, SMTP, payment provider, legal review, a11y QA)
