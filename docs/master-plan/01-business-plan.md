# Sabil business plan: from zero to the Shark Tank pitch

Roles: founder-operator, CFO, startup lawyer's checklist.
Version 1, 2026-11-11. Replaces the earlier draft `docs/business-plan.md`.

**How to read the numbers.** A figure with a source number like [3] comes from
the list at the end. A figure marked *assumption* is my estimate and must be
replaced by a real quote or real sales. Nothing here is legal advice; the legal
section says what a lawyer must confirm.

---

## 1. The business in one page

**What it is.** Sabil is a free map of public drinking-water coolers. People
find water near them, see if a cooler works, and confirm or report it in one
tap. The app runs today in English and Arabic.

**Who pays.** Not the users. The payers are people and organisations who
already spend money on public coolers as *sadaqa jariya* (ongoing charity),
very often in the name of a parent who died. Today they pay once and then have
no idea whether the cooler still works.

**What we sell.**
1. **Build a sabil:** we install a cooler in a chosen spot, with a dedication
   plaque, look after it for a year, and give the family a live page showing
   it works: confirmations by passers-by, photos, last check.
2. **Care plan:** a yearly plan that keeps a cooler working, for coolers we
   built (renewal) and coolers that already exist.
3. **Company networks (later):** a company funds many coolers under its name
   and gets impact reports.

**Why we win.** Anyone can sell a cooler. Only Sabil can show a donor, every
day, that strangers drank from it this morning. The crowd in the free app
produces that proof at no cost to us.

**Where it stands.** Working app and admin panel, tested on one phone. No
company, no users, no revenue. First sale has not been attempted.

**The plan.** Sell 5 to 10 sabils by hand before building anything more. Then
launch in one district, make sales repeatable, expand district by district,
and apply to Shark Tank Egypt once the numbers in section 3 are met.

---

## 2. Problem and evidence

| Who | Problem | Evidence |
|---|---|---|
| People working outside | Heat and no reliable free water. They do not know where a cooler is or whether it works. | Summer 2026 heat reached about 45°C in parts of Egypt and disrupted work [14]. Estimates of delivery riders alone run from about 2 million [12] to 6 million [13]; the two sources disagree. |
| Families who fund a cooler | They pay once, then have no proof it works and nobody maintains it. | Newspapers publish cooler price guides "for sadaqa jariya" [5], which shows steady demand. *Assumption to test:* that families will pay more for upkeep and proof. |
| Mosques, shops and buildings that own coolers | Upkeep is ad hoc; filters go unchanged. | *Assumption.* Must be checked by visiting 20 coolers in Maadi. |
| Companies | They want visible, measurable good works, especially in summer and Ramadan. | Delivery platforms run summer care campaigns for riders [15]. |

**What we do not know yet:** how many public coolers exist in any district, how
many are broken on a given day, and what families pay installers today. The
first two weeks of the plan answer these by walking Maadi with the app.

---

## 3. The road: six stages with pass/fail gates

Do not start a stage until the gate before it is passed. If a gate fails
twice, stop and rethink that stage, not the next one.

| Stage | When | What happens | Gate to pass |
|---|---|---|---|
| **0. Foundations** | Weeks 1 to 2 | Quotes from 3 cooler suppliers and 2 technicians. Walk Maadi and map every cooler (target 150). Lawyer's hour on company form and the fundraising rules. Pick the name. | A written price list with real costs. 150 coolers on the map. A lawyer's yes on selling "build and care" as a service. |
| **1. Prove someone pays** | Weeks 3 to 8 | Sell by hand: WhatsApp, Facebook groups, mosque communities, own network. Take payment by bank transfer or InstaPay with a one-page agreement. Install the first coolers. | **5 paid sabils** at a price that leaves at least 20% after all costs. If fewer than 5 after 40 serious conversations, change the price or the offer. |
| **2. Public launch in one district** | Months 3 to 5 | Company registered. Redesigned app in the Play Store with the new name. Patron pages. Content running (see `03-content-plan.md`). | 300 coolers mapped in the district, 1,000 monthly users, 60% of coolers confirmed in the last 7 days, 20 paid sabils in total. |
| **3. Make sales repeatable** | Months 6 to 9 | Care plans sold to owners of existing coolers using broken-cooler reports. First ops hire. In-app "build a sabil" request form. First company pilot (10 coolers). | 50 paid sabils, 30 care plans, one company pilot signed, a new customer acquired for less than 15% of the sale price. |
| **4. Expand** | Months 9 to 12 | Two more districts with the launch checklist in `04-expansion-plan.md`. Apply to the show. | 1,000 coolers mapped, 10,000 monthly users, 100 paid sabils, 70% of year-one customers say they will renew. |
| **5. Pitch** | When stage 4 gate is met | `08-pitch.md`. | Application accepted. |

The show accepts applications all year [1]. Apply at the stage 4 gate, not
before: a pitch without paying customers gets "come back when you have sales".

### The next 14 days, task by task

| Day | Task | Done when |
|---|---|---|
| 1 | Answer the 6 open questions in section 12 | Written down |
| 1 to 3 | Call 3 cooler suppliers: price for a 3-tap stainless unit, delivery, warranty, discount for 10 | 3 quotes |
| 2 to 4 | Find 2 technicians: price per visit, filter change, emergency repair | 2 quotes |
| 3 to 10 | Walk Maadi with the app; add every cooler; photograph each; note who hosts it and whether it works | 150 coolers |
| 5 | One paid hour with a startup lawyer (questions in section 9) | Notes |
| 6 | Put the real costs into `financial_model.py` and run it | New price list |
| 7 to 14 | Talk to 10 people who funded a cooler before: what they paid, what went wrong, would they pay for upkeep and proof | 10 conversations written up |
| 14 | Decide: go to stage 1, or change the offer | Decision |

---

## 4. Market size, built from the bottom

There is no reliable official figure for charitable giving in Egypt. The
figures in circulation range from a 2017 government study of about EGP 4.5
billion a year to much larger unofficial numbers [16]. I do not use them.

Instead, count what Sabil can actually serve:

| Layer | How it is counted | Size |
|---|---|---|
| Internet users in Egypt | DataReportal | about 98 to 99 million [10] |
| First district (Maadi) | *Assumption:* 150 to 300 public coolers | To be measured in stage 0 |
| Greater Cairo coolers | *Assumption:* 20,000 to 40,000 | Derived after stage 0 from coolers per km² |
| Sabils we can sell in year 3 | Model | 900 a year, about EGP 22 million |
| Care plans in year 3 | Model | about 1,800 coolers under care |

The honest statement for investors: "We do not know the national number.
Nobody does, which is the point of the map. In Maadi we counted X coolers in
Y km², Z% were not working, and W families bought from us in N weeks."

---

## 5. Competition

| Who | What they do | How we differ |
|---|---|---|
| Large charities (for example Orman's piped-water connections at EGP 6,800 each, payable in shares [7]) | Collect donations for water projects, mostly in villages. Report by news and photos. | We sell a service with continuous proof for one specific cooler the donor can visit. They are also potential partners (section 9). |
| Donation apps (MegaKheir lists a "water" category and over 170 charities [8]) | Payment channel to charities. | Same as above. A possible sales channel later. |
| Cooler shops and installers | Sell and install the unit. | No upkeep, no proof. They are our suppliers. |
| Water-finder apps abroad (Tap in the USA planned to earn from sponsored refills and adverts [17]; "Water Finder" lists public fountains worldwide [18]) | Maps of refill points. | None found for Egyptian coolers. Abroad the money was meant to come from adverts, which did not grow into a large business; ours comes from the donor. |
| Rahaa | Map of public toilets in Egypt and the Arab world [19]. | Shows the "map of free public essentials" idea has takers; a future partner or a vertical (see `05-super-app-roadmap.md`). |

No search result showed an app that maps Egypt's public coolers. That is a
finding from web searches on 2026-11-11, not proof that none exists; check the
Play Store before the pitch.

---

## 6. What we sell and what it costs

All figures in Egyptian pounds. Costs marked *assumption* come from retail
price guides, not supplier quotes.

### Building one sabil

| Item | Cost | Basis |
|---|---|---|
| 3-tap stainless street cooler | 9,000 | Retail guides show 5,500 to 10,000 and higher for premium units [5][6] |
| Filter housing and first cartridges | 1,000 | *Assumption* |
| Installation | 2,000 | *Assumption* |
| Plaque with QR code | 500 | *Assumption* |
| **One-time cost** | **12,500** | |
| Cartridges for a year | 1,800 | Sets at 450 to 500, three to four changes [20] |
| 12 technician visits at 250 | 3,000 | *Assumption* |
| Repairs reserve | 1,200 | *Assumption* |
| **Care cost per year** | **6,000** | |

### Prices and profit per sale

| Product | Price | Cost | Payment fees (2.5%, *assumption*) | Profit | Margin |
|---|---|---|---|---|---|
| Build a sabil (cooler, install, plaque, first year of care, proof page) | 24,900 | 18,500 | 623 | 5,778 | 23% |
| Care plan, one year | 9,900 | 6,000 | 248 | 3,652 | 37% |
| Company network, per cooler | 22,000 | 18,500 | 550 | 2,950 | 13% |

Things that are not in the price and must be agreed per site: **electricity
and water** (paid by the host: the mosque, shop or building) and **cups**.

**Is 24,900 too much?** A family can buy a cooler for about 9,000 and pay a
plumber. Our price is higher because it includes a year of upkeep and the
proof. Stage 1 tests exactly this. If it fails, the fallback is a cheaper
"care and proof only" offer for a cooler the family buys itself (the 9,900
plan), which also has the better margin.

**Ways to lift the margin:** buy coolers wholesale (10 or more at a time), one
technician route covering many coolers in the same district per day, and a
higher care price once renewals prove people value it.

---

## 7. Three-year model

Produced by `financial_model.py`; change the assumptions there and re-run.

| | Year 1 | Year 2 | Year 3 |
|---|---|---|---|
| New sabils sold | 60 | 240 | 600 |
| Company-network coolers | 0 | 40 | 300 |
| New care plans (existing coolers) | 40 | 200 | 500 |
| Renewals (70% renew, *assumption*) | 0 | 70 | 385 |
| Coolers under care at year end | 100 | 550 | 1,785 |
| **Revenue** | 1,692,000 | 8,539,000 | 27,826,500 |
| Direct costs | 1,272,300 | 6,413,475 | 21,155,662 |
| Gross profit | 419,700 | 2,125,525 | 6,670,838 |
| Gross margin | 24.8% | 24.9% | 24.0% |
| Running costs (team, marketing, tech, legal) | 330,000 | 1,750,000 | 4,250,000 |
| **Profit before tax** | 89,700 | 375,525 | 2,420,838 |

**Break-even in year 1:** 58 new sabils cover that year's running costs, with
the founder taking no salary. That is about five sales a month.

**What this model says plainly:**
- This is a service business with thin margins, made defensible by software.
  It is not a 70%-margin software company and should not be pitched as one.
- Year 1 only works if the founder is unpaid or has other income.
- The value builds in the number of coolers under care (recurring income) and
  in the map and its users, which make each next sale cheaper.
- The volumes are targets, not forecasts. Stage 1 gives the first real data
  point.

---

## 8. How customers find us

Detail is in `03-content-plan.md` and `04-expansion-plan.md`. The short form:

| Customer | Channel | Message |
|---|---|---|
| Families | WhatsApp and Facebook groups, mosque communities, funeral-season word of mouth, patron pages shared by earlier buyers | "A sabil in their name, and you can see every day that it is working." |
| Owners of existing coolers | A visit or call triggered by app reports | "Your cooler was reported broken three times this week. We can fix it today and keep it working." |
| Companies | Direct approach with the map's numbers | "Fifty coolers under your name, with a monthly report of how many people confirmed them." |
| App users | Content, QR codes on plaques, riders' groups | "Find free cold water near you." |

Every plaque carries a QR code to the cooler's page. Each sabil we build is an
advert for the next one.

---

## 9. Legal checklist (to confirm with a lawyer)

| Topic | What I found | Question for the lawyer |
|---|---|---|
| **Collecting donations** | Under the NGO law (149/2019), fundraising needs prior government approval and is done by registered associations; companies are mostly outside that law [9]. | "If my company sells installation and upkeep of a cooler to a customer who chooses to place it for public use, is that a normal sale? Which words must I avoid in adverts (donate, sadaqa shares)? Can several people split one sabil?" |
| **Pooled 'shares'** | Charities sell shares in water projects [7]. For a company this looks like collecting donations. | "Can I offer shares only through a registered charity partner?" |
| **Company form** | A one-person company can be formed by a single founder; recent guides give a minimum capital of EGP 1,000, older ones EGP 50,000 [11]. | "Which form fits, what does it cost in total, and which activity codes do I need (installation, maintenance, software)?" |
| **Personal data** | The Personal Data Protection Law (151/2020) got its regulations in November 2025; controllers generally need a licence, with a one-year period to comply that is ending now [21]. | "Do username-only accounts and photos need a licence? What if I add phone numbers later?" |
| **Placing coolers in public** | Not researched. | "What permission does a cooler outside a shop or mosque need from the district? Who is liable if someone is harmed by the water?" |
| **Water safety** | Not researched. | "What testing or filter standard should I document to protect the company?" |
| **Store rules** | Google Play requires in-app and web account deletion and a privacy policy [22]. Both exist as of this week. | None; done. |
| **Name** | Not checked. | Trademark search for the chosen name. |

Liability for water quality is the risk that could end the company. Before the
first installation: a written host agreement (who pays water and power, who
may switch it off), a filter-change log per cooler shown on the patron page,
and insurance advice.

---

## 10. Team and money needed

| Stage | People | Monthly cost (*assumption*) |
|---|---|---|
| 0 to 1 | Founder, technicians paid per job | Under 5,000 (transport, a lawyer's hour, small adverts) |
| 2 | Founder, part-time designer for content | 15,000 to 25,000 |
| 3 | Plus one operations coordinator | 30,000 to 40,000 |
| 4 | Plus one salesperson on commission, part-time developer | 70,000 to 90,000 |

Customers pay before installation, so each sabil funds itself. Outside money
is needed for stock bought in bulk, the first hires and marketing in new
districts, which is the case made in the pitch.

---

## 11. Risks

| Risk | How likely | What limits it |
|---|---|---|
| Families will not pay above the cooler's shop price | Medium. The single biggest unknown. | Stage 1 tests it with real money in 6 weeks. Fallback: care-and-proof plan. |
| Fundraising rules applied to us | Medium | Lawyer first; sell a service; shares only through a charity partner. |
| A cooler makes someone ill | Low, severe | Filter log, host agreement, insurance advice, quick "report a problem" in the app. |
| Coolers are stolen or vandalised | Medium | Hosts with a doorman or shopkeeper; repairs reserve; cage where needed. |
| The crowd does not confirm coolers | Medium | Start dense in one district; ask patrons' families to confirm; later, rewards from partners. |
| Fake confirmations | Medium | 50 m rule (planned), daily caps and limits (done), admin review. |
| A charity or a big app copies it | Low at first | Density of data and the installed base of plaques; partner with charities early. |
| Founder runs out of time or money | Medium | Stage gates keep spending near zero until customers pay. |
| Thin margin | Certain | Wholesale buying, routes, care renewals. |

---

## 12. Decisions the founder must make first

1. Is this a side project, or a company you intend to live from? The plan
   assumes the second from stage 2.
2. How many hours a week can you give for the next 3 months?
3. How much money can you risk before the first sale? The plan needs very
   little, but not zero.
4. Starting district: Maadi is assumed because the test data is there. Is
   that where you can walk the streets and know people?
5. Do you know a technician or an installer you trust?
6. Are you willing to sell in person? Stage 1 is 40 conversations.

---

## Sources

1. Shark Tank Egypt, official site and YouTube channel (applications open, panel): https://sharktank-egypt.com/ar and https://www.youtube.com/@SharkTankEgypt
2. "Shark Tank Egypt returns for season 4 after injecting over EGP 874 million into startups", MENA Startup Digest: https://menastartupdigest.com/shark-tank-egypt-returns-for-season-4-after-injecting-over-egp-874-million-into-startups/
3. Deal examples: https://exoskeletonreport.com/2023/03/exoskeleton-startup-cosmos-bionics-strikes-a-deal-on-shark-tank-egypt/ , https://menafn.com/1109150107/Egyptian-Startup-Hoods-Secures-EGP-5-Million-Investment-From-Shark-Tank , https://arabfounders.net/en/shark-tank-egypt-investments-2024/
4. Fan-maintained list of every pitch and deal: https://sharktank.ahmed-ibrahim.com/en/season/5/
5. El Watan, cooler prices for sadaqa jariya 2026: https://www.elwatannews.com/news/details/8344744
6. Cooler price guides: https://projectsegy.com/coldair-water-prices/ and https://www.pricesworld.net/%D8%A7%D8%B3%D8%B9%D8%A7%D8%B1-%D9%83%D9%88%D9%84%D8%AF%D9%8A%D8%B1-%D8%A7%D9%84%D9%85%D9%8A%D8%A7%D9%87
7. Orman Association, piped-water connection project: https://dar-alorman.com/Projects/Details/10
8. MegaKheir, water category: https://www.megakheir.com/charity-category/water
9. NGO law summaries: https://www.icnl.org/resources/civic-freedom-monitor/egypt and https://www.mondaq.com/terrorism-homeland-security-defence/1449102/overview-of-law-governing-non-governmental-organizations-in-egypt
10. DataReportal, Digital 2026: Egypt: https://datareportal.com/reports/digital-2026-egypt
11. Company forms: https://www.deel.com/blog/entity-setup-egypt/ and https://intelligence.dlapiper.com/global-expansion-corporate/?c=EG
12. The National, Cairo's delivery riders: https://www.thenationalnews.com/news/mena/2025/10/03/in-a-city-addicted-to-home-delivery-the-pilots-are-cairos-heroic-daredevils
13. Egyptian Streets, platform workers: https://egyptianstreets.com/2023/04/02/demanding-fairness-towards-better-conditions-for-egypts-digital-platform-workers/
14. Africanews, Egypt's heatwave strains workers, July 2026: https://www.africanews.com/2026/07/22/egypts-intense-heatwave-strains-workers-and-disrupts-economy/
15. Talabat summer kits for riders: https://economygates.com/35086/
16. Al Jazeera on charity figures in Egypt (2019): https://www.aljazeera.net/news/ebusiness/2019/5/26/إمبراطورية-تبرعات-رمضانية-بمصر
17. TechCrunch on Tap: https://techcrunch.com/2018/10/26/tap-a-new-startup-from-sam-rosen-wants-to-be-the-google-of-drinking-water
18. Water Finder app listing: https://apps.apple.com/iq/app/%D9%85%D9%83%D8%AA%D8%B4%D9%81-%D8%A7%D9%84%D9%85%D8%A7%D8%A1-%D8%AE%D8%B1%D9%8A%D8%B7%D8%A9-%D8%A7%D9%84%D8%AA%D8%B9%D8%A8%D8%A6%D8%A9/id6761177435?l=ar
19. Rahaa: https://rahaaa.com/
20. Filter prices: https://projectsegy.com/water-filter-prices/
21. Data-protection regulations: https://www.tamimi.com/law-update/general/articles/from-policy-to-practice-egypt-issues-executive-regulations-of-the-personal-data-protection-law/ and https://cms.law/en/are/legal-updates/egypt-s-pdpl-executive-regulations-issued-one-year-compliance-countdown-begins
22. Google Play account-deletion rule: https://support.google.com/googleplay/android-developer/answer/13327111
