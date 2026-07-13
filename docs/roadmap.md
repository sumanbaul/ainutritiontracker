# Roadmap

| Milestone | Status |
|---|---|
| Backend foundation, PostgreSQL, profiles, food data, meal drafts, confirmation, dashboard | Complete |
| Flutter foundation and cyberpunk product screens | Complete |
| Phase 10 capture, draft review, corrections, confirmation | Complete |
| Phase 10 real OpenAI meal vision and zero-flag developer workflow | Complete foundation; provider credentials remain environment-specific |
| Phase 11 nutrition/recipe/habit data foundation | Complete foundation |
| Phase 12 manual meal logging and review improvements | Complete foundation; custom recipe mobile UX remains a later enhancement |
| Phase 13 progress and habit mobile product | Complete |
| Reference-matched adaptive UI, secure meal imagery, and 12-month history activity calendar | Complete |
| Phase 14 offline replay and conflict UX | Planned |
| Production authentication and authorization | Next after these milestones |
| Production image storage, observability, deployment hardening | Planned |

The next planned milestone is Phase 14: reliable offline replay, server idempotency/version checks, and conflict-resolution UX. Production authentication follows before any public multi-user release.
# Phase 14

Phase 14 adds production JWT authentication, ownership enforcement, secure token refresh, user-scoped Drift replay primitives, version conflicts, S3-compatible private images, recipe selection/logging, account export/deletion, PostgreSQL CI, and release signing templates. Remaining production operations are listed in `docs/phase-14.md`.
# Phase 15 - MVP integrity and self-hosting

Current work makes nutrition matching explicit, blocks confirmation of unresolved foods, and supports protected local image retention for self-hosted deployments. See [Phase 15](phase-15.md). Catalog expansion, deterministic candidate ranking, broader verified food sources, and clinician-review workflows remain the next data-quality milestone.
