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


  }
}
