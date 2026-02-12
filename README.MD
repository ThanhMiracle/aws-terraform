# LAB-1
## ✅ Results
### Install awscli on ec2
![Lab1-image-0](aws_images/use_awscli_in_ec2.jpeg)
---------------------------------------

### Policy Added
![Lab1-image-0](aws_images/s3_policy.jpeg)
----------------------------------------
### Confirm policy to view Buckets from EC2
![Lab1-image-0](aws_images/bucket_iam_policy.jpeg)

# LAB-2
## ✅ Results
### Confirm Nginx is installed
![Lab1-image-0](aws_images/nginx_installed.jpeg)
-----------------
### Access through browser
![Lab1-image-0](aws_images/nginx_installed_1.jpeg)

### EBS mount in EC2
![Lab1-image-0](aws_images/ebs_mount.jpeg)

### Create 2  private subnet , 2 public subnet , 1 natgateway , 1 internet gateway

![Lab1-image-0](aws_images/tf_output_public_private_ip.jpeg)

- Setup inbound and outbound rules for each EC2
![Lab1-image-0](aws_images/inboud_outbound_rules.jpeg)

- SSH into public EC2
![Lab1-image-0](aws_images/ssh_to_public_ip.jpeg)
- SSH from public one to private one
![Lab1-image-0](aws_images/from_public_to_private.jpeg)


# LAB-3
### EBS mount in EC2
![Lab1-image-0](aws_images/ebs_mount.jpeg)

# LAB-4

### Create ALB and ASG , bucket attached to ASG
![Lab1-image-0](aws_images/ALB_ASG.jpeg)

### Access from browser through ALB's DNS
![Lab1-image-0](aws_images/access_through_lb-dns.jpeg)


Here’s a fixed `ec2_user_data` that will **install Docker via user-data reliably** in your environment.

Key changes vs your current script:

* **Do NOT force Ubuntu repos to HTTPS** (your logs show `:443` to Ubuntu mirrors times out; earlier `http://security.ubuntu.com` worked).
* **Wait for network** before apt.
* **Retry apt-get update** until the repo is actually usable (checks `awscli` visibility).
* **Skip `apt-get upgrade`** in user-data (it’s a common source of boot-time failures/locks). If you really want it, make it non-fatal.

Copy/paste this whole block:

```hcl
ec2_user_data = <<-EOF
#!/bin/bash
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

# Force apt to use IPv4 (avoid IPv6 route issues)
cat >/etc/apt/apt.conf.d/99force-ipv4 <<'APT'
Acquire::ForceIPv4 "true";
APT

# IMPORTANT: Do NOT force Ubuntu mirrors to HTTPS.
# Your logs show timeouts to Ubuntu mirrors on :443. Keep default (often http) for Ubuntu repos.
# (Packages are still verified by apt signatures.)

# Wait until network is really ready (DNS + outbound)
for i in {1..60}; do
  curl -4fsS --connect-timeout 2 --max-time 5 http://security.ubuntu.com/ubuntu/ >/dev/null && break || true
  sleep 2
done

apt-get clean
rm -rf /var/lib/apt/lists/*

# Retry apt update until repositories are usable (awscli becomes visible)
ok=0
for i in {1..20}; do
  apt-get update -y || true
  if apt-cache show awscli >/dev/null 2>&1; then
    ok=1
    break
  fi
  sleep 10
done

if [ "$ok" -ne 1 ]; then
  echo "ERROR: apt repositories not reachable or incomplete after retries"
  exit 1
fi

# Avoid upgrade in userdata (frequent failure/lock during boot)
# If you really want it, do: apt-get -y upgrade || true

# Base packages
apt-get install -y ca-certificates curl gnupg lsb-release awscli

# Docker repo + key (keep Docker repo on HTTPS)
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

# Update again for docker repo (retry a bit)
for i in {1..10}; do
  apt-get update -y && break
  sleep 5
done

# Install Docker Engine + Compose plugin
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker
usermod -aG docker ubuntu

docker --version | tee /var/log/docker-version.txt
docker compose version | tee /var/log/docker-compose-version.txt
aws --version | tee /var/log/awscli-version.txt
EOF
```

### Terraform-only note (so it actually reruns)

User-data runs once per instance. After updating this, you must recreate the instance via Terraform, e.g.:

```bash
terraform apply -var="lab_file=lab01" -auto-approve -replace="module.ec2_private.aws_instance.this"
```

(Use the real address from `terraform state list | grep ec2_private` if it differs.)

After recreate, Docker should be installed automatically, and `/var/log/user-data.log` will show the full run.



# DIFFERENCE 
Good question — this is an important Terraform behavior difference.

You’re comparing:

```bash
terraform apply -var="lab_file=lab01" -auto-approve
```

vs

```bash
terraform apply -var="lab_file=lab01" -auto-approve -replace="module.ec2_private.aws_instance.this"
```

---

# 1️⃣ Normal `terraform apply`

```bash
terraform apply -var="lab_file=lab01" -auto-approve
```

Terraform will:

* Compare **current state** vs **current config**
* Only change resources if it detects a diff
* If nothing changed → it does nothing
* If only in-place updates are possible → it updates without recreating

For EC2:

* If `user_data` did not change (or Terraform doesn't detect it as requiring replacement),
  ➜ The instance is NOT recreated
  ➜ Cloud-init does NOT rerun
  ➜ Your Docker script does NOT run again

So normal `apply` is **safe and incremental**.

---

# 2️⃣ `terraform apply -replace=...`

```bash
terraform apply -var="lab_file=lab01" -auto-approve \
  -replace="module.ec2_private.aws_instance.this"
```

This tells Terraform:

> "I don't care if there is no diff. Destroy and recreate this resource."

Terraform will:

1. Destroy the EC2 instance
2. Create a brand new one
3. Run user-data again
4. Docker installs from scratch

This forces a **new instance lifecycle**.

---

# Why this matters for user-data

Cloud-init runs user-data:

* ✅ Once per instance
* ❌ Not on configuration update
* ❌ Not on reboot

So:

| Command          | Instance Recreated?   | user-data Runs? |
| ---------------- | --------------------- | --------------- |
| `apply`          | Only if diff requires | Maybe           |
| `apply -replace` | Always                | Yes             |

---

# When you should use `-replace`

Use it when:

* You changed user-data
* You changed AMI
* You want a clean rebuild
* You are debugging provisioning
* You want immutable infrastructure behavior

---

# Production Best Practice

Instead of manually using `-replace`, inside your EC2 resource add:

```hcl
user_data_replace_on_change = true
```

Then:

* If user-data changes → Terraform automatically recreates the instance
* No need for manual `-replace`

That’s the clean DevOps approach.

---

# Short Answer

Normal apply = “only change what’s different.”
Apply with `-replace` = “force destroy + recreate this resource.”

For your Docker + user-data case, `-replace` guarantees user-data runs again.

---

If you want, I can also explain when `taint` is better than `-replace` and how they differ internally.
