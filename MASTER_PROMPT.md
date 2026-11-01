# MASTER PROMPT — NURLYHOME

## Purpose and product
Build **nurlyhome**, a modern, scalable student-dorm search, comparison, application, booking and management platform for Kazakhstan. This is intended to become a real service, not just a landing page or a mockup. Implement usable end-to-end user flows. Where external credentials, contracts or services are required, prepare integration points and state clearly what is still needed. Never claim a service is live when it is not.

## Visual design and languages
- Commercial-quality, minimal UI comparable in polish to Airbnb/Booking.com; responsive desktop/tablet/mobile; good typography, spacing, clear hierarchy, quality photos and restrained animations.
- Temporary text mark `nurlyhome`, with room for a future logo; do not make a final logo a requirement.
- Light/dark themes with persistent preference.
- Russian, Kazakh and English throughout the UI, forms, errors, statuses, notifications and admin areas; language selector in the header, locale preserved between navigation and visits; do not mix languages on a page.

## Public home and discovery
- Header: brand, search, host connection, locale/theme controls, sign-in/register and authenticated profile menu.
- Hero search: city, university, move-in/out dates; results account for all criteria and date availability.
- Home sections: popular/new/high-rated dorms, benefits, booking steps and host CTA.
- Clearly label illustrative sample data; never invent real universities, addresses or reviews.
- Catalog filters: city, university, gender, semester price, distance, beds per room, multiple amenities, available beds, rating. Filters must affect results and provide a clear empty state.
- Sorting: price, rating, popularity and distance.
- Dorm details: name/location/address, university/distance, gender, photo gallery, description/rules/amenities/pricing, availability, verified ratings/reviews, publicly approved manager info and a choose-bed CTA. Never expose other students' personal data.

## Accounts and student area
- Roles: student, dorm manager, platform Super Admin. Public registration only creates students; managers join through the host onboarding process; Super Admin assignment is owner-controlled and server-protected.
- Student registration fields: legal name, email, password, student ID, university, faculty, course and phone. Validate required fields; support verified email, secure password storage, login/logout, duplicate-email protection, understandable errors, password recovery, profile edits and password changes.
- Student account areas: profile, applications/bookings/history, payments, reviews, settings and notifications. Show each request's current state, dorm/bed/dates/cost; notify on decisions, payment and stay changes.

## Host onboarding and dorm operations
- Owner/manager submits dorm details (city/address/university/gender/prices/term/rules/amenities/contact/photos) for review. Statuses: draft, pending review, corrections requested, approved, rejected, suspended. Pending/rejected properties are not public or bookable. Super Admin decision grants manager access only to approved properties.
- Managers/team members may access only explicitly assigned dorms. Manage listing/photos, gender, prices/term dates, rules, floors/rooms/beds, applications, check-in/out, residents, history, reviews under platform policy, payment setup, statistics and own profile. Public manager details only when they consent.
- Generate floors/rooms/beds from manager-defined counts and numbering; allow manual edits. Room data: number, floor, description/photos, bed count, amenities, price, availability. Each bed has a unique ID, floor/room/bed number and state; allow closure for maintenance.
- Dorm admin dashboard: rooms/beds/free/occupied counts, pending review/payment requests, residents, recent bookings and date-range metrics. Add search/filter/sorting/pagination where useful.

## Availability and booking
- No graphical floor plan. List available beds grouped by floor and room; show room photos, amenities and price. For selected dates, hide occupied/closed beds and check availability for the entire interval.
- Student flow: find dorm → choose dates → inspect available beds → select a bed → see total/terms → submit request → manager review → pay after approval → booking confirmation → manager check-in/out.
- Move-in must be no more than 45 days ahead. Validate dates, property rules, student/dorm gender compatibility, full-range availability and conflicts. Support semester terms and show the correct price before submission.
- Prevent concurrent double booking using database-enforced transactional constraints, not UI-only checks.
- Keep application, payment and occupancy states distinct. Booking lifecycle: draft, pending review, approved, rejected, awaiting payment, paid/confirmed, checked in, checked out, cancelled. Display rejection reason when supplied.
- Allow cancellation before payment. Clearly show cancellation/refund policy before payment; do not charge without explicit confirmation. Paid refund rules require legal review for Kazakhstan.

## Payments, email and notifications
- Do not fake payment. Assess Kaspi Pay/other Kazakhstan providers, especially marketplace/connected-account payouts and direct settlement to dorms. Use hosted/provider-secure payment UI, server-verified signed webhooks, idempotency, failed/incomplete states, receipts and reconciliation. Never store card details or mark paid based only on browser return. Document keys/contracts/onboarding needed.
- In-app notifications for students and managers on request, decisions, payment and check-in/out; prepare email integration and clearly state provider/SMTP setup needed if not active.

## Platform administration and reviews
- Super Admin panel restricted to authorized owner: platform stats; dorms/onboarding; users/managers; bookings; complaints/reviews; analytics/settings; audit log. Show students, approved/pending dorms, bookings, active stays and successful payments. Allow approve/reject/suspend and appropriately scoped account management; never expose or arbitrarily change payment secrets. Audit consequential actions.
- Reviews only from verified stays; rating 1–5 plus text and dimensions (cleanliness, living conditions, amenities, accuracy); permitted edit window; average/count and sorting; report/moderation workflow. Prevent fake/multiple reviews and unjustified manual rating edits.

## Database and security
- Persistent relational entities and foreign keys for users/profiles, managers, dorms/onboarding, cities/universities, floors/rooms/beds, booking applications/bookings, payments, reviews, notifications, reports, audit history and settings.
- Server-side authorization and input validation; tenant isolation between dorms; no role escalation via form/URL/request; secure auth and recovery; payment integrity; minimal personal data and no public student PII; secure storage policies for photos/documents; account deactivation/deletion path suitable for applicable law.

## Additional pages
About, how it works, for dorm owners, FAQ, contacts/support, terms, privacy, booking/payment terms, 404, login, registration and recovery.

## Delivery and acceptance checks
Implement consistent, working flows across the application; no dead UI, fake auth, fake payments or misleading persistence. Document external setup and limitations. Validate registration/login/recovery, role authorization, host submission/approval, room inventory generation, search/filters, date-aware booking, double-book protection, manager decisions, payment/webhook status, check-in/out, verified reviews, both admin areas, locales/themes and mobile layouts.

**Target:** a convenient, scalable and launch-ready foundation for students, universities and dorm operators, with all external dependencies and remaining launch steps stated honestly.
