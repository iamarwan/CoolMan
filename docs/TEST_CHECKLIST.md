# Test checklist: owner feedback round (2026-10-22)

Run once after updating. Tick each box; write down anything that looks wrong (a screenshot helps).

## 0. Update first

1. `git pull` in the `CoolMan` folder (branch `restructure`).
2. In `backend` with `(venv)` active: `pip install -r requirements.txt`, then `python -m scripts.sync_schema --apply` (adds the new `cups_enabled` column).
3. Start Docker (`docker compose up -d`), start the server (see GETTING_STARTED.md Step 2).
4. **Fully stop** the app and start it again with `flutter run` (a manifest change needs a full restart, not hot reload).

## 1. Permissions and location

- [ ] The app asks for location permission; after you allow it, no red "No location permissions" message appears.
- [ ] The map shows your position (set a Cairo point in the emulator: `...` > Location).
- [ ] Long-press the map: the add-cooler prompt appears and the app can place a cooler there.

## 2. Directions (Google Maps)

- [ ] Open a cooler, tap the Navigate arrow: it opens the **Google Maps app** with walking directions to the cooler. (On an emulator without Google Maps, the Google Maps page opens in the browser instead. Both are fine; OpenStreetMap should not open unless nothing else can.)

## 3. The cooler sheet

- [ ] Tapping a cooler opens a sheet that first shows **photos**, the name and the Navigate arrow. The status buttons are **not** visible yet.
- [ ] Swiping the photos works, and a "1 / N" counter shows when there is more than one.
- [ ] Tapping a photo opens it full screen; you can swipe and pinch-zoom.
- [ ] A cooler with no photos shows "No photos of this cooler yet" and an "Add the first photo" button.
- [ ] Sliding the sheet up shows status, freshness, then (if working and 60+ minutes since the last check) "Confirm: Still Working", then **Update condition**, "Add Status Evidence Photo", dedication and sponsor if there are any.
- [ ] Tapping **Update condition** opens a menu with Working, Empty and Broken. The cooler's **current** condition is highlighted with "Current" and a tick and **cannot be tapped**.
- [ ] Choosing another condition (log in first if asked) closes the sheet and shows "Status updated!".

## 4. Messages appear inside the sheet

- [ ] Report a status, then try to report another change on the same cooler right away: the "wait N minutes" message appears **in a red banner at the top of the sheet**, not behind it.
- [ ] Add a photo from the sheet: a green "Photo attached" banner appears in the sheet.
- [ ] While a request runs, a thin progress bar shows and the buttons are disabled.
- [ ] Stop the server and tap Update condition: the banner says it could not reach the server (not a blank failure).

## 5. Cups (admin switch)

- [ ] No cooler shows a "Cup Supplies" row at first.
- [ ] Open the admin screen (tap the app title 5 times, log in `admin` / `admin123`), Live tab, the ⋮ menu of a cooler: it has **"Cups: OFF (tap to show)"**. Tap it: a message says cups are now shown.
- [ ] Open that cooler on the map: the Cup Supplies row now shows. If the cooler has a sponsor, it ends with "· by <sponsor name>".
- [ ] Assign a sponsor to a **different** cooler: its cups row stays hidden (sponsoring must not switch cups on).
- [ ] Switch it off again: the row disappears.
- [ ] The add-cooler form no longer asks "Does it have clean cups?".

## 6. Quick regression

- [ ] Log in, log out, and the phone sign-in tab still opens (code is printed in the server terminal).
- [ ] Closing and reopening the app while the server is stopped does **not** log you out.
- [ ] The sponsor page contact button opens the dialer or the browser, or says "Could not open contact".

## If something fails

Send me the checklist number, what you saw, and (for crashes) the last lines of the `flutter run` terminal. Server errors appear in the `uvicorn` terminal.
