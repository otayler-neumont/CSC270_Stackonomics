# Stackonomics on GCP — Always-Free e2-micro Terraform Module

This module is the GCP sibling of `../terraform/` (Oracle Cloud). It
provisions a single `e2-micro` VM in an always-free GCP region with
Docker + the Stackonomics compose stack bootstrapped via cloud-init.

> **Always-free guarantee:** `e2-micro` in us-west1, us-central1, or
> us-east1, with a 30 GB standard persistent disk, is part of Google's
> permanent Free Tier — not the 90-day trial. As long as you don't add
> a second instance or upgrade the disk type/size, you'll never see a
> charge.

---

## 1. One-time GCP setup (5 minutes in the Console)

These steps don't need `gcloud` installed — they're all clicks in the
web Console.

### 1a. Use (or create) a project

GCP Console → top bar → **project picker** → either pick an existing
project or click **New Project**. Note the **Project ID** (NOT the
project number; the ID is the slug like `stackonomics-470801`).

### 1b. Enable the Compute Engine API

1. Console → search bar → **Compute Engine API**
2. Click **Enable**. (First enable can take 30–60 seconds.)

### 1c. Create a service account for Terraform

1. Console → **IAM & Admin → Service Accounts → Create service account**
2. Name: `stackonomics-tf` (anything works)
3. **Grant role: `Compute Admin`** (lets it create VMs/networks/firewalls)
4. Skip the "Grant users access" step. Click **Done**.

### 1d. Download a JSON key for that service account

1. From the service-accounts list, click the new SA's email
2. **Keys** tab → **Add key → Create new key → JSON → Create**
3. The browser downloads a `.json` file. Move it somewhere safe and
   readable; e.g.:
   ```powershell
   mkdir $HOME\.gcp -Force
   Move-Item "$HOME\Downloads\stackonomics-*.json" "$HOME\.gcp\stackonomics-tf-key.json"
   ```

### 1e. (Strongly recommended) Set a billing budget alert

Even though the always-free e2-micro can't bill you, accidentally adding
a non-free resource later could. Belt-and-suspenders:

1. Console → **Billing → Budgets & alerts → Create budget**
2. Target your billing account, set amount to **$1**, alert at **50% /
   90% / 100%**. Email goes to the account owner.

---

## 2. Configure

```powershell
cd infra\terraform-gcp
copy terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars
```

Fill in:
- `project_id` — from step 1a
- `credentials_file` — absolute Windows path to the JSON key from 1d
  (use forward slashes: `C:/Users/.../stackonomics-tf-key.json`)
- `ssh_public_key` — contents of `~/.ssh/id_ed25519.pub` (single line)

---

## 3. Deploy

```powershell
terraform init
terraform plan
terraform apply
```

The VM itself comes up in ~30 seconds. Cloud-init then takes **~10–15
minutes** to:
1. Allocate a 2 GB swap file (needed because e2-micro only has 1 GB RAM)
2. Install Docker CE + Compose plugin
3. Clone the repo
4. Build the Rails image (memory-tight, swap-heavy phase)
5. Start the compose stack

Track the bootstrap in real time:

```powershell
ssh ubuntu@<public_ip> 'sudo tail -f /var/log/cloud-init-output.log'
```

When you see `Stackonomics bootstrap finished after ... seconds.`, browse
to the `app_url` Terraform printed.

---

## 4. What this creates

| Resource                    | Always-free?              | Notes |
|-----------------------------|---------------------------|-------|
| 1× Custom VPC               | Yes                       | `stackonomics-vpc` |
| 1× Regional subnet (`/24`)  | Yes                       | `stackonomics-subnet` |
| 2× Firewall rules           | Yes                       | Open `:22` (configurable CIDR) and `:80` (world) |
| 1× e2-micro VM              | Yes (1 instance/month)    | 0.25 vCPU burst→2, 1 GB RAM |
| 1× 30 GB pd-standard disk   | Yes                       | Boot volume, exactly at free-tier cap |
| 1× Ephemeral public IPv4    | Yes                       | Static IPs cost; ephemeral does not |

Total monthly cost: **$0.**

---

## 5. Updating the running app

```bash
ssh ubuntu@<public_ip>
cd /opt/app
git pull
docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build
```

The `pgdata` Docker volume persists across rebuilds.

---

## 6. Tear down

```powershell
terraform destroy
```

---

## 7. Troubleshooting

**`terraform apply` says "Compute Engine API has not been used".** Step
1b — enable the API in the Console.

**`Required 'compute.instances.create' permission missing`.** The
service account from 1c needs `Compute Admin`, not just `Compute Viewer`.
Re-grant the role and retry.

**Build OOM-kills despite the swap file.** Increase the swap from 2 GB
to 4 GB in `cloud-init.yaml` (`fallocate -l 4G`) and re-apply (this
will destroy and recreate the VM). Or pre-build the image elsewhere and
push to a registry.

**Cold-start latency / 502 for the first ~30 seconds.** Rails takes a
few seconds to boot under puma. Hit the URL twice; the second one is
fast.
