# Project status

Updated: 2026-07-13

The backend supports PostgreSQL persistence, development identity, user profiles and targets, food search, draft meals, corrections, confirmation, dashboard summaries, and confirmed meal history. The Flutter client supports onboarding, profile/weight management, dashboard/history, camera/gallery capture, draft review, correction, and confirmation.

Real OpenAI image analysis is implemented server-side through the existing meal-vision abstraction. It requires an OpenAI key in .NET user secrets before it can be enabled. Mock analysis remains available only for deterministic testing and is visibly labeled as simulated in review.

Phase 11 adds persisted nutrient definitions/values, provenance/confidence, recipes, dietary preferences, hydration, fasting, and reminder data, together with a server-only curation-manifest guard. Phase 12 adds manual-meal drafts and an improved review summary. Exact repeat image bytes reuse the earlier persisted analysis, avoiding inconsistent repeat AI results while still creating a new editable draft.

Known limitations: temporary development identity remains in use; image retention is local development storage; real provider verification needs a user-supplied OpenAI key and a real meal image; recipe selection in the mobile UI, progress charts, local notification scheduling, and full offline replay/conflict UX remain in progress. Production authentication, cloud image storage, billing, and health integrations are not implemented.
