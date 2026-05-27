# Stackonomics on Oracle Cloud — Always-Free Terraform Module

This Terraform module spins up a single Ubuntu 22.04 ARM VM in Oracle Cloud
Infrastructure (OCI), bootstraps it with Docker + Compose, clones this
repository, and starts the production stack (Rails on `:80` + Postgres
sidecar) — all inside the **Always-Free** tier so it costs **$0/month**.

> **What "Always-Free" means here:** unlike AWS's 12-month free tier, OCI's
> ARM Ampere A1 allowance (up to 4 OCPUs / 24 GB RAM / 200 GB block storage)
> and the public IP / VCN / internet gateway are free *forever*, as long as
> you stay inside those limits. No payment will be charged if you only use
> the resources defined here.

---

## 1. Prerequisites (one-time)

### 1a. Tools

| Tool      | Why                                  | Install                                                   |
|-----------|--------------------------------------|-----------------------------------------------------------|
| Terraform | Drives the deploy                    | `winget install HashiCorp.Terraform` (or `choco install terraform`) |
| OpenSSL   | Generates the OCI API key & secrets  | Ships with Git for Windows                                |
| SSH       | Connect to the VM after it's up      | Ships with Windows 10+                                    |

### 1b. Oracle Cloud account

1. Sign up at <https://signup.oraclecloud.com/>.
2. You'll need a credit card for ID verification, but **Always-Free
   resources don't bill it**. Choose a home region near you (e.g.
   `us-ashburn-1`, `us-phoenix-1`, `sa-saopaulo-1`) — you **cannot
   change it later**.
3. After signup, finish the email verification and log in to the
   [OCI Console](https://cloud.oracle.com).

### 1c. Generate an API signing key

From PowerShell:

```powershell
mkdir $HOME\.oci -Force
openssl genrsa -out $HOME\.oci\oci_api_key.pem 2048
openssl rsa -pubout -in $HOME\.oci\oci_api_key.pem -out $HOME\.oci\oci_api_key_public.pem
icacls $HOME\.oci\oci_api_key.pem /inheritance:r /grant:r "$($env:USERNAME):(R)"
```

Then in the OCI Console:

1. **Profile menu (top-right) → My profile → API keys → Add API key**.
2. Choose **Paste public key** and paste the contents of
   `oci_api_key_public.pem`.
3. Click **Add**. OCI will show a config block — copy the **fingerprint**,
   **user OCID**, **tenancy OCID**, and **region** from it; you'll paste
   them into `terraform.tfvars` in step 3.

### 1d. SSH key

If you don't already have one:

```powershell
ssh-keygen -t ed25519 -f $HOME\.ssh\id_ed25519 -C "stackonomics-oci"
```

The contents of `~/.ssh/id_ed25519.pub` go into `ssh_public_key` in step 3.

---

## 2. What this module creates

| Resource                      | Always-Free?                  | Notes                                |
|-------------------------------|-------------------------------|--------------------------------------|
| 1× VCN (`10.20.0.0/16`)       | Yes                           | Regional VCN                         |
| 1× Internet Gateway           | Yes                           | Default route to `0.0.0.0/0`          |
| 1× Public subnet (`/24`)      | Yes                           |                                       |
| 1× Security list              | Yes                           | Allows SSH (configurable CIDR) + HTTP |
| 1× ARM Ampere A1 Flex VM      | Yes (2 OCPU / 12 GB default)  | Default fits well under the 4/24 cap  |
| 1× 50 GB boot volume          | Yes                           | Under the 200 GB block-storage cap    |
| 1× Public ephemeral IP        | Yes                           |                                       |

Total monthly cost: **$0**.

---

## 3. Configure

```powershell
cd infra\terraform
copy terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars
```

Fill in:
- `tenancy_ocid`, `user_ocid`, `fingerprint`, `region` (from step 1c)
- `compartment_ocid` (use the tenancy OCID for the root compartment)
- `private_key_path` (e.g. `~/.oci/oci_api_key.pem`)
- `ssh_public_key` (contents of `~/.ssh/id_ed25519.pub`, single line)

Optional: tighten `allowed_ssh_cidr` to your own IP/32.

---

## 4. Deploy

```powershell
terraform init
terraform plan
terraform apply
```

`apply` takes roughly 2 minutes for OCI to create the VM. The cloud-init
script then needs another ~3-5 minutes to install Docker, build the
image, and start the stack. Track its progress with:

```powershell
ssh ubuntu@<public_ip> 'sudo tail -f /var/log/cloud-init-output.log'
```

When you see `Stackonomics bootstrap finished after ... seconds.`, browse to
the `app_url` printed by Terraform.

---

## 5. Updating the running app

SSH in and pull + rebuild:

```bash
ssh ubuntu@<public_ip>
cd /opt/app
git pull
docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build
```

The `pgdata` Docker volume keeps the database between rebuilds.

---

## 6. Tear down

```powershell
terraform destroy
```

This removes the VM, VCN, subnet, gateway, and security list. The OCI
Always-Free quota refills immediately — you can re-apply any time.

---

## 7. Troubleshooting

**`Out of host capacity` on apply.** OCI's free ARM capacity is regional
and sometimes oversubscribed. Either pick a different home region (you
can't change yours once set, but the first signup is the locked one) or
retry every few minutes — `terraform apply` is idempotent.

**Site doesn't load after 5 minutes.** SSH in and run
`sudo tail -200 /var/log/cloud-init-output.log` — almost always either a
git auth issue (private repo) or a Docker pull rate-limit hiccup. Re-run
`bash /opt/bootstrap.sh` to retry.

**`docker compose` complains about a missing variable.** Check
`/opt/app/.env.production` exists and is non-empty. Cloud-init writes it
exactly once; if it failed mid-run, regenerate with `openssl rand -hex 64`
/ `openssl rand -hex 16` by hand.

**SSH refuses your key.** Make sure you pasted the **public** key
(`.pub`), single line, with no trailing newline mangling.
