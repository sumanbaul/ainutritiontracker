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
| Phase 14 authentication, offline replay primitives, and conflict UX | Complete |
| Phase 15 MVP integrity, Local self-hosted storage, and deployment hardening | Complete |
| Local MCP image preflight gate and provider-call protection | Complete |
| Discover Meals catalog, seven-day plan, safety filtering, saves, and shopping-list foundation | Complete foundation |
| Automatic conservative food resolution and resolution audit | In progress |
| Opt-in anonymized community validation swipe game | Future phase |

The next work should be a deliberately scoped post-MVP data-quality milestone: broader verified food coverage, catalog curation, and nutrition-source review. It must not bypass the current unresolved-item confirmation safety policy.

## Future: opt-in community validation game

Confirmed meals may later contribute anonymized, opt-in validation tasks. A card will contain one proposed fact (for example, “This portion is 20 g of pickle”); swipe right confirms and swipe left rejects. Users never see their own meal, identifiers, account data, or images without explicit consent. Tasks and responses will be stored separately from meals; aggregate consensus becomes a curator-review candidate only and never changes the shared catalog automatically. User-private foods remain user-scoped unless a curator explicitly promotes them.
# Phase 14

Phase 14 adds production JWT authentication, ownership enforcement, secure token refresh, user-scoped Drift replay primitives, version conflicts, S3-compatible private images, recipe selection/logging, account export/deletion, PostgreSQL CI, and release signing templates. Remaining production operations are listed in `docs/phase-14.md`.
# Phase 15 - MVP integrity and self-hosting

Current work makes nutrition matching explicit, blocks confirmation of unresolved foods, and supports protected local image retention for self-hosted deployments. See [Phase 15](phase-15.md). Catalog expansion, deterministic candidate ranking, broader verified food sources, and clinician-review workflows remain the next data-quality milestone.
