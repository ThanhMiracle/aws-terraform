locals {
  lab01 = {
    environment = "lab01"

    vpc = {
      cidr = "10.0.0.0/16"
      subnet_count = 2

      public_subnets = [
        "10.0.1.0/24",
        "10.0.2.0/24",
        "10.0.3.0/24",
      ]

      private_subnets = [
        "10.0.10.0/24",
        "10.0.20.0/24",
        "10.0.30.0/24",
      ]
    }

    ec2 = {
      instance_type  = "t3.micro"
      ami_id         = null
      attach_deny_s3 = true
      # ssh_cidr_blocks = ["x.x.x.x/32"]  # optional (root can override)
    }

ec2_user_data = <<-EOF
#!/bin/bash
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

# --- APT reliability fixes (your env had IPv6 issues + Ubuntu HTTPS timeouts) ---

# Force apt to use IPv4
cat >/etc/apt/apt.conf.d/99force-ipv4 <<'APT'
Acquire::ForceIPv4 "true";
APT

# Wait until outbound network is actually usable (HTTP works in your env)
for i in {1..60}; do
  curl -4fsS --connect-timeout 2 --max-time 5 http://security.ubuntu.com/ubuntu/ >/dev/null && break || true
  sleep 2
done

apt-get clean
rm -rf /var/lib/apt/lists/*

# Retry apt update until repos are usable (awscli becomes visible)
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

# Avoid upgrade in userdata (often causes locks/timeouts during early boot)
# If you really want it, uncomment the next line:
# apt-get -y upgrade || true

# Base packages
apt-get install -y ca-certificates curl gnupg lsb-release awscli

# --- Docker install (official Docker repo over HTTPS) ---

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

apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable/start docker
systemctl enable --now docker

# --- No-sudo docker for ubuntu user (session gets it on FIRST login after boot) ---

# Ensure docker group exists and add ubuntu
getent group docker >/dev/null || groupadd docker
usermod -aG docker ubuntu

# Wait for docker socket then enforce group ownership/perms (helps if defaults differ)
for i in {1..30}; do
  [ -S /var/run/docker.sock ] && break
  sleep 1
done
chgrp docker /var/run/docker.sock || true
chmod 660 /var/run/docker.sock || true

# Persist docker.sock perms across restarts via systemd drop-in
mkdir -p /etc/systemd/system/docker.service.d
cat >/etc/systemd/system/docker.service.d/override.conf <<'OVERRIDE'
[Service]
ExecStartPost=/bin/sh -c 'chgrp docker /var/run/docker.sock && chmod 660 /var/run/docker.sock || true'
OVERRIDE

systemctl daemon-reload
systemctl restart docker

# Verify installations (logs)
docker --version | tee /var/log/docker-version.txt
docker compose version | tee /var/log/docker-compose-version.txt
aws --version | tee /var/log/awscli-version.txt

echo "DONE: user-data finished successfully"
EOF

  }
}
