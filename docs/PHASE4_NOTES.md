# Phase 4 — Containerization + free-tier cloud deploy

Phase 4 takes the Phase 3 app, wraps it in a production-grade container
stack, and ships it to a publicly reachable Oracle Cloud Infrastructure
(OCI) VM via Terraform — all inside Oracle's Always-Free allowance so
nothing bills.

---

## Assignment mapping

| Rubric item                              | How we implemented it |
| ---------------------------------------- | --------------------- |
| Containerize the application             | Multi-stage `Dockerfile` (base/build/development/production) |
| Local dev with Compose                   | `docker-compose.yml` (Rails dev + Postgres) |
| Production-style runtime                 | `docker-compose.prod.yml` (Rails on `:80` + Postgres sidecar, named volume, healthcheck) |
| Infrastructure as Code                   | `infra/terraform/` — OCI provider, VCN, subnet, IGW, security list, ARM A1 VM |
| Public, internet-reachable deploy        | Public IPv4 on the VM, security list opens `:80` |
| Cost                                     | **$0/month**, Always-Free ARM Ampere A1 |

---

## Architecture

```
                          ┌──────────────────────────────────────┐
                          │ Oracle Cloud (Always-Free, ARM A1)   │
                          │                                      │
   Internet ─── :80 ─────►│  ┌─────────────┐   ┌──────────────┐  │
                          │  │  web        │──►│  db          │  │
                          │  │  Rails 8    │   │  postgres:16 │  │
                          │  │  Puma :3000 │   │  internal    │  │
                          │  └─────────────┘   └──────────────┘  │
                          │     stackonomics-web:prod            │
                          │     docker compose (prod overlay)    │
                          └──────────────────────────────────────┘
                                       ▲
                                       │ terraform apply
                                       │ cloud-init bootstrap
                                       │
                                  Local laptop
```

- **`web`** publishes container port 3000 on host port 80. Rails is told
  it's behind a non-TLS edge via `RAILS_SERVE_STATIC_FILES=true` so
  Propshaft assets are served directly without a reverse proxy.
- **`db`** stays on an internal Compose network — no host port published.
  Data lives in the `pgdata` named volume which survives image rebuilds.
- **Secrets** (`SECRET_KEY_BASE`, `POSTGRES_PASSWORD`) are generated *on
  the VM itself* during cloud-init and stored in `/opt/app/.env.production`
  with `0600` perms. They never leave the box and aren't in git.

---

## Key changes vs. Phase 3

1. **`Gemfile`** — added `pg ~> 1.5` in the `:production` group; SQLite
   stays the dev/test database so nobody needs `libpq` locally.
2. **`config/database.yml`** — `production:` now reads `DATABASE_URL` and
   uses the `postgresql` adapter.
3. **`Dockerfile`** — installs `libpq5` (runtime) in `base` and
   `libpq-dev` (headers) in `build`; `BUNDLE_WITHOUT` updated so the
   correct groups are pulled in each stage.
4. **`docker-compose.prod.yml`** — new file; web on `:80`, Postgres
   sidecar with healthcheck, secrets via `.env.production`.
5. **`infra/terraform/`** — new module: VCN/subnet/IGW/security list,
   one ARM A1 Flex VM, cloud-init that installs Docker, clones the repo,
   generates secrets, and brings the stack up.

---

## Why Oracle Cloud (and not AWS/GCP)?

| Provider | Always-Free? | What you get for $0 forever |
|----------|--------------|-----------------------------|
| **OCI**  | Yes (forever) | Up to 4 ARM OCPUs + 24 GB RAM + 200 GB block storage |
| AWS      | 12 months only | 1× `t2.micro` (1 vCPU + 1 GB), then ~$8/mo |
| GCP      | Yes (forever) | 1× `e2-micro` (2 vCPU burst + 1 GB), 30 GB disk |

OCI's ARM allowance is roughly **12× the RAM** of GCP's always-free shape
and never expires — perfect for a class project that needs to stay live
indefinitely. Trade-off: ARM-only, so all our images have to be
multi-arch. Postgres and Ruby slim both ship `linux/arm64` builds, so
the Compose stack works unchanged.

---

## Deployment workflow

```powershell
# One-time
cd infra\terraform
copy terraform.tfvars.example terraform.tfvars
# fill in OCI creds + SSH key

terraform init
terraform apply

# Wait ~5 minutes for cloud-init, then visit the printed app_url.
```

Updating after a code change:

```bash
ssh ubuntu@<public_ip>
cd /opt/app && git pull
docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build
```

See [`infra/terraform/README.md`](../infra/terraform/README.md) for the
full signup walkthrough, troubleshooting, and tear-down steps.

---

## Demo checklist

- [ ] `docker compose up` works locally on a fresh clone
- [ ] `terraform plan` shows ~9 resources, all in the Always-Free tier
- [ ] `terraform apply` finishes; `app_url` output prints a public IP
- [ ] Browsing to `app_url` shows the Phase 3 specimens UI
- [ ] Creating/editing/deleting a specimen survives `docker compose down && up -d`
      (proves the `pgdata` volume is persistent)
- [ ] `terraform destroy` cleanly removes everything
