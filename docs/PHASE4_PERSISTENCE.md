# Phase 4 — Adding Persistence

> **Assignment:** Stand up a database, build a Data Access Layer (DAL),
> and update API routes that need persistence to go through the DAL.
> ([Phase_4.png](../Assignment_Refs/Phase_4.png))

## TL;DR

- **Database**: Postgres 16 in production (Docker), SQLite for local dev/test.
- **DAL**: `app/repositories/specimen_repository.rb` (module `SpecimenRepository`).
  Idiomatic Rails-style repository — controllers never touch ActiveRecord
  directly, they only ever call `SpecimenRepository.<method>`.
- **All five REST routes** for specimens (GET list, GET one, POST, PATCH/PUT, DELETE)
  read and write through the DAL.
- **Migrations + seeds** run automatically on every container start via
  `bin/docker-entrypoint` → `bin/rails db:prepare`, so persistence is wired
  end-to-end without any manual steps.
- **Smoke-test**: `scripts/dal-smoke.ps1` round-trips a specimen through
  every CRUD endpoint and asserts the row count grows then shrinks.

## Architecture

```
                  HTTP request
                       v
+------------------------------------------------+
|  Api::SpecimensController                      |   <- HTTP concerns only:
|  (app/controllers/api/specimens_controller.rb) |      params, status codes, JSON
+------------------------------------------------+
                       v
+------------------------------------------------+
|  SpecimenRepository  (the DAL)                 |   <- the only place in the app
|  (app/repositories/specimen_repository.rb)     |      that calls Specimen.<method>
+------------------------------------------------+
                       v
+------------------------------------------------+
|  Specimen < ApplicationRecord                  |   <- model: validations,
|  (app/models/specimen.rb)                      |      constants, as_json
+------------------------------------------------+
                       v
+------------------------------------------------+
|  ActiveRecord  ->  Postgres 16  (prod)         |
|                    SQLite 3     (dev/test)     |
+------------------------------------------------+
```

The hard rule across the codebase: **only `SpecimenRepository` calls
`Specimen.<anything>`**. Anything that needs to read or write a specimen
goes through the repository.

A quick grep confirms it:

```
$ rg 'Specimen\.' app/
app/repositories/specimen_repository.rb
  Specimen.order(:name)
  Specimen.find(id)
  Specimen.create!(attrs)
  Specimen.count
```

Controllers, views, and the rest of the model layer never reach past the DAL.

## Route → DAL → SQL mapping

| HTTP                       | Controller action             | DAL method                          | What ActiveRecord runs                          |
| -------------------------- | ----------------------------- | ----------------------------------- | ----------------------------------------------- |
| `GET /api/specimens`       | `Api::SpecimensController#index`   | `SpecimenRepository.all`            | `SELECT * FROM specimens ORDER BY name`         |
| `GET /api/specimens/:id`   | `Api::SpecimensController#show`    | `SpecimenRepository.find(id)`       | `SELECT * FROM specimens WHERE id = ? LIMIT 1`  |
| `POST /api/specimens`      | `Api::SpecimensController#create`  | `SpecimenRepository.create(attrs)`  | `INSERT INTO specimens (...) VALUES (...)`      |
| `PATCH /api/specimens/:id` | `Api::SpecimensController#update`  | `SpecimenRepository.update(id, attrs)` | `UPDATE specimens SET ... WHERE id = ?`      |
| `DELETE /api/specimens/:id`| `Api::SpecimensController#destroy` | `SpecimenRepository.destroy(id)`    | `DELETE FROM specimens WHERE id = ?`            |

## Files touched in Phase 4

| File                                                | Change      | Purpose                                      |
| --------------------------------------------------- | ----------- | -------------------------------------------- |
| `app/repositories/specimen_repository.rb`           | **new**     | The DAL itself                               |
| `app/controllers/api/specimens_controller.rb`       | refactored  | Goes through the DAL; no `Specimen.X` calls  |
| `scripts/dal-smoke.ps1`                             | **new**     | End-to-end CRUD smoke test                   |
| `docs/PHASE4_PERSISTENCE.md`                        | **new**     | This document                                |

Things that were *already* in place from Phase 3 that satisfy parts of
the Phase 4 rubric:

- `app/models/specimen.rb` — model + validations
- `db/migrate/20260521120000_create_specimens.rb` — schema migration
- `db/schema.rb` — committed schema snapshot
- `db/seeds.rb` — six starter specimens (Diamond, Ruby, Sapphire, Emerald, Opal, Amethyst)
- `bin/docker-entrypoint` — runs `rails db:prepare` on container boot
- `docker-compose.prod.yml` + `infra/terraform-gcp/` — Postgres alongside the web service

## Database setup

### Local development

```powershell
bin/rails db:prepare      # creates SQLite DB, runs migrations, seeds it
bin/rails server          # http://localhost:3000
```

### Production (GCP VM)

Nothing manual. On every container boot, `bin/docker-entrypoint` runs
`bin/rails db:prepare`, which:

1. Connects to the `db` service (Postgres 16) using the `DATABASE_URL`
   that docker-compose injects from `.env.production`.
2. Creates the `stackonomics_production` database if it doesn't exist.
3. Runs any pending migrations.
4. Runs `db/seeds.rb` if the DB was just created.

Data lives in the named Docker volume `app_pgdata`, which is independent
of the container lifecycle — so rebuilding and restarting the web
container **does not erase the database**.

## Verifying persistence

### Local

```powershell
# Terminal A
bin/rails server

# Terminal B
.\scripts\dal-smoke.ps1
```

### Production (live GCP VM)

```powershell
.\scripts\dal-smoke.ps1 -BaseUrl http://35.223.220.115
```

Expected output (final lines):

```
[6/6] DELETE /api/specimens/<id>  (SpecimenRepository.destroy)
  [ ok ] status = 204

[bonus] GET /api/specimens/<id>  (should be 404)
  [ ok ] deleted row returns 404

=== DAL smoke test PASSED ===
```

### Proof the data persists across container restarts

```powershell
# 1. Create a specimen
curl.exe -sS -X POST http://35.223.220.115/api/specimens `
  -H "Content-Type: application/json" `
  -d '{"specimen":{"name":"Persistence Demo","tint":"emerald"}}'

# 2. Restart the web container (DB container stays up)
ssh ubuntu@35.223.220.115 'cd /opt/app && sudo docker compose -f docker-compose.prod.yml --env-file .env.production -p app restart web'

# 3. Wait a few seconds, then fetch the list
curl.exe -sS http://35.223.220.115/api/specimens
# -> the "Persistence Demo" row is still there
```

The same survives a *full* rebuild (`up -d --build`) because the
`pgdata` Docker volume isn't touched by `docker compose up --build`.

## Why a thin repository instead of a "real" DAL class with mapping?

The Phase 4 rubric uses a Java-flavored DAL example (`dal.getAllBulldogs()`,
`dal.updateBulldog(int id, data)`). The idiomatic Rails way to express
the same idea is a repository module that wraps ActiveRecord:

- **One responsibility:** the repository owns *all* DB calls for the
  resource. Nothing else in the app says `Specimen.<method>`.
- **Cheap to evolve:** the repository hides the implementation. We could
  add caching, switch to a different ORM, or split reads and writes
  without touching the controllers.
- **Idiomatic:** Ruby modules with `module_function` are the standard
  Rails pattern for stateless service objects. No DI framework or factory
  needed.

In short, the repository is the DAL — same contract the rubric asks for,
expressed the way a Rails reviewer would expect to read it.

## What Phase 5 will need

Phase 5 (membership and user interactions) adds `User`, `Session`, and
probably a join table (likes / comments / messages). The plan is to
follow this same pattern:

- `app/models/user.rb`           (model)
- `app/repositories/user_repository.rb`   (DAL)
- `app/repositories/session_repository.rb` (DAL)
- etc.

The hard rule stays the same: controllers never call `Model.<method>`
directly — they go through the matching repository.
