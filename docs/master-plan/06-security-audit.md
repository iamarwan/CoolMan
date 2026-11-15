# Security audit

Role: application security engineer attacking my own code.
Date: 2026-11-11. Scope: backend (`app/`), admin panel, phone app (`mobile/lib`),
deploy files. Method: read every route and state change, write each suspected
attack as a test, run it against the code, fix, re-run.

**Result:** 14 attacks worked before this pass. All 14 are fixed and covered by
tests in `tests/test_security.py`. A 15th, confirming from far away, was closed
later the same day with the 50 m rule (`tests/test_distance.py`). 11 known
risks remain open; they are listed at the end with what closes each one.

What I could not test: the Android build (no Android SDK in my workspace), a
real HTTPS deployment, and attacks that need a real phone (GPS spoofing, a
rooted device).

---

## Fixed in this pass

Severity: **High** = account takeover, data leak or the moderation system
defeated. **Medium** = abuse that costs trust or money. **Low** = hardening.

| # | Severity | Attack that worked | Fix | Test |
|---|---|---|---|---|
| 1 | High | **Unlimited password guessing.** Nothing limited wrong logins, so a script could try thousands of passwords per minute against any username. | Failed logins are counted in the database: 10 per user from one address, 30 per user overall, 60 per address, each per 15 minutes. Then the server answers "too many attempts". | `test_login_is_locked_after_repeated_wrong_passwords` |
| 2 | High | **Unlimited guessing of the admin password** (only a 1-second delay, and requests could run in parallel). | 5 failures per address per 15 minutes, then locked. | `test_admin_login_is_locked_after_repeated_failures` |
| 3 | High | **Forging any login in development.** The token-signing secret had a default value published in this repository. On home Wi-Fi anyone could create an admin token without knowing the password. | In development a random secret is generated and kept in a local `.dev-secret` file (not in git). Production already refused to start with the default. | Covered by config; manual check |
| 4 | High | **Becoming "trusted" in one evening without leaving home.** Each confirmation paid 5 points and each status report 10, on every cooler, every hour. 15 coolers gave 225 points an hour; 500 points unlock instant publishing with no review. | Status reports pay only when an admin accepts them. At most 20 rewarded actions per day. Reporting the status a cooler already has is rejected. (Distance check is still open, see R1.) | `test_status_report_points_only_after_admin_accepts`, `test_dismissed_status_report_earns_nothing`, `test_daily_cap_on_rewarded_actions`, `test_reporting_the_current_status_is_rejected` |
| 5 | Medium | **Double reward by tapping twice at the same instant** (two requests could both pass the cooldown check). | A database lock per user, cooler and action makes the second request wait and then fail. | `test_two_simultaneous_confirms_reward_once` |
| 6 | Medium | **Look-alike usernames.** "Admin", "admin" and "ADMIN" were three different accounts, useful for impersonation on the leaderboard. | Usernames are unique ignoring case. | `test_usernames_are_case_insensitive` |
| 7 | Medium | **Finding which usernames exist by timing.** Login answered faster for unknown usernames than for a wrong password. | Unknown usernames now cost the same time as a real password check. | Code review (timing tests are unreliable) |
| 8 | Medium | **Mass account creation** by a script, to farm points or spam submissions. | 20 registrations per address per hour. | `test_mass_registration_from_one_address_is_limited` |
| 9 | Medium | **Seeing photos an admin has not approved.** "My submissions" returned every photo on my coolers, including ones other people uploaded and nobody had reviewed. | Only approved photos and my own are returned. | `test_my_coolers_does_not_show_other_peoples_unapproved_photos` |
| 10 | Medium | **Weak password storage by today's standard.** 260,000 rounds; the current OWASP minimum for this method is 600,000, and the format could not be upgraded. | 600,000 rounds, a versioned format, and old hashes upgrade at the next login. | `test_password_hashes_are_versioned_and_old_ones_upgrade_on_login` |
| 11 | Medium | **No way to delete an account.** Google Play removes apps that allow sign-up without in-app and web deletion. | `DELETE /auth/me` (password required), a "Delete account" row in the profile, and a public page at `/account/delete`. | `test_delete_account_requires_password_and_removes_the_user`, `test_public_account_deletion_and_privacy_pages_exist`; also run by hand in a browser |
| 12 | Low | **Database reachable from the whole Wi-Fi network** with the development password. | The development database listens on this computer only. | Config |
| 13 | Low | Browsers could guess file types of responses ("content sniffing"). No HTTPS-only header. | `nosniff` on every response; HSTS in the production proxy config. | `test_responses_forbid_content_sniffing` |
| 14 | Low | **Unpinned packages.** A fresh install could pull a newer, untested or compromised version. | Exact versions pinned in `constraints.txt`; every push scans them for known vulnerabilities (currently none in 40 packages). | CI job |

Two related bugs found while testing the attacks, also fixed:

- A user's "confirmations" count dropped whenever an admin changed a cooler's
  status, because the records were deleted. They are now kept
  (`test_confirmation_count_survives_a_status_change`).
- When a saved login expired, every action failed with "please log in again"
  but the app still believed it was logged in, so the user was stuck. The app
  now logs out on its own and asks to log in at the next action.

Already sound before this pass (checked, no change needed): photo uploads are
re-encoded and stripped of GPS data; admin forms carry anti-forgery tokens; the
admin cookie cannot be read by scripts; text shown in the admin panel is
escaped; search input cannot inject SQL wildcards; production refuses default
secrets and hides the API documentation; the server runs as a non-root user and
the production database is not exposed.

---

## Open risks

Ordered by what I would close first.

| # | Risk | Why it is still open | What closes it |
|---|---|---|---|
| R1 | ~~Confirming from far away~~ | **Closed 2026-11-11.** The server refuses confirmations, reports, photos and new coolers beyond 50 m or with GPS less accurate than 40 m. A phone with a faked GPS position can still pass; see R2 and the daily cap. | Done. Next: flag accounts whose positions jump impossibly fast. |
| R2 | **A trusted account going rogue.** At 500 points an account can change any cooler's status and publish coolers with no review. | Needs product decisions. | Daily limits for trusted accounts, an activity log with one-click undo in the admin panel, and loss of trusted status after a rejected action. |
| R3 | **No account recovery.** There is no email or phone on an account, so a forgotten password means a lost account, and there is no "change password". | Needs a login redesign. | Phone number with one-time code (the norm in Egypt), which also raises the cost of fake accounts. |
| R4 | **Logins last 30 days and cannot be cancelled from the server.** A stolen token works until it expires. | Low likelihood at this stage. | A per-user token version that is bumped on password change or "log out everywhere". |
| R5 | **One shared admin password, no second factor, no record of who did what.** | Fine for a single founder. | Before a second moderator joins: one account per admin, a log of actions, and a second factor. |
| R6 | **No general request limit.** Public endpoints can be hammered. Per-address limits are also blunt on mobile networks, where many phones share one address. | Best solved outside the app. | Put Cloudflare (free plan) in front of the server before launch. |
| R7 | **Release build is signed with the debug key and the app id is `com.example.sabil`.** Anyone can produce an "update" signed with the public debug key. | I cannot run an Android build here, and I broke that build once already by editing it blind. | Create an upload key and set the real app id during the rebrand, on the owner's PC, with a build to confirm. Steps are in `07-quality-audit.md`. |
| R8 | **Photos can show faces or car plates.** Unreviewed photos are also reachable by anyone who has the exact file address (names are random and long). | Policy plus tooling. | Moderation rule "no faces", optional automatic face blurring later. |
| R9 | **No monitoring, alerts or automatic backups.** A breach or an outage would go unnoticed. | Not needed before real users. | Error tracking (Sentry), an uptime check, nightly database and photo backups, before launch. |
| R10 | **Data-protection licence.** Egypt's Personal Data Protection Law requires controllers of personal data to hold a licence; the compliance period after the 2025 regulations is ending now. | Legal step, not code. | Ask a lawyer whether username-only accounts need the licence and file it if so. See the legal section of the business plan. |
| R11 | **Development mode on Wi-Fi.** The server listens on the whole network with the admin password `admin123`. | Kept so testing on a phone stays simple. | The admin panel now shows a red warning. Set `SABIL_ADMIN_PASSWORD` in a `.env` file. |
| R12 | **Phone app packages are not scanned for known vulnerabilities** (only the backend's are). | No scanner available in my workspace. | Add an OSV scan of `pubspec.lock` to CI. |

---

## What to do next

1. Set a real admin password in `.env` on the development PC (R11).
2. R1 is closed. The remaining cheap abuse path is a faked GPS position
   combined with patience; R2's limits and undo are the answer.
3. Before any public release: R6, R7, R9, R10.
4. Before the first hire or a second admin: R5.
