#!/bin/bash
set -euo pipefail

echo "[user-data] start"

# Force IPv4 for apt (avoids IPv6 "network unreachable" during boot)
echo 'Acquire::ForceIPv4 "true";' | tee /etc/apt/apt.conf.d/99force-ipv4 >/dev/null

echo "[user-data] Installing AWS CLI v2 (if missing)..."
if ! command -v aws >/dev/null 2>&1; then
  for i in {1..10}; do
    apt-get update -y && break
    echo "[user-data] apt-get update failed, retry $i/10..."
    sleep 5
  done

  apt-get install -y unzip curl

  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install --update
  rm -rf /tmp/aws /tmp/awscliv2.zip
fi

aws --version || true

APP_DIR="${app_dir}"
install -d -m 0755 "$APP_DIR"

echo "[user-data] Writing install_docker.sh..."
cat > "$APP_DIR/install_docker.sh" <<'EOF'
${install_docker}
EOF
chmod +x "$APP_DIR/install_docker.sh"

echo "[user-data] Running install_docker.sh..."
set +e
bash -x "$APP_DIR/install_docker.sh"
dock_rc=$?
set -e
if [ "$dock_rc" -ne 0 ]; then
  echo "[user-data] WARN: install_docker.sh failed with exit code $dock_rc (continuing)"
fi

echo "[user-data] done"