# Phase 3 - Presentation Guide

> **Phase 3 rubric (typical asks):** RESTful API with CRUD on a record type;
> front-end pages that use those API routes; list, detail, delete (edit is
> bonus); zip + live demo. Adjust the timeline if your instructor gave a
> time cap.

This guide covers **what changed in Phase 3** and how to demo it. Phase 1
(stack + static pages) and Phase 2 (MineralFYI + USGS on `/gems` and
`/mines`) still apply — skim those guides for the opening if you need a
full “from zero” story.

**Written notes:** `docs/PHASE3_NOTES.md` (architecture, files, gotchas).

---

## 1. Roles

| Role         | Who   | What they do                                                          |
| ------------ | ----- | --------------------------------------------------------------------- |
| **Driver**   | _TBD_ | Browser demo + optional API tab + code files in editor                |
| **Narrator** | _TBD_ | API design, data model, why specimens, assignment checklist             |

Swap for the **code tour** so whoever opened the files narrates confidently.

---

## 2. Suggested timeline (~5–7 minutes)

| Time        | Section              | Beats                                                                 |
| ----------- | -------------------- | --------------------------------------------------------------------- |
| 0:00 – 0:45 | Intro                | Bedrock + Phase 3 goal: **our own API + DB**, not a 3rd-party API       |
| 0:45 – 1:30 | Architecture         | Same Rails app serves JSON + HTML; browser `fetch`es `/api/specimens` |
| 1:30 – 4:00 | Live demo            | Collection CRUD walkthrough (see §4)                                  |
| 4:00 – 5:30 | Code tour            | Routes → API controller → model → one view + JS client (see §5)       |
| 5:30 – end  | Wrap + submission    | Zip name, SQLite file, what’s next (auth, tip form, etc.)             |

If time is short, skip **Add specimen** in the demo and show **raw JSON** instead of the full code tour.

---

## 3. What to say — architecture & stack

**One-line pitch:**
> "Phase 3 asked for CRUD over our own records. We added a **Specimen**
> model in **SQLite**, exposed it as a **JSON REST API** under
> `/api/specimens`, and built a **Collection** section where every page
> loads and saves data through that API using `fetch` — still all **Rails
> 8**, no second backend."

**Why specimens (not bulldogs):**
> "The assignment used bulldogs as an example. We picked **mineral specimens**
> so the collection fits Bedrock’s gems-and-mines theme and reuses the same
> card styling as `/gems`."

**Request flow (30 seconds):**
> "The HTML page is a thin shell from `SpecimensController`. On load,
> JavaScript calls `GET /api/specimens`. The API controller reads
> ActiveRecord and returns JSON. For edits, the form sends `PATCH` with
> the CSRF token from the layout meta tag. Same database, two interfaces:
> humans in the browser, machines at `/api/specimens`."

**Phase 1 → 2 → 3 story (optional, 20 s):**
> "Phase 1 was static constants. Phase 2 pulled **external** APIs on
> `/gems` and `/mines`. Phase 3 is **our** API backed by **our** database."

---

## 4. Demo flow — Collection (CRUD)

Open **Collection** in the nav (or go to `/specimens`).

### List — `/specimens` (≈ 40 s)

- Point at the **Phase 3 · Collection** header and the card grid.
- Say: *"These cards are not rendered by Ruby on the server — the page
  fetches `GET /api/specimens` and builds the DOM in JavaScript."*
- Note **Mohs bar**, **gem SVG**, and **tint** matching the Gems page design.
- Mention **six seeded records** from `db/seeds.rb` (Diamond, Ruby, etc.).

### Detail — click any card (≈ 35 s)

- Hero with gradient + gem icon; field data panel; dark **field note** quote.
- Say: *"Detail is `GET /api/specimens/:id` — same pattern as list."*
- Optional: open **Raw JSON** link in the sidebar (or new tab to
  `/api/specimens/1`) for graders who want to see the API bare.

### Edit — bonus (≈ 45 s)

- Click **Edit**. Form loads current values from the API.
- Change something visible (e.g. color or field note) → **Save specimen**.
- Land on detail; point out the update.
- Say: *"`PATCH /api/specimens/:id` with a JSON body wrapped in `specimen`."*

### Delete (≈ 30 s)

- **Delete** → confirmation page with specimen preview.
- Confirm → redirect to list with green **removed** notice.
- Say: *"`DELETE /api/specimens/:id` — permanent, no soft-delete."*

### Create (≈ 35 s, if time)

- **Add specimen** → fill name + one field → save → new detail page.
- Back to list; new card appears.

### API-only beat (≈ 15 s, if skipping create)

- New tab: `http://localhost:3000/api/specimens`
- *"Full CRUD: GET list, GET one, POST, PATCH, DELETE — all JSON."*

**Assignment checklist aloud (10 s):**
> "List all, view one, delete with confirm, edit as bonus, front-end talks
> to our API routes — all checked."

---

## 5. Code tour — what to click

Stay shallow unless the rubric demands depth.

1. **`config/routes.rb`** (~20 s)
   - `namespace :api do resources :specimens`
   - HTML routes: `specimens`, `specimens/delete/:id`, `specimens/:id/edit`
   - *"REST for machines, friendly URLs for humans."*

2. **`app/controllers/api/specimens_controller.rb`** (~25 s)
   - Show `index`, `show`, `create`, `update`, `destroy`.
   - `specimen_params` permits fields; returns JSON.

3. **`app/models/specimen.rb`** + **`db/schema.rb`** (~20 s)
   - Validations on name and Mohs.
   - *"SQLite in `storage/development.sqlite3`."*

4. **`config/initializers/inflections.rb`** (~15 s, optional but memorable)
   - `irregular "specimen", "specimens"`
   - *"Rails wanted table `specimen`; our migration created `specimens` —
     this one line fixed seeding."*

5. **`app/views/specimens/index.html.erb`** + **`_api_client.html.erb`** (~25 s)
   - Show `BedrockApi.fetchJson("/api/specimens")` and card HTML built in JS.
   - *"Front-end requirement: pages call API routes, not server-rendered rows."*

6. **`scripts/setup-and-run.ps1`** (~10 s, optional)
   - `db:migrate` then `db:seed` before server start.
   - *"Double-click `start-dev.bat` and the collection is ready to demo."*

---

## 6. Submission & grading tips

- Zip the **repo root** (not just `app/`): `TeamName_Rails_Phase3.zip`.
- Grader machine: **`start-dev.bat`** should migrate, seed, and serve on port 3000.
- If styling looks broken on their PC: mention `ruby bin\rails tailwindcss:build`.
- Offline demo works — no external API required for Collection (unlike Phase 2).

---

## 7. Likely questions

| Question | Short answer |
| -------- | ------------ |
| Why not use Rails `resources` views only? | Assignment asked for an API **and** front-end that **uses** API routes; `fetch` makes that obvious in the demo. |
| Could Postman test this? | Yes — same endpoints; need CSRF only for browser POST/PATCH/DELETE from our pages. |
| Is this separate from Phase 2 APIs? | Yes. Phase 2 = external HTTP. Phase 3 = internal REST + SQLite. |
| What’s next? | Wire tip form to DB, auth, maybe expose API docs or pagination. |

---

## 8. Pre-demo checklist

- [ ] `start-dev.bat` finished without exit code 6
- [ ] Log shows **Seeded 6 specimens**
- [ ] `/specimens` shows six cards (not spinner forever)
- [ ] Edit + delete tested once this session
- [ ] Know your team name for the zip filename
- [ ] Phase 2 pages still load (optional: quick reload `/gems` if grader asks about earlier work)
