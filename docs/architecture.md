# Architecture reference

The Flutter application communicates only with the ASP.NET Core API. The API owns PostgreSQL access, image retention, food matching, nutrition calculation, and provider credentials.

```text
Flutter image capture -> API multipart endpoint -> image validation -> meal-vision provider
-> structured food candidates -> food database matching -> persisted draft -> review/confirmation
```

`IMealVisionProvider` isolates vision vendors. `OpenAiMealVisionProvider` sends the validated image and the existing structured nutrition-recognition prompt to the OpenAI Responses API, then maps its JSON-schema result into the existing provider contract. It has no authority to calculate final nutrition; the food database and existing calculators remain authoritative.

Configuration precedence is .NET user secrets/process environment over `appsettings.json`. `.env.local` is consumed only by the local PowerShell scripts and contains non-secret convenience defaults. Do not put database passwords or OpenAI keys in source-controlled files or Flutter defines.

Development retains uploaded image files under the existing `MealAnalysis:RetainImages` policy. The mobile app never receives an image URL, provider key, raw model response, or authorization header.
