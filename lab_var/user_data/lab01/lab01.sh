#!/bin/bash
set -euo pipefail

APP_DIR="${app_dir}"

install -d -m 0755 "$APP_DIR"

cat > "$APP_DIR/install_docker.sh" <<'EOF'
${install_docker}
EOF
chmod +x "$APP_DIR/install_docker.sh"
bash "$APP_DIR/install_docker.sh"

cat > "$APP_DIR/create_env.sh" <<'EOF'
${create_env}
EOF
chmod +x "$APP_DIR/create_env.sh"

# chạy script tạo .env
bash "$APP_DIR/create_env.sh"