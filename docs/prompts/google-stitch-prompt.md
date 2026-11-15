# Prompt for Google Stitch — Full App Interface

## How to use this

1. Replace `[APP NAME]` everywhere (use "Sabil" if the name is not final).
2. The `BRAND` block below already works without a final identity: colours are
   placeholders. If you later like a palette, swap the hex values there, or just
   tell Claude Code the new colours after the build — every colour lives in one
   place in the app, so changing them later is a small edit.
3. In Stitch, choose **Mobile** as the target.
4. Paste **Prompt A (master)** first. Stitch does best with focused prompts, so
   if it skips screens or the quality drops, generate the remaining screens one at a
   time with the **Prompt B** lines below, in the same project so the style carries over.
5. Generate each key screen in **English (LTR)** and **Arabic (RTL)**.
6. Export the designs (images + HTML/CSS or Figma export) and give them to Claude Code.

---

## Prompt A — master prompt

```
Design a complete Android mobile app UI for "[APP NAME]", a free community app
for finding public drinking-water coolers in Egyptian cities. Style it like a
modern mobility app (Rabbit, Lime, Careem): the map is the home screen, and
details open in bottom sheets. It should feel fast, clean, warm and trustworthy.

BRAND (placeholder — colours will be changed later, so keep them as tokens)
- Name: [APP NAME]. Use a simple text wordmark with a water-drop symbol; no final logo yet.
- Personality: practical, fast, warm, trustworthy, community-driven; quiet respect
  for the charitable roots (sadaqa jariya) without religious imagery.
- Colour roles (placeholder values): Primary #0F766E (teal), Primary container #CCFBF1,
  Surface #FFFFFF, Background #F8FAFC, Ink #1E293B, Muted #64748B, Line #E2E8F0.
  Status: Working #059669, Empty #D97706, Broken #DC2626, Pending #2563EB,
  Patron/verified #7C3AED.
- Use ONLY these named colour roles everywhere (no one-off colours), so the whole
  palette can be swapped later by changing the role values.
- One font family that supports Arabic and Latin (e.g. IBM Plex Sans Arabic or Cairo).
- Corner radius 16 for cards/sheets, 12 for buttons/inputs; 4/8 spacing grid.

GLOBAL RULES
- Phone frame 360x800 dp (mid-range Android). Material 3 foundations, customised to the brand.
- Map-first: the full-screen map is always the base layer; overlays are a
  floating search bar on top and a bottom sheet / floating buttons at the bottom.
- Large touch targets (min 48dp), high contrast for use in bright sunlight.
- Light shadows only; no heavy blur or glassmorphism (must stay fast on mid-range phones).
- Every cooler status uses colour + icon + text label together:
  Working, Empty, Broken, Pending review. Coolers that have a patron (the family,
  mosque or business that funded and maintains it) get a subtle patron badge.
- Bilingual: show each key screen in English (left-to-right) AND Arabic
  (right-to-left, fully mirrored layout, Arabic typography, Arabic text — not lorem ipsum).
- Include realistic Cairo content (e.g. "Maadi Metro Station", "Road 9",
  "Next to El-Tawheed Mosque", "El-Borg Pharmacy").

SCREENS

1. Splash — logo centred on the brand colour; nothing else.

2. Onboarding (3 swipeable pages + "Skip"):
   (a) find free clean water near you, (b) drop a pin to add a cooler or report
   one that is empty/broken, (c) earn trust points; at 500 points your additions
   go live instantly. Final page asks for location permission with a friendly
   explanation and "Allow location" / "Not now".

3. Home map:
   - Full-screen map of Maadi, Cairo with ~15 cooler pins in different statuses
     and 2 numbered cluster bubbles.
   - Floating search bar at the top ("Search coolers or places") with a profile
     avatar button.
   - Small status filter chips under the search bar: All, Working, Has cups.
   - Floating "my location" button, and a prominent "+ Add cooler" button.
   - A compact "nearest working cooler: 120 m · 2 min walk" card above the bottom edge.

4. Cooler detail bottom sheet (half-expanded and fully-expanded states):
   - Name/landmark, status pill, distance and walking time, "Last confirmed 25 min ago".
   - Cups info (Shared cup / Disposable cups / No cups).
   - Horizontal photo strip.
   - Patron card (only on coolers that have one): "Sabil for the soul of Hajj Ahmed
     Mahmoud" or "Maintained by El-Borg Pharmacy", verified badge, small "confirmed
     working 312 times" impact line; tapping opens the patron detail (screen 11).
   - Primary action "Still working ✓", secondary actions "Report empty",
     "Report broken", "Add photo", and "Directions".
   - Distance rule: contributions are only allowed within 50 m of the cooler.
     Show the states: (a) near → buttons enabled; (b) too far → buttons disabled
     with a clear line "Get closer to confirm — you are 230 m away" and the
     Directions button highlighted; (c) "Getting an accurate location…" with a
     small spinner while GPS improves.

5. Add cooler flow (3 short steps in a bottom sheet over the map):
   (1) Place pin — map with a centre crosshair pin, "Move the map to place the
   pin", "Confirm location" (only possible within 50 m of the user's position;
   show the user's dot and a faint 50 m circle); (2) Details — name/landmark field, cups choice
   (Shared / Disposable / None), status; (3) Photos — add up to 3 photos
   (cooler + cups), then "Submit". Then a success state: "Submitted! Waiting
   for review · +50 points when approved".

6. Report / confirm feedback — small toast or snackbar states: "Confirmed! +5
   points", "Thanks — marked as empty", "You already confirmed this cooler, try
   again in an hour".

7. Login / register bottom sheet — appears only when the user tries to
   contribute: "Log in to contribute", tabs Log in / Create account,
   username + password, primary button, a short line about why an account is needed.

8. Profile:
   - Avatar, username, trust score with a progress bar to 500 ("Verified
     contributor" badge when reached), counts for coolers added, confirmations, photos.
   - Rows: My submissions, Leaderboard, Language (English / العربية),
     About, Log out. (No sponsors list here.)

9. My submissions — list of the user's coolers with status chips:
   Approved, Pending review, Rejected, and pending status changes.

10. Leaderboard — top 10 contributors, top 3 highlighted, the current user's rank pinned at the bottom.

11. Patron detail — opened only from a cooler's patron card: dedication or
    business name, type (Family, Mosque, Business, NGO), verified badge, short
    message, the cooler's impact (times confirmed, last checked, photos), and a
    contact button for businesses. There is NO general list of patrons.

12. Language picker — English / العربية with a preview of direction (LTR/RTL).

13. Empty, loading and error states:
    - No coolers in this area ("Be the first to add one" + Add button).
    - Location off ("Turn on location to see coolers near you" + Open settings).
    - No internet ("You're offline — showing saved coolers" banner over the map).
    - Map loading skeleton.

Deliver a consistent design system across all screens: colour tokens,
typography scale, spacing, corner radii, buttons, chips, inputs, bottom sheets,
map pins (one per status + cluster + selected state) and icons.
```

---

## Prompt B — one screen at a time (use if Prompt A gets cut short)

Start each with: *"Same app, same design system as before."* Then one of:

- `Design the Home map screen (screen 3 from my brief) in English, then the same screen in Arabic RTL.`
- `Design the Cooler detail bottom sheet in half-expanded and fully-expanded states, English and Arabic RTL.`
- `Design the 3-step Add cooler flow plus its success state, English and Arabic RTL.`
- `Design the Login/Register bottom sheet shown when a guest tries to contribute.`
- `Design the Profile screen with trust-score progress and the Language row, English and Arabic RTL.`
- `Design My submissions and Leaderboard screens.`
- `Design the Patron card inside the cooler sheet and the Patron detail screen (family dedication and business versions), English and Arabic RTL.`
- `Design the cooler sheet's distance states: near (enabled), too far (disabled with distance + directions), and waiting for accurate GPS.`
- `Design the Onboarding pages with the location-permission request, English and Arabic RTL.`
- `Design the empty, offline, location-off and loading states over the map.`
- `Design a component sheet: map pins for Working, Empty, Broken, Pending, Patron, cluster bubble, selected pin; buttons; chips; inputs; status pills; toasts.`
