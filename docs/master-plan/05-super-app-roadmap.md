# Nwasy super-app roadmap

Role: chief product officer.
Date: 2026-11-11.

## What "super app" means here

Not "an app that does everything". Nwasy is **one map of the things you look
for on foot that regular maps miss**: places with no address, places that move,
and places whose status changes by the hour.

Every layer must pass four tests before it is built:

1. **It reuses the map.** Same home screen, a new filter and pin style.
2. **It reuses the crowd.** People nearby can add and confirm it.
3. **It reuses the proof.** "Be there" (the 50 m rule) decides what is trusted.
4. **Someone pays, or it clearly feeds a layer where someone pays.**

A layer that fails a test is not built, however good the idea sounds.

## The layers

| # | Layer | What the user gets | Who keeps it accurate | Who pays | When |
|---|---|---|---|---|---|
| 1 | **Water** (built) | Nearest working cooler, cups, last confirmed | Passers-by, within 50 m | Families and cooler owners (sabil and care plans) | Now |
| 2 | **Street food and coffee** | Food trucks, coffee and tea carts, juice stands: where they are *today* and whether they are open | The vendor checks in from the spot each day; customers confirm | Vendors (paid plan) | Free listings from the public launch; paid from stage 3 |
| 3 | **Street essentials** | Public toilets, shaded seats, prayer spaces, phone charging, tyre and bike repair | Passers-by | Nobody directly; raises daily use | After layer 2 works in one district |
| 4 | **Seasonal** | Ramadan free-iftar tables, Eid markets, summer cooling points | Organisers and passers-by | Companies sponsoring the season's layer | First Ramadan after launch |
| 5 | **Order ahead** | Order and pay before you reach the cart | Vendor | Commission per order | Only after layer 2 has paying vendors in three districts |

Layers 3 to 5 are options, not promises. Each has a kill rule below.

## Layer 2 in detail: street food and coffee

**The problem only Nwasy solves.** A cart moves. Today it is at the metro
exit, tomorrow by the school. Google Maps shows a fixed dot that is often
wrong. The vendor's own "be there" check-in fixes that: when the vendor taps
"Open here" from the cart, the pin moves to that corner and shows as open,
verified by the phone's position.

**What gets built**

| Piece | Detail |
|---|---|
| Place types | A cooler becomes one kind of "place". New kinds: food truck, coffee cart, juice stand. Each has its own icon and colour family; status colours stay the same everywhere. |
| Vendor account | A vendor claims a place by checking in at it. One phone number per vendor (needs phone login, see security R3). |
| Open here | One button. Works only within 50 m of where the vendor says they are. Closes by itself at night. |
| Customer confirmation | "It's open" / "Not here", with the same points and limits as water. |
| Vendor page | Photos, a short menu with prices, hours, a follow button. |
| Followers | "Your coffee cart is open on Road 9" as a notification (needs push notifications). |
| Paid plan | Highlighted pin, top of the list in its category nearby, menu and photo slots, weekly numbers (views, taps on directions, followers). |

**Order of work**

1. Rename "cooler" to "place" in the data, with a type field. The map, pins,
   sheets, trust rules and admin panel already work per place.
2. Category filter on the map ("Water", "Food", "Coffee").
3. Vendor check-in and vendor page.
4. Free for everyone until a district passes 1,000 monthly users; then offer
   the paid plan there.

**Numbers to hit before charging in a district:** 1,000 monthly users, 50
vendors listed, 40% of them checking in at least three days a week.

**Kill rule:** if after three months of free listings in the launch district
fewer than 20 vendors check in weekly, vendors do not value it; stop and
return to water and essentials.

## Layer 3: street essentials

Low cost because it is only new place types on the same map. Start with public
toilets (Rahaa already maps some; propose sharing data rather than competing).

**Kill rule:** a type with fewer than 30 places and 100 views a week in the
launch district after two months is hidden.

## Layer 4: seasonal

Ramadan is when giving and going out both peak. A "free iftar tables" layer
for 30 days is cheap, widely shared, and a natural thing for a company to
sponsor.

**Kill rule:** none needed; it switches off by date.

## Layer 5: order ahead

This is where "super app" starts to mean payments. It needs a payment partner,
refunds and support, so it waits for real demand.

**Start rule:** 200 paying vendors and at least 30% of them asking for it.

## What must exist before any new layer

| Need | Why | Status |
|---|---|---|
| Phone-number login | One vendor, one account; fewer fake accounts | Not built |
| Push notifications | Followers and "your cooler was approved" | Not built |
| Share links that open the app | Vendor and patron pages spread by link | Not built |
| Admin: user list and action log | More contributors means more abuse to handle | Not built |
| Place types in the data | Everything above | Not built; the first technical step |
| Numbers dashboard | To know when a rule is met | Not built |

## What Nwasy will not become

- A delivery app. Couriers, restaurants with kitchens and fees are other
  companies' business.
- A reviews site. Status and proof, not star wars.
- A social network. Usernames and points are enough.

## Next 3 product steps

1. Phone login and push notifications (they unblock layers 2 and the patron
   reports).
2. Place types and the category filter.
3. Vendor check-in and vendor page, tested with 10 vendors in Maadi.
