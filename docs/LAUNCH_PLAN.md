# Launch plan: what the app still needs before real users in Egypt

Written 2026-10-17, updated the same day. Scope: features and groundwork the app itself needs to run for the public in Egypt. Payments, the enterprise dashboard, the municipality API and AI photo checking are **not** in here (see `BUSINESS_STRATEGY.md`).

Effort: **S** = hours to a day, **M** = a few days, **L** = a week or more. These are rough guesses.

## 0. Progress since this plan was written

| Item | State |
|---|---|
| Arabic translation spreadsheet (every text in the app, empty Arabic column) | Done: `docs/translations/sabil_arabic_translation.xlsx`. Waiting for the Arabic to be filled in |
| Sign in with a mobile number (item 3, partly) | Done in the app and server (Phone tab, SMS code). Works in development with the code printed in the server log. **Still needed:** pick a real SMS company and add it in `backend/sabil/core/sms.py`; a button in the profile to link a number to an existing account (the server route `/auth/phone/attach` is ready) |
| "In memory of" dedications | Done: admin sets/removes it from the Live tab menu; everyone sees it on the cooler's card |
| Commissioned coolers (see section 7) | Planned, not started |

## 1. What already works

Map with clustering and nearby search; add a cooler with photos and a 15 m duplicate guard; report status and "Still working"; "Verified N days ago / Stale" labels; directions button (opens Google Maps); trust points, levels and leaderboard; sponsors and sponsor assignment; admin review queue (hidden, via 5 taps on the title); private unapproved items; rate limits; upload checks; photo compression on the phone.

## 2. Must have before launch

| # | Item | Why (Egypt-specific where it applies) | Effort |
|---|---|---|---|
| 1 | **Arabic language and right-to-left layout.** Follow the phone's language; let the user switch. Every text in the app is English today, and `intl`/localizations are not set up. | Most users will read Arabic first. This is the biggest piece of work. Arabic digits vs 0-9 is a small decision inside it. | L |
| 2 | **Report a problem with a cooler:** "does not exist / removed", "wrong place", "inappropriate photo". Admin sees the reports; optionally hide a cooler automatically after several independent "does not exist" reports. Also let a person withdraw their own pending submission. | Today the only report is working/empty/broken, so dead or fake coolers can sit on the map forever. | M |
| 3 | **Account basics:** change password, delete my account (Google Play requires in-app deletion), and some way to recover a forgotten password. *Phone sign-in is built (see section 0), which covers recovery for people who link a number.* Change password and delete account are not built. | Recovery needs a decision: optional email, or phone number with an SMS code (costs money per SMS in Egypt). | M |
| 4 | **Production hosting:** HTTPS server, managed PostgreSQL with PostGIS and automatic backups, photos stored somewhere that survives redeploys (server disk with backup, or object storage), `SABIL_ENV=production` with real secrets, CORS restricted (BE-10). | Pick a host with good latency to Cairo (EU region or a local provider). | M |
| 5 | **Real client IP behind the proxy.** Rate limits read `request.client.host`; behind a reverse proxy every user looks like one IP, so 3 new coolers per minute would apply to *everybody together*. Also move the limits out of memory if more than one server process runs (BE-09). | Mobile carriers in Egypt share addresses too (carrier NAT), so consider per-user limits as well as per-IP. | S-M |
| 6 | **Map tiles:** the app uses the public OpenStreetMap tile server, whose rules do not allow production-scale use. Switch to a tile provider (paid or free tier) and show the map attribution. | Avoids being blocked on launch day. | S |
| 7 | **Release build:** server address set per build (`--dart-define`, not edited in code), app name, icon, splash screen, signing key, Play Store listing, **privacy policy and terms pages** (location + camera + photos), Data Safety form. | Required to publish at all. | M |
| 8 | **Poor-network behaviour:** keep the last loaded coolers and show them when offline with a banner, retry buttons, retry for failed photo uploads. Lower the add-cooler photo size (1920 px / 85 %) to match the 1280 px used elsewhere. | Mobile data is slow and drops often. | M |
| 9 | **Crash and error reporting plus uptime alert** (for example Sentry, and a simple ping monitor on the server). | Without it you will not know the app is broken. | S |
| 10 | **Starting data.** An empty map kills the app. Options: import existing OpenStreetMap `amenity=drinking_water` points for Egypt (check licence and attribution rules, and quality), plus a field pass through Maadi. Then recruit first reporters. | Phase 1 of the business plan assumes 200 coolers in Maadi. | M |
| 11 | **Database migrations (Alembic)** instead of hand SQL (BE-14). `scripts/sync_schema.py` is only a stop-gap. | Do it before the first real deployment, while the database is empty or small. | M |
| 12 | **Admin tools for abuse:** block a user, see their submissions, undo their approvals; a second admin account instead of one shared password. I have not seen a way to block a user in the code. | One moderator cannot handle all of Egypt. | M |

## 3. Should have soon after launch

- Filter the map by status ("only working") and by type of cooler.
- Count sponsor views and clicks (BE-11), because sponsors need numbers to justify paying.
- Share a cooler through WhatsApp (link opens the app or a small web page).
- Tidy items from the findings log: MB-11, MB-14, MB-15 (rules and strings typed into the app).
- Decide the leftovers: BE-12 (edit a cooler), BE-17 (three overlapping ways to update status), BE-18 (cups type is never set), BE-19.

## 4. Suggested order

1. **Foundation (items 4, 5, 6, 9, 11):** the server can run safely for the public.
2. **Egypt-ready (item 1, then 8):** Arabic and bad-network behaviour.
3. **Keeping data clean (items 2, 3, 12):** reports, accounts, abuse tools.
4. **Launch prep (items 7, 10):** store listing, privacy policy, starting data.
5. **Soft launch** in Maadi only, watch crash reports and the moderation queue for 2-4 weeks, then widen.

## 5. Open decisions

- Password recovery: email, phone code, or sign in with Google?
- Arabic digits or 0-9?
- Which host and region?
- Is a soft launch limited to Maadi, or all of Cairo?

## 6. Note on payments (outside this plan)

`BUSINESS_STRATEGY.md` names Stripe. To my knowledge Stripe does not onboard businesses based in Egypt, so check before designing around it. Paymob and Fawry are the usual Egyptian routes, with InstaPay and mobile wallets such as Vodafone Cash common with users.

## 7. Commissioned coolers ("In memory of", built by you)

Business idea in `BUSINESS_STRATEGY.md`, section 2D: people order a cooler built and installed in the name of someone they love, and you build it and keep it running. Not started; waiting for the owner to decide where it sits in the app (see 7.4).

### 7.1 Decision (2026-10-18): how people ask

| Option | Verdict |
|---|---|
| **A button inside the app, feeding an admin inbox** | **Chosen.** The person drops a pin exactly where the cooler should go; their phone number is already verified (phone sign-in); the request lands in the admin panel and connects to the dedication feature already built. |
| A separate app | Rejected. Two apps to build, publish and maintain for the same audience, no benefit. Only worth reconsidering for a corporate (B2B) product much later. |
| Email only | Rejected as the process: no map pin, no verified person, a lot of back and forth. Use email only as a notification to the owner. |
| WhatsApp | Add as the conversation channel: a "Talk to us on WhatsApp" button that opens a chat with the request pre-filled. This is where sales will actually be closed in Egypt. |
| A simple web order page with the same form | Later, for people who have not installed the app and arrive from a WhatsApp or Facebook link. Uses the same server. |

### 7.2 The flow

1. The user taps "Give a Sabil in someone's name" (wording to be decided; avoid "donate" and "buy", see 7.5).
2. They choose a tier, drop a pin (or describe the place), enter the name to dedicate and a short message, any notes (mosque, shop, building), and how they want to be contacted. Their account and verified phone number are attached automatically.
3. The request appears in the admin panel. The owner replies on WhatsApp with a quote. Payment starts offline (InstaPay, bank transfer, cash) and is recorded by the admin.
4. The user can follow the request in the app ("My requests"): New, Contacted, Quoted, Paid, Building, Installed, Declined.
5. The owner builds and installs it, adds a photo, creates the cooler and sets the dedication (already built). The person gets a shareable "in memory of" card.

### 7.3 Tiers (owner to confirm which at launch)

| Tier | What it is | Why |
|---|---|---|
| Dedicate an existing cooler | A year of refills and cups on an existing cooler, with the name on its card | Cheapest way in, no building |
| Zeer (clay pot) cooler | Traditional, cheap, no electricity | Low cost, culturally familiar |
| New cooler, built and installed | The full service | Highest margin |

All tiers can include a yearly renewal (maintenance fee).

### 7.4 Where to put the entry point in the app (owner to decide)

| Place | For | Against |
|---|---|---|
| **On each cooler's card:** "Dedicate this cooler / fund its refills in someone's name" | Right moment (the person is looking at a cooler); fits the cheapest tier | Only reaches people who open a cooler |
| **A card on the profile screen:** "Give a Sabil in someone's name" | Always findable, does not clutter the map | Few people open the profile |
| A floating button on the map | Most visible | Clutters the map, which is the product |
| A fourth welcome screen | Everyone sees it once | Too early, before they trust the app |
| The sponsor page ("Become a sponsor") | Right for shops and businesses | Not for individuals |
| A seasonal banner (Ramadan, heat waves) | Good timing, easy to switch off | Needs a banner mechanism |

**Suggestion:** cooler card + profile card, keep the map clean, and add the web order page for people who have not installed the app. Revisit once there is data on what people tap.

### 7.5 What the app and server need (all not started)

| Step | What it is | Effort |
|---|---|---|
| 1 | Request form in the app (pin, tier, name, message, notes, contact). | M |
| 2 | Admin inbox for requests with status, notes and contact visible only to the admin. | M |
| 3 | "My requests" screen so the person can follow progress. | S |
| 4 | Turning a request into a cooler: create the cooler, attach the photo, set the dedication (the dedication part exists). | S |
| 5 | WhatsApp button with the request pre-filled (a `wa.me` link, no server needed). | S |
| 6 | Price list stored on the server so prices change without a new app release. | S |
| 7 | Shareable gift card (image or PDF: name, message, cooler photo, location). | M |
| 8 | QR plaque for each cooler: scanning opens that cooler's page, shows the dedication and lets passers-by confirm "Still working". Also keeps the data fresh. | M |
| 9 | Payments: offline first, recorded by the admin. Online later. | S now, M later |
| 10 | Maintenance renewals: renewal date per cooler, list of renewals due, reminder at 40 days and one year. | M |
| 11 | Internal tracker: supplier costs, installed coolers, maintenance schedule. | M |

### 7.6 Checks before selling (owner, with a lawyer and accountant)

- **Selling a service is not collecting donations.** Collecting donations is regulated in Egypt. Word the offer as commissioning or sponsoring a cooler, and confirm with a lawyer which rules apply to you.
- **Permission for each place:** who can approve a cooler in a mosque, shop, building or on a street.
- **Practicalities:** water supply, electricity, theft and vandalism, hygiene and cups, who does the monthly refill and how fast.
- **Business paperwork:** registration to take payment and issue receipts.
- **Consent for the name:** the family agrees to the name being shown, and there is a way to remove it.
- **Pricing:** hardware + installation + first-year maintenance + margin; renewal price.

### 7.7 More ideas for this business

Funeral and mosque partnerships (offer the option to families); Ramadan and corporate batches (one company funds many coolers, with its name on the plaques); anniversary messages with a fresh photo at 40 days and one year; a "before and after" photo for every installation; local technician partners per area; group funding of one cooler by a family (check the donation rules first).

### 7.7a Questions waiting for the owner

1. Which tiers at launch?
2. The WhatsApp business number to use.
3. Web order page now or after the app?
4. Where the entry point goes (7.4).

## 8. Ideas list status

Chosen by the owner on 2026-10-17: idea 2 ("In memory of" dedications, built) and idea 9 (phone sign-in, built). The commissioned-coolers service (section 7) grows out of idea 2. The other ideas (cooler types incl. Zeer, WhatsApp sharing, request a cooler here, guardians, heat/Ramadan mode, metro layer, quality tags, offline map) are not decided yet.
