# Phase 3 — Change notes (Stackonomics / Bedrock)

Summary of what we added for the CSC270 Phase 3 assignment: a RESTful API with
full CRUD, HTML pages that call that API from the browser, and SQLite persistence.

---

## Assignment mapping

| Rubric item | How we implemented it |
| ----------- | ---------------------- |
| RESTful API with CRUD | `Api::SpecimensController` at `/api/specimens` (JSON) |
| Pick a record type | **Specimens** — mineral entries in our collection (on-theme vs. generic “bulldogs”) |
| List all records | `GET /api/specimens` + `/specimens` (HTML shell + `fetch`) |
| View one record | `GET /api/specimens/:id` + `/specimens/:id` |
| Delete a record | `DELETE /api/specimens/:id` + `/specimens/delete/:id` confirm page |
| Edit (bonus) | `PATCH /api/specimens/:id` + `/specimens/:id/edit` |
| Front-end uses API routes | All collection pages load/save via `fetch` to `/api/specimens` |
| Submission zip | `TeamName_Rails_Phase3.zip` from repo root (replace team name) |

---

## Architecture

**Same stack for API and UI.** We did not add Express or a separate Node service.
Rails serves both:

- **JSON API** — `ActionController::API` under `app/controllers/api/`
- **HTML shells** — `SpecimensController` renders ERB pages with almost no server-side data; JavaScript calls the API

**Data flow (example: list page):**

1. Browser requests `/specimens` → Rails returns static ERB + layout.
2. Inline script runs `fetch("/api/specimens")`.
3. `Api::SpecimensController#index` reads `Specimen` rows from SQLite → JSON array.
4. Script builds gem-style cards in the DOM.

Create/update/delete forms send `POST` / `PATCH` / `DELETE` with a JSON body shaped as `{ "specimen": { ... } }` and the Rails CSRF token in `X-CSRF-Token`.

---

## Database

| Item | Location |
| ---- | -------- |
| Model | `app/models/specimen.rb` |
| Migration | `db/migrate/20260521120000_create_specimens.rb` |
| Schema | `db/schema.rb` |
| Seed data | `db/seeds.rb` (6 gems, idempotent `find_or_create_by!`) |
| File | `storage/development.sqlite3` |

**Columns:** `name` (required), `color`, `mohs`, `origin`, `fact`, `tint` (UI card color), timestamps.

**Inflection fix:** Rails default pluralization treats `specimen` → `specimen` (same word). We added `inflect.irregular "specimen", "specimens"` in `config/initializers/inflections.rb` so ActiveRecord uses the `specimens` table.

**Launcher:** `start-dev.bat` → `scripts/setup-and-run.ps1` runs `db:migrate` then `db:seed` on every start (seed is safe to repeat).

---

## API endpoints

| Method | Path | Controller action |
| ------ | ---- | ----------------- |
| GET | `/api/specimens` | `index` |
| GET | `/api/specimens/:id` | `show` |
| POST | `/api/specimens` | `create` |
| PATCH/PUT | `/api/specimens/:id` | `update` |
| DELETE | `/api/specimens/:id` | `destroy` |

Errors return JSON `{ "error": "..." }` with `404` or `422` as appropriate (`Api::BaseController` rescues `RecordNotFound` and `RecordInvalid`).

---

## HTML routes

| Path | Purpose |
| ---- | ------- |
| `/specimens` | List (API-driven grid) |
| `/specimens/new` | Create form → `POST` API |
| `/specimens/:id` | Detail |
| `/specimens/:id/edit` | Edit form → `PATCH` API |
| `/specimens/delete/:id` | Delete confirmation → `DELETE` API |

Nav link: **Collection** in `app/views/layouts/application.html.erb`.

---

## New / changed files (high level)

```
app/models/specimen.rb
app/controllers/api/base_controller.rb
app/controllers/api/specimens_controller.rb
app/controllers/specimens_controller.rb
app/helpers/specimens_helper.rb
app/views/specimens/          # index, show, new, edit, delete_confirm, partials
config/routes.rb              # api namespace + specimen HTML routes
config/initializers/inflections.rb
db/migrate/..._create_specimens.rb
db/schema.rb
db/seeds.rb
scripts/setup-and-run.ps1   # migrate + seed
docs/PHASE3_NOTES.md
presentations/Phase3_Presentation_Guide.md
```

Phase 1–2 pages (`/`, `/gems`, `/metals`, `/mines`) are unchanged in behavior; only the layout nav gained **Collection**.

---

## Styling

Collection pages reuse Bedrock’s Tailwind look (amber/slate palette, gem SVGs, Mohs bar). Shared pieces:

- `_page_hero`, `_breadcrumb`, `_form`, `_api_client`
- Tint colors centralized in `SpecimensHelper::TINT_STYLES` and exposed to JS as `window.BedrockTints`

---

## Demo checklist (quick)

1. `start-dev.bat` — confirm migrate + seed in log.
2. `/specimens` — six seeded cards, styled grid.
3. Click **View** → detail hero + field note panel.
4. **Edit** → change a field → save → detail reflects change.
5. **Delete** → confirm → back to list with flash notice.
6. **Add specimen** → new record appears in list.
7. Open `/api/specimens` in a new tab — raw JSON for graders.

---

## Known gotchas

- **Table `specimen` error on seed:** fixed by irregular inflection (see above).
- **`db:prepare` + seed ordering:** launcher uses explicit `db:migrate` then `db:seed` instead of `db:prepare` alone.
- **Tailwind after new classes:** if cards look unstyled, run `ruby bin\rails tailwindcss:build` or use `bin/dev` (watcher).
