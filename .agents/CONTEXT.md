# Food resolution context

## Current implementation

- Meal analysis automatically resolves foods conservatively: exact catalog matching first, then AI ranking only over server-filtered user-visible catalog candidates.
- A catalog result must have sufficient confidence and a lead over the next candidate. AI cannot select an ID outside the shortlist.
- When there is no safe catalog match, the server creates a private inactive `AI estimate` food for the draft item. It contributes draft totals and remains visibly review-required. Meal confirmation activates it for that owner; removal or draft deletion discards it.
- `FoodResolutionEvent` is the privacy-safe audit record. Do not store raw image bytes or raw provider/model output in it.
- Flutter treats resolve/edit mutation responses as authoritative and guards background review refreshes with a revision token.

## Future phase: opt-in validation game

- Do not expose the game in the current product.
- Future cards use anonymized, opt-in, confirmed-meal data only. Never show users their own meal or unconsented images/identifiers.
- Swipe right confirms; swipe left rejects. Store tasks and responses separately from meals.
- Consensus may create curator-review candidates only. It must never automatically alter the shared catalog; private foods require explicit promotion.
