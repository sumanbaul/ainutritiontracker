# Phase 15 - MVP integrity and self-hosting

Phase 15 makes food-review data honest and confirms only fully resolved meals.

- An unmatched item has nullable nutrition, an `Unresolved` match state, and the explicit **Nutrition unavailable** label. It is not stored as zero calories.
- Confirmation is blocked until every unresolved item is replaced with a catalog food or removed. The review action states how many items remain.
- Totals only add known values and carry `hasIncompleteNutrition`; confirmed meals therefore never silently include an unknown item.
- Local image retention is the default self-hosted storage mode. New uploads are kept below `MealAnalysis:LocalStorageRoot` in a hashed-user/year/month/meal-id path. Stored paths remain private and are only read through the owned image endpoint.

## Self-hosted production

Use PostgreSQL backups plus a persistent protected volume for `App_Data/meal-images`. Keep this directory outside source control, deny direct web serving, and back it up with the database. Set these deployment-only environment variables through your host secret manager:

```text
ASPNETCORE_ENVIRONMENT=Production
Authentication__SigningKey=<32-or-more-character-secret>
ConnectionStrings__DefaultConnection=<postgres-connection-string>
MealAnalysis__Provider=Local
MealAnalysis__AllowLocalInProduction=true
MealAnalysis__LocalStorageRoot=/data/nutrilens/meal-images
```

`AllowLocalInProduction` is deliberately false by default. S3 remains optional and is not enabled by this configuration. Never mount the image directory as a public static-file directory or put provider credentials in mobile builds.

## Offline boundary

The app queues hydration, weight, completed fasting, reminder settings, and manual drafts. Image upload/analysis, food matching, confirmation, and conflict-sensitive recipe changes require an online connection. This boundary is visible in the client rather than presenting image analysis as offline-capable.

## Operations

Before updating the API, take a PostgreSQL backup and a filesystem snapshot of retained images. Apply the EF migration normally; it migrates existing unmatched historical items to `Unresolved`. Do not edit retained image paths manually. Remove expired local images only with an operator-reviewed retention job after confirming the associated database cleanup policy.

For a self-hosted Linux deployment, run the database dump on the server with the secret connection string supplied through the shell or service manager:

```bash
pg_dump --format=custom --file=nutrilens-$(date +%F).dump "$ConnectionStrings__DefaultConnection"
pg_restore --clean --if-exists --dbname="$ConnectionStrings__DefaultConnection" nutrilens-YYYY-MM-DD.dump
tar -C /data/nutrilens -czf nutrilens-meal-images-$(date +%F).tgz meal-images
```

Take the database dump and image archive close together, retain multiple tested restore points, and restore both from the same backup window. The API must be stopped or writes must be briefly paused when strict point-in-time consistency is required.
