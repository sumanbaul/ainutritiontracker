# Food data model

Nutrients use edible values per 100 grams. Aliases retain regional and BCP-47 language metadata; Unicode-preserving normalization supports indexed matching. Household measures are food-specific, so katori and bowl never have a global gram value.

Search ranks exact canonical names, exact aliases, prefixes, then contains matches. Only active shared foods and the requesting user's private custom foods are visible. Scaling rounds final values to three decimals and preserves null unknown nutrients.

Mixed-dish seed values are approximate development data, not a validated production nutrition database or medical advice. Future IFCT or USDA imports require confirmed licensing, attribution, and versioning.
