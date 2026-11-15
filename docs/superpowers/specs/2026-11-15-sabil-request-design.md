# Build-a-sabil request (in the app)

Replaces selling sabils by hand on WhatsApp: a person fills a form in the app,
the request lands in the admin panel as a lead, and the team calls them back.

## Decisions

| Point | Choice | Why |
|---|---|---|
| Who can send | Logged-in users only | Ties the request to an account, so the user can follow it and the rate limit works |
| Payment | None in the app | Prices are not validated yet; the team quotes after a call or site visit |
| Prices shown | None; the team enters a quote in the admin panel and the user sees it | Prices can change without an app update |
| Limit | 5 requests per user per day | Stops a script filling the list; a real customer sends one or two |
| Account deletion | Deletes the user's requests | Keeps the privacy promise simple (privacy page updated) |
| Option codes | Plain strings checked by the API (`app/schemas.py`) | New options need no database migration |

## The form (four parts, one scrolling page)

1. **What to build:** package (full sabil, care plan, company network with a
   number of coolers), taps (2 to 4), extras (filter, shade, cup holder, night
   light), timing.
2. **Who it is for:** purpose, name on the sabil, plaque text, show the name in
   the app or not.
3. **Where:** governorate (all 27), area, street and landmarks, optional current
   location, type of place, permission for the spot, electricity and water pipe
   nearby.
4. **Contact:** name, Egyptian mobile (normalised to 01xxxxxxxxx, Arabic digits
   accepted), call or WhatsApp, best time, notes.

Entry points: Account tab (card, and "My sabil requests"), and the patron page
of a sponsored cooler ("Build one like this").

The form is a non-lazy scroll view on purpose: a lazy list drops the top parts
when the user scrolls, losing their answers and skipping their validation
(caught in a browser run; covered by a test).

## Admin panel

`/admin/requests`: tabs by status (open, new, contacted, site visit, quoted,
won, lost, all) and a badge with the number of new requests in the top bar.
Each request has call and WhatsApp buttons, every answer in English, a map
link, and a follow-up form (status, quote in EGP, team notes that the customer
never sees).

## Not done

- No notification to the team when a request arrives (check the badge), and
  none to the user when the status changes.
- No payment or deposit in the app.
- Package names and contents follow the business plan and are not final.
