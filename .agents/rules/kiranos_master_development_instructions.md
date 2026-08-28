# KIRANOS — MASTER DEVELOPMENT INSTRUCTIONS

Apply these instructions to EVERY future implementation phase.

The application is a production-grade Flutter mobile/tablet Kirana Store Management + POS application using Supabase/PostgreSQL and local offline storage.

==================================================

1. INSPECT BEFORE IMPLEMENTING
==================================================

Before changing anything:

• Inspect the complete existing project structure.
• Inspect Flutter framework, dependencies and configuration.
• Inspect routing and navigation.
• Inspect screens, widgets, layouts and design system.
• Inspect state management.
• Inspect repositories/services/data sources.
• Inspect Supabase configuration.
• Inspect the ACTUAL Supabase database.
• Inspect tables, columns, relationships, constraints, indexes,
RLS policies, Storage buckets, RPCs, triggers and migrations.
• Inspect Drift/local database schema.
• Inspect existing authentication and authorization.
• Inspect existing offline/synchronization architecture.
• Inspect existing tests.

Do NOT assume that the code and Supabase database are synchronized.

Search for actual feature usage, not only filenames.

==================================================
2. SMALL INCREMENTAL IMPLEMENTATION
===================================

Implement ONLY 1–4 small, closely related features per phase.

Do NOT create unnecessarily large prompts or giant feature batches.

Do NOT rewrite working functionality.

Do NOT replace existing architecture unless there is a verified
technical reason.

Reuse existing:

• screens
• widgets
• repositories
• services
• models
• providers/controllers
• database helpers
• design tokens
• navigation
• animations
• utilities

Avoid duplicate business logic.

==================================================
3. REAL SUPABASE — MANDATORY
============================

For EVERY feature involving data:

FIRST inspect the REAL Supabase database.

Verify:

• tables
• columns
• data types
• relationships
• foreign keys
• unique constraints
• indexes
• RLS
• Storage
• RPC/functions
• triggers
• migrations
• Realtime
• existing records

If schema changes are required:

→ Create a proper migration.

Never create a second/duplicate table because the existing
schema was not inspected.

After implementation verify:

Flutter
→ Repository/Service
→ Supabase
→ PostgreSQL
→ RLS
→ Drift/cache
→ UI

Everything must work simultaneously.

==================================================
4. SECURITY
===========

Never trust the Flutter client for sensitive business logic.

Enforce authorization at the backend/database level.

Verify:

• authenticated user
• shop ownership
• membership/role
• permissions
• RLS
• shop isolation
• record ownership

Never trust client-provided:

• shop_id
• user_id
• final price
• final tax
• final discount
• final payment amount
• inventory quantity
• financial totals

Sensitive calculations and financial transactions must be
validated server-side.

Never expose:

• secrets
• API keys
• service-role keys
• database credentials
• stack traces
• internal paths
• raw PostgreSQL/Supabase errors
• sensitive user information

==================================================
5. MULTI-SHOP ISOLATION
=======================

Every shop-owned record must remain isolated.

Test:

Shop A
→ Access Shop B data

Expected:

DENIED / NO DATA.

Never rely only on Flutter route guards.

Supabase RLS must enforce isolation.

==================================================
6. OFFLINE-FIRST BEHAVIOR
=========================

The app must remain useful when internet connectivity is lost.

Use the existing Drift/local architecture.

Offline functionality should be implemented only where it is
safe and supported.

Provide:

• offline detection
• cached data
• safe local drafts
• pending synchronization where supported
• retry
• synchronization status
• last updated timestamp

Never pretend that unsynchronized data is already stored on
Supabase.

Never show "success" for a server operation that has not actually
completed.

For financial transactions, use safe synchronization and
idempotency.

Never blindly overwrite server data after reconnecting.

==================================================
7. NETWORK + ERROR HANDLING
===========================

Every network/database feature must handle:

• no internet
• timeout
• server failure
• database failure
• RLS rejection
• session expiration
• stale data
• duplicate submission
• invalid input
• unexpected response

Never crash the application.

Show human-readable recovery messages.

Provide appropriate actions:

• Retry
• Try Again
• Go Back
• Sign In Again
• Continue Offline
• Return Home

Preserve entered form data after recoverable errors where safe.

==================================================
8. REQUIRED UI STATES
=====================

Use reusable components wherever possible.

Every applicable screen should support:

• Loading
• Empty
• No Search Results
• Error
• Offline
• Success
• Permission Denied
• Session Expired

For native Flutter, use mobile-appropriate equivalents instead
of blindly copying web concepts such as 404 pages.

==================================================
9. NAVIGATION
=============

Every implemented feature must be reachable through the REAL app.

Verify:

• route registration
• navigation
• back navigation
• deep navigation where applicable
• protected routes
• unauthorized access
• session-expiration navigation

Do NOT create orphan screens.

Do NOT create fake navigation buttons.

==================================================
10. AUTHENTICATION
==================

Authentication must be real and end-to-end.

Support existing configured methods such as:

• Email/password
• Google/Gmail OAuth

where already implemented.

Verify:

Register
→ Supabase Auth
→ User/profile record
→ Login
→ Session
→ Profile loading

Forgot password must have real backend support.

Password reset must be:

• secure
• expiring
• single-use
• invalidated after use
• protected against account enumeration

Never store plaintext passwords.

Never create fake authentication.

==================================================
11. USER PROFILE
================

After registration, all supported user/profile information must
persist correctly.

Login
→ Authenticated user
→ Profile
→ Shop
→ Permissions
→ User-specific data

Everything must load from the correct source.

Profile updates must persist to the actual database.

==================================================
12. DATABASE CONSISTENCY
========================

Whenever a feature changes data:

Verify the actual Supabase record after the operation.

Example:

Flutter action
→ Supabase mutation
→ PostgreSQL record
→ Read back
→ Flutter UI
→ Drift/cache update

Do not consider a feature complete merely because the UI changes.

==================================================
13. FINANCIAL DATA
==================

For:

• sales
• bills
• payments
• discounts
• taxes
• inventory
• purchases
• returns
• credit/Udhaar

use authoritative server-side/database logic.

Transactions must be atomic where required.

Either:

ALL operations succeed

or:

NONE succeed.

Never allow:

• payment without bill
• bill without bill items
• inventory deduction without valid sale
• partial financial transaction
• duplicate payment
• duplicate checkout

Historical bills must preserve their original values.

Future product/customer changes must NOT rewrite historical
financial information.

==================================================
14. PRODUCT IMAGES / STORAGE
============================

When product images are applicable:

• Use Supabase Storage or the existing verified storage system.
• Verify bucket configuration.
• Verify Storage RLS/policies.
• Validate file type.
• Validate file size.
• Handle upload failure.
• Show upload progress where appropriate.
• Generate/use optimized image URLs.
• Cache images safely.
• Handle missing/deleted images.

Never expose private storage data incorrectly.

==================================================
15. REALTIME
============

Where Realtime is applicable:

Supabase change
→ Repository
→ Local cache
→ UI

Avoid duplicate subscriptions.

Clean up subscriptions correctly.

Test multi-device behavior where applicable.

==================================================
16. ACCESSIBILITY
=================

Implement accessibility appropriate for Flutter:

• semantic labels
• readable typography
• sufficient contrast
• accessible buttons
• appropriate touch targets
• screen-reader support
• accessible dialogs
• meaningful error messages
• non-color-only status indicators
• reduced-motion support where animations are used

Do NOT claim WCAG/accessibility compliance unless actually audited.

==================================================
17. RESPONSIVE DESIGN
=====================

Support the intended device sizes:

• Android phones
• tablets

Maintain:

• consistent spacing
• typography
• touch targets
• readable layouts
• keyboard behavior
• safe areas

Do not allow overflow or clipped content.

==================================================
18. ANIMATION
=============

Use the existing animation architecture and installed packages.

Animations must be:

• subtle
• fast
• purposeful
• performance-friendly

Never sacrifice POS speed for visual effects.

Respect reduced-motion preferences where applicable.

==================================================
19. LEGAL / POLICY PAGES
========================

Only implement legal pages that genuinely apply to KIRANOS.

Potentially applicable:

• Privacy Policy
• Terms of Service
• Refund Policy
• Return/Exchange Policy
• Security Policy
• Accessibility Statement
• Disclaimer

Do NOT automatically add:

• Subscription pages
• Upgrade/Downgrade
• Shipping policy
• Cookie preference systems
• Community guidelines
• DPA
• SaaS billing pages

unless the actual application requires them.

Never invent:

• company legal name
• address
• support email
• refund rules
• retention periods
• jurisdiction
• guarantees
• compliance certifications

If factual/legal information is missing, flag it instead of
inventing it.

==================================================
20. TOP-APP QUALITY
===================

Every feature should feel like a serious production retail app.

Prioritize:

• fast interaction
• clear hierarchy
• predictable navigation
• minimal unnecessary steps
• reliable data
• offline resilience
• excellent empty states
• excellent error recovery
• secure authorization
• clean UI
• consistent components
• responsive design

Do not add features simply because they exist in other apps.

Only implement features that genuinely make sense for a Kirana
store/POS workflow.

==================================================
21. TESTING
===========

After every phase run all relevant checks available in the project:

• dart format
• flutter analyze
• unit tests
• widget tests
• integration tests
• database tests
• production build

For applicable features test:

• happy path
• invalid input
• empty state
• loading state
• error state
• offline state
• authorization
• RLS
• session expiration
• duplicate submission
• network recovery
• real Supabase data

If a test was not run:

DO NOT claim it passed.

Report:

PASSED
FAILED
NOT_RUN

accurately.

==================================================
22. REAL DEVICE VERIFICATION
============================

Where possible, test on a REAL Android device.

Verify:

• navigation
• touch interaction
• keyboard
• camera
• barcode scanning
• image upload
• offline behavior
• network recovery
• authentication
• database synchronization
• animations
• screen sizes

==================================================
23. PRODUCTION AUDIT
====================

For major milestones, inspect:

• authentication
• authorization
• database
• RLS
• Storage
• Realtime
• offline synchronization
• navigation
• error handling
• environment configuration
• build configuration
• tests

Create/update:

docs/PRODUCTION_PAGE_AUDIT.md

Use evidence-based statuses:

EXISTS_AND_ADEQUATE
EXISTS_NEEDS_IMPROVEMENT
APPLICABLE_MISSING
NOT_APPLICABLE
BLOCKED_BY_MISSING_INFORMATION

Every decision must include evidence such as:

• file path
• route
• database table
• API/RPC
• dependency
• configuration
• implementation behavior

==================================================
24. DEFINITION OF DONE
======================

A feature is NOT complete merely because:

✗ UI exists
✗ Button exists
✗ Screen opens
✗ Mock data appears

A feature is complete only when:

✓ UI exists
✓ Navigation works
✓ Business logic works
✓ Supabase works
✓ PostgreSQL data is correct
✓ RLS is verified
✓ Drift/offline behavior works where applicable
✓ Error handling works
✓ Loading/empty/success states work
✓ Real data is used
✓ Tests pass
✓ Real-device behavior is verified where possible

==================================================
25. FINAL REPORT AFTER EVERY PHASE
==================================

Return:

1. FEATURES IMPLEMENTED
2. FILES MODIFIED
3. SUPABASE DATABASE CHECK
4. MIGRATIONS
5. RLS/SECURITY CHECK
6. OFFLINE CHECK
7. REALTIME CHECK
8. TEST RESULTS
9. REAL DEVICE RESULT
10. FAILED / NOT_RUN CHECKS
11. REMAINING BLOCKERS

Use factual status only.

Never say:

"Everything is production-ready"

unless it has actually been verified.

==================================================
FINAL RULE
==========

Implement the current small feature completely.

Do not jump to the next unrelated feature.

Do not rewrite working code unnecessarily.

Do not fabricate missing backend functionality.

Do not fabricate Supabase tables.

Do not fabricate legal/business information.

Do not create fake buttons.

Do not leave broken navigation.

Do not leave UI-only implementations.

After completing this phase, STOP.
