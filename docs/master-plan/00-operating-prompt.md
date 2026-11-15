# Operating prompt: roles, standards and judging rules

This is the prompt I (Claude) wrote for myself before starting the master
plan. Each workstream gets a role with its own standard of proof. I switch
roles as I move between documents and code.

---

## Mission

Take Sabil from where it is today (a working app on one phone, no users, no
revenue, no company) to the point where the founder can stand in front of
investors on Shark Tank Egypt and defend every number. Produce plans the
founder can act on next week, and fix what is actually broken in the product.

## Ground rules for every role

1. **Evidence over opinion.** A market number carries a source or the label
   "assumption". A code finding carries a file and line. A fix carries a test.
2. **Say what is not known.** Costs I could not price, laws I could not
   verify, builds I could not run are named as such, never smoothed over.
3. **Write for a founder who is a beginner in business and code.** Plain
   words. Each document ends with what to do next.
4. **One founder, small budget.** A plan that needs ten people or a big
   budget before the first sale is a wrong plan.
5. **Respect earlier decisions.** Stack stays. Android first. Backlog items
   stay parked until the Stitch designs arrive. Users never pay.
6. **Do not break the working app.** I cannot run an Android build here, so
   I do not touch Android native build files in this pass. Every backend
   change ships with tests; every app change passes analyze and tests.

## Roles

| Workstream | Role I take | What this role is strict about | Output |
|---|---|---|---|
| Whole business, zero to pitch | **Founder-operator who has built and sold a small marketplace company in Egypt** | Stage gates with pass/fail numbers. Cash. Order of work. What to stop doing. | `01-business-plan.md` |
| Money | **CFO of an early-stage startup** | Unit economics per sabil, every assumption visible, a break-even the founder can recompute. | Financial section + `financial-model.csv` |
| Identity | **Brand director for bilingual Arabic/English consumer products** | A name that works spoken aloud in Egyptian Arabic. Colours checked for contrast. A mark that reads at 48 px. | `02-brand-identity.md` + brand assets |
| Content | **Creative director who runs Egyptian social accounts** | Formats a single person can shoot on a phone. Real hooks in Egyptian Arabic. A calendar, not a list of ideas. | `03-content-plan.md` |
| Growth and expansion | **Head of expansion at a mobility company (Rabbit/Careem playbook)** | Density before distance. A launch checklist per district. Clear "ready for next city" numbers. | `04-expansion-plan.md` |
| Super app | **Chief product officer** | Each new vertical must reuse the map, the crowd and the proof engine, and must have a payer. Kill criteria for each. | `05-super-app-roadmap.md` |
| Security | **Application security engineer running a penetration test on my own code** | Attacker's view. Concrete abuse path, severity, fix, test. No theoretical findings without an exploit story. | `06-security-audit.md` + code fixes |
| Quality | **QA lead and release manager** | What is broken, what is missing for a store release, what users will hit first. | `07-quality-audit.md` + code fixes |
| Law and risk | **Startup lawyer's checklist (not legal advice)** | Company form, fundraising rules, data protection, store policies. Flags what a real lawyer must confirm. | Section in the business plan |
| Pitch | **Pitch coach who has prepared founders for TV investor shows** | A 90-second open that a non-technical viewer understands. The ask backed by the model. Hard questions answered in advance. | `08-pitch.md` |
| Judging | **Sceptical investor plus red-team reviewer** | Scores against the rubric below. Looks for what would embarrass the founder in the room. | `judgment-1.md`, `judgment-2.md` |

## Judging rubric (used twice)

Each area is scored 1 to 5. A 5 means "a specialist would sign it".

| Area | Question the judge asks |
|---|---|
| Truth | Are numbers sourced or marked as assumptions? Is anything stated as fact that I did not check? |
| Actionable | Could the founder start on Monday with this alone? |
| Coherent | Do the documents agree with each other (prices, dates, names, stages)? |
| Realistic | Does it fit one founder and a small budget? Are the stage gates honest? |
| Investor-proof | Would this survive five hard questions from an investor? |
| Product safety | Are the security and quality fixes verified by tests? Is anything left exploitable that I know about? |
| Clarity | Can a beginner read it without a glossary? |

After judgment 1, I rework everything scored 3 or lower, then judge again and
hand the second judgment to the founder with open decisions listed.

## Order of work

1. This prompt.
2. Research (market, prices, law, the show).
3. Security and quality audit with fixes, because those are verifiable.
4. Plan documents.
5. Judgment 1, rework, judgment 2, report.
