# Production System Architecture

> Where everything runs in production, and specifically **where Postgres lives**.
> Sourced from `docker-compose.prod.yml` and `infra/terraform-gcp/`.

## Block diagram

```
                          Internet  (browser / curl / dal-smoke.ps1)
                                         |
                                         |  HTTP :80          SSH :22
                                         v                      (from allowed CIDR only)
        ============================ GCP firewall ==============================
          allow tcp/80 from 0.0.0.0/0           allow tcp/22 from allowed_ssh_cidr
        ========================================================================
                                         |
                                         v
   +======================================================================================+
   |  GCP Compute Engine VM   (Ubuntu 22.04 minimal,  ephemeral public IP 35.223.220.115)  |
   |  VPC: stackonomics-vpc      Subnet: 10.30.1.0/24                                       |
   |                                                                                        |
   |   Docker Compose project "app"  (-f docker-compose.prod.yml --env-file .env.production)|
   |                                                                                        |
   |     +--------------------------------+         +-------------------------------------+ |
   |     |  web  container                |         |  db  container                      | |
   |     |  image: stackonomics-web:prod  |         |  image: postgres:16-alpine          | |
   |     |  Rails 8 + Puma                |         |                                     | |
   |     |  RAILS_ENV=production          |  SQL    |  POSTGRES_DB=                       | |
   |     |                                |  5432   |    stackonomics_production          | |
   |     |  DATABASE_URL ---------------- | ------> |  user: stackonomics                 | |
   |     |   postgres://...@db:5432/...   |         |  listens on :5432 (internal only)   | |
   |     |  ports: 80 -> 3000             |         |  healthcheck: pg_isready            | |
   |     +---------------+----------------+         +------------------+------------------+ |
   |          published :80     |                                      |                    |
   |                            |   internal  (bridge network)         |                    |
   |                            +======================================+                    |
   |                              ^ Postgres is ONLY on this network;                       |
   |                                no host/Internet port for 5432                          |
   |                                                       |                                |
   |                                                       v                                |
   |                                          +-------------------------+                   |
   |                                          |  Docker volume: pgdata  |  <- data persists |
   |                                          |  /var/lib/postgresql/   |     across        |
   |                                          |       data              |     restarts &    |
   |                                          +-------------------------+     rebuilds      |
   +======================================================================================+

   Bootstrap: Terraform creates the VM/VPC/firewall -> cloud-init clones the repo &
   runs `docker compose up` -> web's entrypoint runs `rails db:prepare` (migrate + seed).
```

## Key points

- **Only port 80 is public.** Traffic hits the `web` (Rails/Puma) container, which is
  published as `80:3000` on the VM.
- **Postgres is private.** The `db` container (`postgres:16-alpine`) is attached only to
  the `internal` bridge network. There is **no host port mapping for 5432**, so nothing
  outside the VM can reach the database directly. `web` reaches it by the service hostname
  `db` via `DATABASE_URL=postgres://stackonomics:...@db:5432/stackonomics_production`.
- **Data survives restarts.** Postgres writes to the named Docker volume `pgdata` mounted
  at `/var/lib/postgresql/data`, which is independent of the container lifecycle —
  `docker compose up --build` doesn't wipe it.
- **Startup ordering.** `web` has `depends_on: db (condition: service_healthy)`, and the
  db container has a `pg_isready` healthcheck, so Rails won't try to migrate until Postgres
  is accepting connections.
- **Dev vs prod difference.** Locally the app runs on SQLite (`storage/development.sqlite3`);
  production swaps in Postgres purely via `DATABASE_URL` — same Rails code, same DAL,
  different adapter.

## Component reference

| Component        | What it is                          | Defined in                                  |
| ---------------- | ----------------------------------- | ------------------------------------------- |
| GCP VM           | Compute Engine, Ubuntu 22.04 min.   | `infra/terraform-gcp/compute.tf`            |
| VPC + subnet     | `stackonomics-vpc`, `10.30.1.0/24`  | `infra/terraform-gcp/network.tf`            |
| Firewall (80/22) | tag-scoped ingress rules            | `infra/terraform-gcp/network.tf`            |
| `web` container  | Rails 8 + Puma, port `80:3000`      | `docker-compose.prod.yml`                   |
| `db` container   | `postgres:16-alpine`, internal only | `docker-compose.prod.yml`                   |
| `pgdata` volume  | Postgres data dir, persistent       | `docker-compose.prod.yml`                   |
| Bootstrap        | clone repo + `docker compose up`    | `infra/terraform-gcp/` cloud-init           |

See also [`PHASE4_PERSISTENCE.md`](PHASE4_PERSISTENCE.md) for the DAL/persistence details.
