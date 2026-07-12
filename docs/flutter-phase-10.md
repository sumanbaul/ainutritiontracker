# Flutter Phase 10 — Meal capture and review

Phase 10 adds camera and gallery image selection, local JPEG/PNG/WebP and 5 MB validation, multipart upload to `POST /api/meals/analyse`, persisted draft review, correction/removal, and confirmation. The mobile app never contains AI provider credentials; the backend selects Mock or a configured production provider.

Development can enable `ENABLE_MOCK_MODE=true` to expose deterministic meal-vision scenarios. Uploaded images are retained by the development backend for draft review under its existing `MealAnalysis:RetainImages=true` policy.

Capture errors map HTTP 400, 401, 413, 415, 502, and 504 responses to readable messages. Confirmation returns the user to Today; confirmed meal totals then appear through the existing dashboard and history APIs.
