# Nwasy brand identity

Role: brand director for bilingual Arabic and English products.
Date: 2026-11-11. First pass, written after the owner chose the name and
supplied the Stitch designs.

## Name

**Nwasy · نواصي** means "street corners" (singular ناصية). It fits a super app
for what you find on the street, and Egyptians already say "على الناصية" (on
the corner) for the kiosk, the cart and the cooler.

| Point | Note |
|---|---|
| Arabic spelling | نواصي. Clear and common. |
| English spelling | "Nwasy" has no vowel after the N, so English readers hesitate. "Nawasy" reads the way it is said. Decide once; the store name, domain and accounts must all match. **My advice: Nawasy in Latin letters, نواصي in Arabic.** If you prefer "Nwasy" as a deliberate brand spelling, keep it and add a one-line pronunciation ("na-WAA-see") wherever the name is introduced. |
| How to say it | na-WAA-see |
| Checks still to do | Play Store search, Egyptian trademark register (software and advertising), domain, social handles. Not done by me. |
| Room to grow | Works for water, food, coffee and anything else on a corner. |

The app, the admin panel and the documents currently use "Nwasy".

## Positioning

**For** people on foot in Egyptian cities **who** need something nearby right
now, **Nwasy is** the map of what is on the corner, **that** is confirmed by
people standing there. **Unlike** general maps, it shows places with no
address and whether they are working or open today.

Promise: *what the map says is there, is there.*

Personality: helpful, street-smart, warm, honest, quick.

| This | Not that |
|---|---|
| A neighbour who knows the area | A charity brochure |
| Plain Egyptian Arabic | Formal or preachy language |
| Shows broken things honestly | Pretends everything works |
| Respectful of giving | Uses religion to sell |

## Colour

The Stitch designs use the teal palette below, and the app is now built with
it. All colours live in one file (`mobile/lib/shared/ui.dart`), so changing
the palette later is a small edit.

| Role | Hex | Contrast on white |
|---|---|---|
| Primary | `#0F766E` | 5.5 |
| Primary dark (strong buttons, text on tint) | `#005C55` | 7.9 |
| Primary tint | `#CCFBF1` | background only |
| Background | `#F9F9FF` | |
| Quiet surface | `#F0F3FF` | |
| Ink | `#111C2D` | 17.1 |
| Muted text | `#64748B` | 4.8 |
| Working | `#059669` | 3.8 (use with icon and label, or on its tint) |
| Empty | `#D97706` | 3.2 (same) |
| Broken | `#DC2626` | 4.8 |
| Waiting for review | `#2563EB` | 5.2 |
| Patron | `#7C3AED` | 5.7 |

Two honest notes for the next design round:

1. **Teal and "working" green are close.** On the map they are told apart by
   shape and icon, but a brand colour further from green (a deep blue, for
   example) would make status clearer. Worth testing before printing anything.
2. **Working green and empty amber fall below the 4.5 text standard on
   white.** They are fine as pin fills with white icons and as text on their
   own tints, which is how the app uses them. Do not use them for small text
   on white.

**Categories for the super app.** Each layer gets an icon and a colour family
for its filter chip and list icon, never for status:

| Layer | Icon | Colour family |
|---|---|---|
| Water | Drop | Teal (brand) |
| Food | Truck or fork | Warm orange |
| Coffee and tea | Cup | Coffee brown |
| Essentials | Compass | Slate blue |

Status colours (working, empty or closed, broken, waiting) stay the same in
every layer, so people learn them once.

## Type

**IBM Plex Sans Arabic**, bundled in the app in three weights (regular,
semibold, bold). One family covers Arabic and Latin, it stays readable at
small sizes, and it is free to use (Open Font License; the licence file is in
`mobile/assets/fonts`).

| Use | Size | Weight |
|---|---|---|
| Large heading | 30 | Bold |
| Heading | 22 | Bold |
| Title | 18 | Semibold |
| Body | 15 | Regular |
| Label | 14 or 12 | Semibold |

Line heights are generous so Arabic marks are never clipped.

## Logo direction

There is no final logo. The app shows a drop in a rounded square as a
placeholder. Three directions for a designer:

| Direction | Idea | For | Against |
|---|---|---|---|
| **The noon pin** (my pick) | The Arabic letter ن is a bowl with a dot above it. Make the dot a map pin. It is the first letter of نواصي and reads as "a place, marked". | Ownable, works at icon size, needs no words | Latin readers will not see the letter, only a friendly shape |
| The corner | Two streets meeting at a right angle with a pin on the corner | Literal and clear | Looks like many map icons |
| The crossroads | A plus sign of roads with one corner filled | Simple | Close to a medical cross |

Rules for whichever is chosen: reads at 48 px, works in one colour, works on
light and dark, the Arabic and Latin names sit side by side with the mark
between or before them.

I drew an earlier visual board, but it was made for the old name and a blue
palette before the Stitch designs arrived, so I removed it rather than leave
something misleading. A board for Nwasy has not been drawn yet.

## Shapes and components

From the Stitch design system, as built:

- Pills for chips and status. Radius 12 for buttons and fields, 16 for cards,
  24 for the top of sheets.
- Light, tight shadows and hairline borders; no blur, so it stays readable in
  sunlight and fast on mid-range phones.
- Touch targets at least 48 px.
- Pins are teardrops in the status colour with a white icon; a purple ring
  marks a patron's cooler; clusters are dark teal circles with a number.

## Voice and sample lines

| Moment | English | Arabic |
|---|---|---|
| Tagline, users | Everything on the corner. | كل اللي على الناصية. |
| Tagline, water | Cold water, on the map. | أقرب مَيّة ساقعة ليك. |
| Tagline, givers | A sabil in their name. See it working every day. | سبيل باسمهم.. وشغّال قدّام عينك. |
| On a plaque | Drink, and say a prayer for them. | اشرب وادعيلهم. |
| Too far to confirm | Get closer to confirm. | قرّب شوية عشان تأكّد. |
| After confirming | Thanks. The next person will know. | شكرًا.. اللي بعدك هيعرف. |
| Vendor sticker | Find me on Nwasy. | لاقيني على نواصي. |

The app's own Arabic text is in clear standard Arabic; these lines are in
Egyptian dialect for marketing. A native copywriter should review both.

## Decisions needed from the owner

1. "Nwasy" or "Nawasy" in Latin letters.
2. Keep the teal, or test a brand colour further from the status green.
3. Which logo direction to hand to a designer.

## Next steps

1. Run the name checks.
2. Commission the mark (a few days of a freelance designer's time) with this
   page as the brief.
3. Then set the app id, icon and store listing together (quality audit B1 to B3).
