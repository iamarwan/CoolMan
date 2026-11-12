# Judgment 1

Role: sceptical investor and red-team reviewer, judging my own first pass.
Date: 2026-11-12. Rubric from `00-operating-prompt.md`. Scores are 1 to 5;
5 means a specialist would sign it.

Nothing has been reworked after this judgment. It waits for the owner.

## Verdict in three lines

- **The product work is solid and checked.** Security fixes, the 50 m rule and
  the Nwasy redesign are tested and were exercised in a browser. One gap: the
  redesigned app has not been built or run on a real Android phone.
- **The plans are well-structured but rest on assumptions.** Not one price,
  cost or customer in them is real yet. They are a good map of what to find
  out, not evidence that the business works.
- **The identity is the weakest part.** There is a name and a written
  direction, but no logo and nothing to look at.

## Scores

| Area | Truth | Actionable | Coherent | Realistic | Investor-proof | Clarity | Overall |
|---|---|---|---|---|---|---|---|
| 01 Business plan | 3 | 4 | 4 | 3 | 2 | 4 | **3** |
| 02 Brand identity | 4 | 2 | 3 | 4 | 2 | 4 | **2.5** |
| 03 Content plan | 3 | 4 | 4 | 4 | n/a | 4 | **3.5** |
| 04 Expansion plan | 2 | 3 | 4 | 3 | 3 | 4 | **3** |
| 05 Super-app roadmap | 3 | 3 | 4 | 3 | 3 | 4 | **3** |
| 06 Security audit and fixes | 5 | 4 | 4 | 4 | 4 | 4 | **4.5** |
| 07 Quality audit and redesign | 4 | 4 | 4 | 4 | 3 | 4 | **4** |
| 08 Pitch | 3 | 3 | 4 | 3 | 2 | 4 | **3** |

## What I would attack, document by document

### 01 Business plan (3)

- **Every cost is a guess.** Installation, technician visits, plaque and
  payment fees are my estimates; the cooler price is from retail guides, not a
  supplier. A 20% error in cost removes most of the 23% margin.
- **No customer has been asked.** "Families will pay 24,900 for a sabil with
  proof" and "vendors will pay 250 a month" are the two beliefs the whole plan
  stands on. Both are untested.
- **Two businesses for one founder.** Installing and maintaining coolers is an
  operations company. Vendor subscriptions are a software company. The plan
  orders them, but a part-time founder doing both is a real risk and I may be
  understating it.
- **Year-1 volumes are ambitious.** 60 sabils means more than one sale a week
  from a standing start. The running-cost line (330,000 for the year) is thin.
- **Legal gaps I did not research:** permission to place coolers in public,
  liability for water quality, whether unlicensed vendors can be listed, and
  whether the data-protection licence applies. Each could change the plan.
- **Market size is honest but empty.** I refused to quote unreliable numbers,
  which is right, but it leaves no figure until Maadi is walked.

### 02 Brand identity (2.5)

- **No logo and no visual board.** I drew a board earlier for the old name and
  a blue palette, then removed it when the name and designs changed. I did not
  redraw it. An identity you cannot see is half done.
- **The Latin spelling is unresolved** ("Nwasy" or "Nawasy"), and no
  trademark, store or domain check has been made.
- **I flagged a real problem and did not fix it:** the brand teal sits close
  to the "working" green, and two status colours fail the contrast standard
  for small text. The app follows the Stitch palette as given.
- The owner said earlier he disliked the first palette and logo. This document
  does not yet give him something better to choose from.

### 03 Content plan (3.5)

- Usable as written: pillars, formats, a weekly rhythm and a first month.
- **The Arabic hooks are mine and unreviewed by a native speaker.**
- Nothing has been filmed, so which format works is unknown.
- The fact-card numbers in the examples are invented placeholders.

### 04 Expansion plan (3)

- The "one district at a time" rule and the launch checklist are sound.
- **The district order, the cost of 20,000 per district and the "ten coolers
  per technician day" figure are assumptions.** No district has been walked.
- Waves 3 to 5 are speculation and are labelled as such.

### 05 Super-app roadmap (3)

- The four tests and the kill rules keep "super app" from becoming a wish list.
- **Nothing of layer 2 is built.** It needs phone login, notifications, share
  links and a data change (cooler becomes "place") first. That is months of
  work I have described but not scheduled in detail or estimated.
- The claim that vendors will check in daily is the heart of it and is untested.

### 06 Security (4.5)

- Strong: 15 attacks written as tests, all now failing as they should; no
  known vulnerabilities in pinned packages; checks run on every push.
- **Still open:** a faked GPS position defeats the 50 m rule; trusted accounts
  have no limits or undo; no account recovery; one shared admin password; no
  monitoring or backups; the release is signed with the debug key.
- I could not test on a real device or a real HTTPS deployment.

### 07 Quality and the redesign (4)

- 55 backend tests and 34 app tests pass; the main flows were run in a browser
  with a simulated position, in English and Arabic.
- **Not verified:** an Android build of the redesigned app. I cannot build one
  here, and the font and new screens have never run on a phone. The owner's
  last APK size was never reported either.
- Two files are over the size target (542 and 586 lines).
- Several things in the Stitch designs were left out because the data does not
  exist (saved coolers, activity feed, filter specs, ratings, patron stories).
  They are listed in `docs/backlog.md`, but the app is not a full match for
  the designs.
- The server settings still carry the old `SABIL_` name, and the Android app
  id is still `com.example.sabil`.

### 08 Pitch (3)

- Structure, hard questions and practice plan are usable.
- **Every number in it is a bracket.** The ask (4 million for 15%) is built on
  targets, not results, and I could not confirm the show's current season,
  panel or terms.
- "Why you?" is left blank on purpose; only the founder can answer it.

## Does it all agree with itself?

Mostly. Prices, stage gates, district costs and the pitch figures match the
financial model. Known loose ends:

- "Sabil" remains as the word for a dedicated cooler (correct), but also in
  setting names and the Dart package (leftover).
- The content plan's sample numbers are not tied to the model.
- The operating prompt said backlog items stay parked until the designs
  arrive; they arrived mid-run, so three of them are now built.

## What I would do next, if asked (not started)

1. Draw the Nwasy identity board: three logo marks and two or three palettes
   shown on the real screens, so there is something to choose.
2. Fix the two colour issues in the app once a palette is chosen.
3. Add an Android build to the automatic checks, so a broken build is caught
   before it reaches the owner's PC.
4. Split the two oversized files; rename the `SABIL_` settings.
5. Turn the super-app roadmap's first steps into an estimated work plan.
6. Tighten the business plan after real quotes and the first 20 conversations.

## Decisions only the owner can make

1. **Spelling:** Nwasy or Nawasy.
2. **Colour:** keep the teal from Stitch, or test a brand colour further from
   the status green.
3. **Which business first:** start selling sabils by hand now (cash, but
   operations), or put all effort into users and vendors (software, but no
   income for months). The plan assumes sabils first.
4. **The six questions** in section 12 of the business plan: time, money,
   district, technician, willingness to sell in person.
5. **Which of the six "next" items above to do**, and in what order.
6. **Test on your phone:** pull, rebuild with `build_apk.ps1`, and report the
   APK size and what you see.
