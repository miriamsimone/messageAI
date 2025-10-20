## messageAI MVP Implementation Plan

1. **Phase 0 – Foundations**
   - Audit the current Xcode project structure and dependencies.
   - Configure Firebase (Auth, Firestore, Storage, Cloud Functions, FCM) and centralize environment management.
   - Establish SwiftData schemas that mirror PRD data models as the local source of truth.

2. **Phase 1 – Accounts & Identity**
   - Implement email/password onboarding with persistent sessions.
   - Enforce unique usernames via client validation and Firestore security rules.
   - Provide editable profile settings and logout/account state handling.

3. **Phase 2 – Contacts & Discovery**
   - Build username search backed by indexed Firestore queries.
   - Add contact add/remove flows with limited-profile gating.
   - Deliver contact list UI states including empty/loading/error scenarios.

4. **Phase 3 – Core Messaging Layer**
   - Define conversation and message repositories backed by SwiftData.
   - Wire Firestore listeners with optimistic writes and delivery state tracking.
   - Create conversation list and one-on-one chat views with timestamps, unread badges, pagination, and local caching.

5. **Phase 4 – Group Chat Enablement**
   - Extend data layer for group metadata (name, avatar, participants).
   - Support group creation, editing, and participant management.
   - Adapt chat UI for message attribution and membership updates.

6. **Phase 5 – Presence & Receipts**
   - Integrate presence tracking (online/offline, last seen) and typing indicators through lightweight listener channels.
   - Add delivery-to-read state transitions with UI affordances for one-on-one and group conversations.

7. **Phase 6 – Media Handling**
   - Implement image picker/camera workflows with thumbnail generation and caching.
   - Upload images to Firebase Storage with retry logic and local reference updates.
   - Support profile photo updates using the same media pipeline.

8. **Phase 7 – Resilience & Offline**
   - Build persistent message queuing for offline sends with retry/backoff strategies.
   - Surface connectivity banners and actionable error messaging.
   - Harden force-quit recovery flows and handle rate-limit responses gracefully.

9. **Phase 8 – Notifications**
   - Register and manage FCM tokens per user session.
   - Deliver foreground notifications with deep links into conversations.
   - Scaffold background and terminated-state handling as stretch goals.

10. **Phase 9 – QA & Tooling**
    - Codify the nine MVP scenarios into manual and, where feasible, automated test plans.
    - Add diagnostics/logging hooks to observe messaging reliability.
    - Validate performance targets (latency, launch, load times) under constrained network conditions.

11. **Phase 10 – Release Prep**
    - Resolve build warnings, verify Firebase security rules, and run final regression pass.
    - Prepare TestFlight distribution pipeline and collect stabilization feedback.
    - Document launch readiness checklist for the MVP checkpoint review.
