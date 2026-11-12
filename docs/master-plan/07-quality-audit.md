# Quality audit: what is broken, missing or needs editing

Role: QA lead and release manager.
Date: 2026-11-11. Method: read the code, run both test suites, run the app in a
browser build against the real backend, load-test the map, and use the owner's
notes from the first phone test.

## State of the product today

| Check | Result |
|---|---|
| Backend tests | 55 pass (API, trust rules, photos, admin panel, 15 attack tests, the 50 m rule) |
| App tests | 34 pass (network errors, map loading, saved-data restore, Arabic, cooler sheet, near/far/no-GPS states) |
| Automatic checks on every push | Running on GitHub and passing |
| Known vulnerabilities in backend packages | None in 40 pinned packages |
| Map speed with 100,000 coolers | Query uses the map index; a screen of about 200 pins returns in about 6 ms, 7.5 KB compressed; about 340 requests per second on a 4-core machine |
| Runs on a real phone | Yes (owner's test, 2026-11-09) |
| Release APK size | **Not reported yet.** The owner built it but did not send the number. |

The speed result means the backend is not the limit for a long time: one small
server handles every cooler in Greater Cairo.

## Fixed in this pass

| Problem | Effect on users | Fix |
|---|---|---|
| Expired login left the app "logged in" | Every action failed until the user found Log out | App logs out by itself and asks to log in again |
| Confirmation count could go down | Profile numbers shrank when a cooler's status changed | History is kept |
| Server error text shown in English inside the Arabic app | Mixed-language messages | Unknown errors show a translated generic message; new error types translated |
| No account deletion, no privacy page | Store rejection | Both added (app and web) |
| Reset script failed once a new table existed | Developer blocked | Script now drops every table the app defines |
| Missing `jinja2` package; Android build file error | Server and APK would not build on the owner's PC | Fixed earlier this week; the package list is now tested in a clean environment on every push |

## Open: store blockers

None of these stop testing. All of them stop a public release.

| # | Item | Where | Note |
|---|---|---|---|
| B1 | App id is `com.example.sabil` | `mobile/android/app/build.gradle.kts` | Cannot be changed after publishing. Set it with the new name. |
| B2 | Signed with the debug key | same file | Create an upload key (`keytool`), keep it backed up outside the repo, reference it from a `key.properties` file. Losing it means losing the ability to update the app. |
| B3 | Default Flutter icon, label "sabil" | `android/app/src/main/res`, `AndroidManifest.xml` | Comes with the identity. |
| B4 | Map tiles from OpenStreetMap's public servers | `core/config.dart` (`TILE_URL`) | Their policy forbids production use. Pick a provider (MapTiler, Stadia, Carto); the app already takes the URL as a build setting. |
| B5 | Privacy policy has no company name or contact | `app/public_web/templates/privacy.html` | Draft is live at `/privacy`. Needs a lawyer's read. |
| B6 | Play Console "Data safety" form | Play Console | Answers: account (username), photos, approximate location used but not stored. |
| B7 | No server yet | `deploy/` | Files are ready and tested as a container; a domain and a server are needed. |
| B8 | No crash or error reporting | app and backend | Add Sentry (free tier) before strangers use it. |
| B9 | No backups | server | Nightly database dump and photo copy; commands are in `deploy/DEPLOY.md`. |

## Open: things users will notice

**Update after the redesign (same day):** U1, U2, U4, U5 and U10 are done and checked in a browser with a simulated GPS position. U3 and U6 to U9 and U11 remain.

Ordered by how soon a new user hits them.

| # | Gap | Detail | When |
|---|---|---|---|
| U1 | Confirm from anywhere | Backlog item 2 (50 m rule). | With the redesign |
| U2 | A cooler you just added disappears | It waits for review and is not on the map; it only shows under My submissions. Show it as a grey "waiting" pin to its author. | With the redesign |
| U3 | Search finds cooler names only | Typing a street or area finds nothing. Add place search (a geocoding service). | With the redesign |
| U4 | No filters | "Working only", "has cups". The data is already in each pin. | With the redesign |
| U5 | No "nearest working cooler" shortcut | The main reason to open the app; today the user must read the map. | With the redesign |
| U6 | No forgotten-password path | See security R3. | Phone login |
| U7 | Leaderboard shows the top 10 only | A user ranked 11th or lower cannot see their rank. | Later |
| U8 | Nothing brings users back | No notifications ("a cooler you added was approved", "your sabil was confirmed 12 times this week"). | After launch |
| U9 | Cannot share a cooler | No link that opens a cooler in the app. Needed for patron pages. | With patron pages |
| U10 | Sponsors row in the profile | Backlog item 1: remove. | With the redesign |
| U11 | Adding a cooler needs a connection | No saved draft if the upload fails halfway (photos are retried by hand). | Later |

## Open: admin panel

| # | Gap | Detail |
|---|---|---|
| A1 | Photo review lacks context | Backlog item 4. |
| A2 | No log of admin actions and no undo | Needed before a second moderator. |
| A3 | No user list | Cannot see or block an abusive account from the panel. |
| A4 | No numbers | No counts of users, coolers or confirmations per day. Investors will ask. |

## Open: housekeeping

| # | Item | Note |
|---|---|---|
| H1 | `BUSINESS_STRATEGY.md` at the top of the repo is the old plan | Replaced by this folder; delete or point to it. |
| H2 | `mobile/README.md` is the Flutter template text | Replace with two lines. |
| H3 | Folders for iOS, web, Windows, Linux, macOS | Unused today. Keep iOS and web; the rest can go. |
| H4 | Every push runs the checks twice | Once for the push and once for the open pull request. Harmless. |
| H5 | No test of the Android build itself | Add a build job to CI so a broken build file is caught before it reaches the owner. |
| H6 | Translations are edited by hand in two files | A test fails if a key is missing from either; fine for now. |

## Test gaps

- No automated test taps through "add a cooler" or the map screen itself
  (both were checked by hand in a browser).
- Nothing runs on a real Android device automatically.
- GPS behaviour (permission denied, poor accuracy) is only covered by code
  review.

## What to do next

1. Send the APK size from the last build, so the size goal can be closed.
2. Add the Android build to CI (H5) before the redesign touches native files.
3. Take B1 to B3 together with the identity, on the owner's PC, with a build
   after each change.
4. Build the redesigned app on the phone and walk to a real cooler: the 50 m
   rule has only been tested with a simulated position.
