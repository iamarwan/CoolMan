# Prompt for Claude — Brand Identity

Copy everything inside the box below into a new Claude conversation.
When Claude finishes, paste its **"Brand Summary for Designers"** section into
the Google Stitch prompt (`docs/prompts/google-stitch-prompt.md`), and send the
full result back to Claude Code so the app theme can be built from it.

---

```
You are a senior brand strategist and identity designer who has launched
consumer mobile apps in Egypt and the wider Arab world. Create a complete
brand identity for the mobile app described below. Work through it step by
step and be decisive: give me one strong recommendation for each item, with
short reasoning, plus alternatives only where I ask for them.

## The product

A free community app for finding **public drinking-water coolers** in Egypt,
starting in Cairo (Maadi), with plans for the wider Middle East and North Africa.

What people do in it:
- Open the app and immediately see a map of nearby water coolers.
- Tap a cooler to see whether it is Working, Empty or Broken, whether it has
  cups (shared cup or disposable), photos, and when it was last confirmed.
- Tap "Still working" to confirm a cooler in one tap, or report it as empty/broken.
- Add a new cooler by dropping a pin on the map, with photos.
- Earn trust points for useful contributions; trusted contributors (500+ points)
  get their submissions approved instantly. There is a leaderboard.
- Some coolers are funded by sponsors (shops, pharmacies, mosques, NGOs,
  families). In Egyptian culture these "sabil" water points are often a form of
  **sadaqa jariya** (ongoing charity). Sponsors get a respectful, verified badge
  on their coolers.

Who uses it:
- Primary: everyday people on foot in hot cities — delivery riders, workers,
  students, commuters, parents, tourists. Many use mid-range Android phones,
  often outside in bright sunlight, often in a hurry.
- Secondary: sponsors (local businesses, mosques, NGOs) who want their good deed
  to be visible but dignified.

Tone and feel I want:
- Fast, clear and practical like modern mobility apps (Rabbit, Lime, Careem),
  not like a charity brochure.
- Warm, trustworthy, community-driven, with quiet respect for the charitable
  and cultural roots. No religious imagery in the logo itself.
- Works equally well in **Arabic and English**, including right-to-left layouts.

The current working name is "Sabil" / "CoolMan". I want a **fresh name**.

## What I need from you

1. **Brand strategy**
   - One-sentence positioning statement.
   - Brand promise, three to four brand values, and brand personality
     (with a "this, not that" list, e.g. "helpful, not preachy").
   - Short audience personas (2–3).

2. **Name**
   - 10 name candidates, each with: the Arabic version (script + transliteration),
     meaning/story, how it sounds in both languages, and any risk (awkward
     meanings, hard to pronounce, too similar to existing apps).
   - Names must be short (ideally 1–2 syllables in at least one language),
     easy to say in Egyptian Arabic and English, and work as an app-store title.
   - Pick your top 3 and then one final recommendation, with reasoning.
   - Note that I must check trademark, domain and Play Store availability myself.

3. **Tagline**
   - 5 options in English and their natural Arabic equivalents (not literal
     translations). Recommend one.

4. **Logo direction**
   - Describe 3 logo concepts (wordmark + symbol) for the recommended name.
   - The app icon must read clearly at 48×48 px on a phone home screen and work
     on both light and dark backgrounds.
   - For your recommended concept, produce a simple **SVG** of the symbol and an
     SVG of the app icon (square with safe area for Android adaptive icons).
   - Bilingual lockups: how the Arabic and English wordmarks sit together.

5. **Colour system**
   - Primary, secondary, accent and neutral palettes with hex values.
   - Semantic colours for cooler status: **Working**, **Empty**, **Broken**,
     **Pending review**, plus **Sponsored/verified**. They must be distinguishable
     by people with colour blindness and should be paired with icons, not colour alone.
   - Light mode and dark mode values.
   - State WCAG contrast ratios for text on each main background (aim for AA,
     and AAA for body text where possible). The app is used in bright sunlight.

6. **Typography**
   - One font family (or a matched pair) that covers **both Arabic and Latin**
     scripts well, is free for commercial use (e.g. from Google Fonts), and is
     legible at small sizes. Give the reasons for your pick.
   - A type scale for mobile (display, headline, title, body, label, caption)
     with sizes, weights and line heights, noting any adjustments for Arabic.

7. **Iconography and illustration**
   - Icon style (stroke weight, corner radius, filled vs outline) and a list of
     the core icons the app needs (cooler, cups, working, empty, broken, add pin,
     confirm, camera, sponsor, trophy/points, profile, language).
   - Map pin and cluster design for each status, described precisely enough
     for a designer to draw (shape, size, colours, icon inside).
   - Illustration style for empty states and onboarding (3 onboarding scenes).

8. **UI design language**
   - Corner radii, spacing scale (4/8-based), elevation/shadow rules (keep it
     light; this runs on mid-range phones), button styles, bottom-sheet style,
     chips, input fields, and motion principles (short, purposeful).
   - Express this as **design tokens** in a JSON block (colours, typography,
     radius, spacing, elevation) that a Flutter developer can turn into a theme.

9. **Voice and microcopy**
   - Writing guidelines in English and Arabic (Egyptian-friendly Modern Standard
     Arabic, not overly formal).
   - Sample microcopy in both languages for: onboarding (3 screens),
     location-permission request, "no coolers nearby" empty state,
     confirm-working success, report-empty, add-cooler success, waiting for
     approval, network error, login prompt ("log in to contribute"), and points earned.

10. **Brand Summary for Designers**
    End with a single compact section titled exactly
    **"Brand Summary for Designers"** (max ~250 words): name, tagline (EN + AR),
    personality in five words, the full colour palette with hex codes and
    roles, fonts, corner radius, icon style, map-pin description and visual mood.
    I will paste this straight into Google Stitch, so make it self-contained.

Format everything with clear headings. Use tables for colours and type scales.
```
