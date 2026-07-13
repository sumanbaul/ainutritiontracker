# Fasting counter

NutriLens fasting is a timestamp-based, informational tracking tool. It is not medical advice.

## Lifecycle

`POST /api/fasting/start` persists one user-scoped active fast with a UTC start time and selected 1–72 hour target. `GET /api/fasting/active` restores it after backgrounding or an app restart. A user-scoped secure-storage mirror renders immediately while the app refreshes from the backend; the backend always replaces or clears that mirror. The client redraws from `nowUtc - startedAtUtc`; it never persists a ticking seconds counter.

`POST /api/fasting/{id}/end` atomically creates the existing completed `FastingWindow` record and marks the active record completed. Repeating the end call returns the completed state without creating a second history record. `POST /api/fasting/{id}/cancel` does not create completed history.

## Offline and notification policy

Starting requires an online connection. Once started, the displayed counter remains correct offline because it is derived from UTC timestamps. If ending fails because the device is offline, the exact end timestamp, expected server version, and idempotency key are queued under the current user. The app keeps the fast visible as **pending sync** and blocks repeat end/cancel actions until replay succeeds. Users may opt in to one local target-reached notification; permission is requested only when that option is selected, and the scheduled notification is cancelled on end or cancellation.

The UI uses neutral language, does not recommend fasting targets, does not encourage extension after a target, and always displays a short safety disclaimer.
