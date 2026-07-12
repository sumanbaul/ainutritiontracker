# Mobile Today dashboard

Today combines `GET /api/profile` nutrition targets with `GET /api/dashboard/today` confirmed-meal totals. Flutter calculates display-only percentages and remaining values. Confirmed meal history comes from bounded `GET /api/meals?take=100`. Draft meals never contribute to totals.

Empty, unavailable, and populated states are explicit. Pull-to-refresh re-requests the current user’s data. Full meal capture and review remain Phase 10.
