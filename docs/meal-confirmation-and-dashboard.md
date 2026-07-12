# Meal Confirmation and Dashboard

Phase 7 keeps every analysed meal in `AwaitingReview` until the owning user confirms it.

- `PUT /api/meals/{mealId}/items/{itemId}` corrects a draft item’s food, grams, serving, or preparation method.
- `POST /api/meals/{mealId}/items` adds a food-database-backed item to a draft.
- `DELETE /api/meals/{mealId}/items/{itemId}` removes a draft item.
- `POST /api/meals/{mealId}/confirm` confirms a non-empty draft.
- `GET /api/meals` returns confirmed history for the current user only.
- `GET /api/meals/{mealId}/corrections` returns the owned meal’s immutable correction history.
- `GET /api/dashboard/today?date=YYYY-MM-DD` returns the confirmed-meal totals for that UTC date.
- `DELETE /api/meals/{mealId}` soft-deletes an owned confirmed meal and recalculates that date’s summary.

Each add, edit, or removal writes a `user_food_corrections` record that preserves the original and corrected food, quantity, and serving information when applicable. Confirmed totals are stored in `daily_nutrition_summaries`; drafts never contribute to the dashboard. Endpoints require the temporary `X-Development-User-Id` header and constrain every read/write by that user ID.

This phase does not include Flutter screens, production authentication, or image removal.
