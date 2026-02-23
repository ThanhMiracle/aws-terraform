#!/bin/bash
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

cat >/etc/apt/apt.conf.d/99force-ipv4 <<'APT'
Acquire::ForceIPv4 "true";
APT

for i in {1..60}; do
  curl -4fsS --connect-timeout 2 --max-time 5 http://security.ubuntu.com/ubuntu/ >/dev/null && break || true
  sleep 2
done

apt-get clean
rm -rf /var/lib/apt/lists/*

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

apt-get install -y ca-certificates curl gnupg lsb-release awscli

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

for i in {1..10}; do
  apt-get update -y && break
  sleep 5
done

apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker

getent group docker >/dev/null || groupadd docker
usermod -aG docker ubuntu

for i in {1..30}; do
  [ -S /var/run/docker.sock ] && break
  sleep 1
done
chgrp docker /var/run/docker.sock || true
chmod 660 /var/run/docker.sock || true

mkdir -p /etc/systemd/system/docker.service.d
cat >/etc/systemd/system/docker.service.d/override.conf <<'OVERRIDE'
[Service]
ExecStartPost=/bin/sh -c 'chgrp docker /var/run/docker.sock && chmod 660 /var/run/docker.sock || true'
OVERRIDE

systemctl daemon-reload
systemctl restart docker

docker --version | tee /var/log/docker-version.txt
docker compose version | tee /var/log/docker-compose-version.txt
aws --version | tee /var/log/awscli-version.txt

echo "DONE: user-data finished successfully"