# Arabic translation sheet

`sabil_arabic_translation.xlsx` lists every English text in the app (259 rows in "App texts"), the messages the server sends (22 rows), and a glossary of key words. Type the Arabic in the yellow column. The first sheet explains how.

Generated 2026-10-17 from the app source. Nothing in the app uses it yet: it is the input for the Arabic version (item 1 of `docs/LAUNCH_PLAN.md`).

Next steps once it is filled in:
1. Set up Flutter localization (Arabic + English files, right-to-left layout).
2. Replace each typed-in English text with a lookup (the sheet's ID and "Where used" columns say where each one is).
3. Make the server send error codes instead of English sentences, so the app can show them in Arabic (the 22 "Server messages" rows).

If the English texts change before then, ask for the sheet to be regenerated; the Arabic already entered will be carried over by matching the English text.
