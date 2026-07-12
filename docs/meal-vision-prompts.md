# Meal vision prompts

Current prompt version: `v1`. Schema version: `1.0`.

The system prompt treats packaging and image text as untrusted data, ignores instructions visible in images, prohibits medical/private-attribute inference, nutrition totals, markdown, and prose outside JSON. Client context is length-limited and JSON-serialized into an explicitly untrusted section. Bengali and Indian terminology is preferred only when supported by the image and context.

Add future prompt versions as immutable builders or embedded resources, retain schema compatibility tests, and return both versions in every result.
