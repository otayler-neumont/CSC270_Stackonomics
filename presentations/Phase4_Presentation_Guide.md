# Phase 4 — Presentation Guide

> **Phase 4 rubric:** stand up a **database**, build a **Data Access Layer (DAL)**,
> and route every API call that needs persistence **through the DAL** — not
> directly to the model. The assignment example uses bulldogs; we use
> **specimens** (same CRUD stack from Phase 3, new persistence architecture).
>
> **Class notes (May 28):** the prof wants you to **cover your tables, cover
> your database, cover your data access layer** in detail. There is a lot to
> show — aim for **4½–5½ minutes**. You probably **do not need to walk through
> the Terraform stack**; spend that time on persistence instead.
>
> **Written notes:** [`docs/PHASE4_PERSISTENCE.md`](../docs/PHASE4_PERSISTENCE.md)
> (architecture, route → DAL → SQL mapping, verification).

This guide covers **what changed in Phase 4** and how to demo it. Phase 3
(Collection CRUD + `/api/specimens`) still applies for the live UI beat — skim
[`Phase3_Presentation_Guide.md`](Phase3_Presentation_Guide.md) if you need the
full CRUD walkthrough. **This talk is about the layer under the API.**

---

## 1. Roles

| Role         | Who   | What they do                                                                 |
| ------------ | ----- | ---------------------------------------------------------------------------- |
| **Driver**   | _TBD_ | Browser + terminal smoke test + code files in editor                         |
| **Narrator** | _TBD_ | Tables, database setup, DAL contract, route → repository mapping             |

Swap for the **code tour** so whoever opened the files narrates confidently.

---

## 2. Suggested timeline (4½–5½ minutes)

Per the prof's guidance: persistence first, Terraform optional at the end.

| Time          | Section              | Beats                                                                 |
| ------------- | -------------------- | --------------------------------------------------------------------- |
| 0:00 – 0:30   | Intro                | Bedrock, Phase 4 goal: **explicit DAL + real DB persistence**         |
| 0:30 – 1:15   | Architecture         | Controller → DAL → Model → DB; dev vs prod adapters (see §3)          |
| 1:15 – 2:30   | **Tables + database**| Migration, schema, seeds, `database.yml`, prod Postgres (see §4)       |
| 2:30 – 4:00   | **Data access layer**| `SpecimenRepository`, controller refactor, grep proof (see §5)        |
| 4:00 – 4:45   | Live proof           | Quick UI + `dal-smoke.ps1` or create → restart → still there (see §6) |
| 4:45 – 5:15   | Wrap                 | Rubric checklist aloud, zip name, what's next (Phase 5 auth)          |

**If you're running long:** cut the Collection UI demo to 20 s and skip the
Terraform mention entirely. **If you're short:** run `dal-smoke.ps1` live —
it's the fastest way to prove all five routes hit the DAL.

**If time is tight:** skip edit/create in the browser; the smoke script covers
POST/PATCH/DELETE in one shot.

---

## 3. What to say — architecture (45 s)

**One-line pitch:**
> "Phase 4 asked us to add persistence with a named **Data Access Layer**.
> We kept the same five REST endpoints from Phase 3, but **no controller
> calls `Specimen` directly anymore** — everything goes through
> `SpecimenRepository`. Dev and test stay on **SQLite**; production runs
> **Postgres 16** in Docker, wired by `DATABASE_URL`."

**Request flow (30 s — say this while showing the diagram or pointing at files):**
> "HTTP hits `Api::SpecimensController`, which only handles params, status
> codes, and JSON. It calls `SpecimenRepository.all`, `.find`, `.create`,
> `.update`, or `.destroy`. The repository is the **only** place that touches
> ActiveRecord. The model validates; Postgres or SQLite stores the row."

**Phase 3 → 4 story (optional, 15 s):**
> "Phase 3 gave us CRUD and the Collection UI. Phase 4 **refactored persistence**
> behind a repository and **promoted production to Postgres** so data survives
> container restarts on our deployed VM."

**Do not spend time here on:** multi-stage Dockerfile, OCI vs GCP, cloud-init,
security lists — unless the grader asks. One sentence max: *"Production is
containerized with Postgres on our cloud VM; local dev is still
`start-dev.bat` + SQLite."*

---

## 4. Code tour — tables & database (~75 s)

This is the section the prof called out. Click these files **in this order**.

### 4a. The table — migration + schema (~35 s)

1. **`db/migrate/20260521120000_create_specimens.rb`** (~20 s)
   - Walk the columns aloud: `name` (required), `color`, `mohs` (decimal),
     `origin`, `fact`, `tint` (default `"slate"`), timestamps.
   - Point at `add_index :specimens, :name`.
   - Say: *"Migrations are the version-controlled source of truth for schema
     changes. We never hand-edit the live database."*

2. **`db/schema.rb`** (~15 s)
   - Show the generated `create_table "specimens"` block — same shape as the
     migration, now the snapshot Rails uses for `db:schema:load`.
   - Say: *"This is what actually exists in the database after migrate."*

### 4b. Seed data (~15 s)

3. **`db/seeds.rb`**
   - Six starter rows: Diamond, Ruby, Sapphire, Emerald, Opal, Amethyst.
   - Say: *"Idempotent — `find_or_create_by!` on name, so re-running seed
     doesn't duplicate rows. Grader gets a populated collection on first boot."*

### 4c. Database configuration (~25 s)

4. **`config/database.yml`**
   - **development / test:** `adapter: sqlite3` → `storage/development.sqlite3`
   - **production:** `adapter: postgresql`, `url: <%= ENV["DATABASE_URL"] %>`
   - Say: *"Developers don't need Postgres or libpq locally. Production reads
     `DATABASE_URL` injected by Docker Compose."*

5. **`docker-compose.prod.yml`** (db service only — ~20 s, optional but strong)
   - `postgres:16-alpine`, env vars, **`pgdata` named volume**.
   - Say: *"The DB is a sidecar on an internal network — no public port.
     Data lives in the `pgdata` volume, so rebuilding the web container
     doesn't wipe rows."*

6. **`bin/docker-entrypoint`** (~10 s, if time)
   - Runs `rails db:prepare` before the server starts.
   - Say: *"Create DB if missing, migrate, seed — zero manual steps on deploy."*

---

## 5. Code tour — Data Access Layer (~90 s)

This is the other section the prof wants depth on.

### 5a. The DAL itself (~40 s)

1. **`app/repositories/specimen_repository.rb`**
   - Read the header comment: controllers **must not** call `Specimen.<anything>`.
   - Walk each method and tie it to HTTP:
     - `all` → `GET /api/specimens`
     - `find(id)` → `GET /api/specimens/:id`
     - `create(attrs)` → `POST`
     - `update(id, attrs)` → `PATCH`
     - `destroy(id)` → `DELETE`
   - Say: *"Same contract as the rubric's Java `dal.getAllBulldogs()` example —
     expressed idiomatically as a Ruby module with `module_function`."*
   - Note: errors bubble up; `Api::BaseController` already maps
     `RecordNotFound` / `RecordInvalid` to JSON — the DAL stays thin.

### 5b. Controller uses the DAL (~25 s)

2. **`app/controllers/api/specimens_controller.rb`**
   - Show `index` → `SpecimenRepository.all`, `create` → `.create`, etc.
   - Say: *"Search this file for `Specimen.` — you won't find it. HTTP
     concerns only."*

### 5c. Model stays below the DAL (~15 s)

3. **`app/models/specimen.rb`**
   - Validations on `name`, `mohs`, `tint`; `as_json` for Mohs as float.
   - Say: *"The model defines shape and rules. Only the repository executes
     queries."*

### 5d. Grep proof (~10 s — very memorable)

4. **Terminal or Cursor search:** `Specimen.` in `app/`
   - Expected: **only** `app/repositories/specimen_repository.rb`.
   - Say: *"That's our enforcement — one file owns all DB access for specimens."*

### Route → DAL cheat sheet (have this visible or memorized)

| HTTP                       | DAL method                          | SQL (conceptually)                    |
| -------------------------- | ----------------------------------- | ------------------------------------- |
| `GET /api/specimens`       | `SpecimenRepository.all`            | `SELECT * … ORDER BY name`            |
| `GET /api/specimens/:id`   | `SpecimenRepository.find(id)`       | `SELECT * … WHERE id = ?`             |
| `POST /api/specimens`      | `SpecimenRepository.create(attrs)`  | `INSERT INTO specimens …`             |
| `PATCH /api/specimens/:id` | `SpecimenRepository.update(…)`      | `UPDATE specimens SET … WHERE id = ?` |
| `DELETE /api/specimens/:id`| `SpecimenRepository.destroy(id)`    | `DELETE FROM specimens WHERE id = ?`  |

---

## 6. Live demo — persistence proof (~45 s)

Pick **one** path. Path A is best for grading; Path B is faster.

### Path A — DAL smoke test (recommended, ~45 s)

With the dev server running (or against production):

```powershell
.\scripts\dal-smoke.ps1
# or: .\scripts\dal-smoke.ps1 -BaseUrl http://<your-vm-ip>
```

Narrate as it runs:
> "Each step labels the repository method — GET all, POST create, GET find,
> PATCH update, DELETE destroy, then a 404 on the deleted id. Passing means
> **controller → DAL → ActiveRecord → database** works for every route."

Point at the final line: **`=== DAL smoke test PASSED ===`**

### Path B — Browser + persistence (~45 s)

1. Open **`/specimens`** — six seeded cards (proves DB has data).
2. **Add** or **edit** one specimen; show the change on detail/list.
3. Say: *"Same five API routes as Phase 3 — now every call goes through
   `SpecimenRepository` before it hits Postgres or SQLite."*

Optional production beat (10 s): *"On our VM, this is Postgres in Docker;
the `pgdata` volume keeps rows across container restarts."*

---

## 7. Rubric checklist — say aloud (~15 s)

> "**Database:** `specimens` table via migration, SQLite locally, Postgres in
> production. **DAL:** `SpecimenRepository` — the only place that calls
> `Specimen`. **API routes:** all five CRUD endpoints go through the DAL, not
> ActiveRecord in the controller. **Persistence:** seeds on boot, smoke test
> proves round-trip, data survives restarts in prod."

---

## 8. Submission & grading tips

- Zip the **repo root** as `TeamName_Rails_Phase4.zip` (use your team identifier).
- Grader local path: **`start-dev.bat`** → migrate, seed, serve on port 3000.
- Point them at **`.\scripts\dal-smoke.ps1`** for one-command DAL verification.
- If they ask about production: give your VM **`app_url`** (from `terraform output
  app_url`) — Collection should load and API should respond the same as local.
- Offline demo works for the rubric core (DAL + SQLite); smoke test needs no
  external APIs.

---

## 9. Likely questions

| Question | Short answer |
| -------- | ------------ |
| Why a repository instead of calling ActiveRecord in the controller? | Phase 4 rubric requires an explicit DAL; one module owns all specimen DB access and can evolve (cache, swap store) without touching controllers. |
| Is this different from Phase 3's API? | Same URLs and JSON shape; Phase 4 **refactored** persistence behind `SpecimenRepository` and added Postgres for production. |
| Why SQLite dev + Postgres prod? | No local Postgres install; production matches real deploy with Docker + `DATABASE_URL`. |
| Where is `Specimen` queried besides the DAL? | `db/seeds.rb` uses `Specimen` for bootstrapping only — acceptable; runtime app code goes through the repository. |
| Could you show the Terraform stack? | Briefly: VM + Docker Compose + Postgres sidecar. Persistence story is migration → DAL → smoke test. |
| What's Phase 5? | Users, sessions, membership — same repository pattern for `UserRepository`, etc. |

---

## 10. Pre-demo checklist

- [ ] `start-dev.bat` finished without errors; log shows **Seeded 6 specimens**
- [ ] `/specimens` shows six cards (not a forever spinner)
- [ ] `.\scripts\dal-smoke.ps1` passed once this session
- [ ] Files open and tabbed in editor: migration → schema → `database.yml` →
      `specimen_repository.rb` → `api/specimens_controller.rb`
- [ ] Grep `Specimen.` in `app/` — only the repository file
- [ ] Know production URL if demoing the live VM
- [ ] Phone timer rehearsed once at **~5:00** (hard ceiling ~5:30)

---

## 11. One-page talk track (print this)

**Intro (30 s):** Phase 4 = database + DAL. Specimens, same REST API as Phase 3.

**Architecture (45 s):** Controller → `SpecimenRepository` → `Specimen` → SQLite/Postgres.

**Tables (75 s):** Migration columns + index → `schema.rb` snapshot → seeds →
`database.yml` adapters → prod `pgdata` volume + `db:prepare` on boot.

**DAL (90 s):** Repository methods map 1:1 to five routes; controller has zero
`Specimen.` calls; grep proves it; model = validations only.

**Demo (45 s):** Run `dal-smoke.ps1` OR quick Collection edit; point at PASSED.

**Wrap (15 s):** Database ✓ DAL ✓ all routes through DAL ✓ persistence ✓ thanks.

**Total: ~4:30–5:30**
