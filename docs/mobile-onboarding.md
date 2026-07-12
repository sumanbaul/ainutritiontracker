# Mobile onboarding

The onboarding flow collects identity/body metrics, goal, activity, diet, target weight, metric preference, and timezone. Submission maps directly to `POST /api/profile`. Backend validation and nutrition calculation remain authoritative; successful creation returns the calculated protocol and routes to Today. Startup determines completion by `GET /api/profile`, never by local flags alone.
