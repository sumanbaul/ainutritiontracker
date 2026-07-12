# Nutrition target calculation

Automatic targets use Mifflin-St Jeor: `10*kg + 6.25*cm - 5*age + 5` for male and `... - 161` for female. BMR is multiplied by configured activity level, then adjusted by goal. Values are rounded to two decimals only at the final result.

Protein uses configured grams per kilogram, fat is the greater of 25% calories or 0.6 g/kg, carbohydrates receive remaining calories, and fibre is 14 g per 1000 kcal. Automatic targets are clamped to configured non-medical safeguards; custom targets must reconcile macro calories within tolerance and are not clamped. These are estimates, not medical advice.
