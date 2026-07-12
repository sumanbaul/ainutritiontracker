# Project status

Updated: 2026-07-13

The backend supports PostgreSQL persistence, development identity, user profiles and targets, food search, draft meals, corrections, confirmation, dashboard summaries, and confirmed meal history. The Flutter client supports onboarding, profile/weight management, dashboard/history, camera/gallery capture, draft review, correction, and confirmation.

Real OpenAI image analysis is implemented server-side through the existing meal-vision abstraction. It requires an OpenAI key in .NET user secrets before it can be enabled. Mock analysis remains available only for deterministic testing and is visibly labeled as simulated in review.

Known limitations: temporary development identity remains in use; image retention is local development storage; real provider verification needs a user-supplied OpenAI key and a real meal image; production authentication, cloud image storage, billing, health integrations, and offline sync are not implemented.
