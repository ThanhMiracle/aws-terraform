#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${app_dir}"
ENV_FILE="$APP_DIR/.env"
DB_INSTANCE_IDENTIFIER="${db_instance_identifier}"
DB_NAME_FALLBACK="${db_name}"

########################################
# Detect AWS region via IMDSv2
########################################
TOKEN="$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")"

REGION="$(curl -s \
  -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/dynamic/instance-identity/document \
  | jq -r .region)"

if [ -z "$REGION" ] || [ "$REGION" = "null" ]; then
  echo "ERROR: Could not determine AWS region from instance metadata."
  exit 1
fi

########################################
# Ensure awscli + jq installed
########################################
if ! command -v aws >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y awscli jq
fi

########################################
# Wait until RDS is available
########################################
echo "Waiting for RDS instance to become available..."

for i in $(seq 1 60); do
  RDS_JSON="$(aws rds describe-db-instances \
    --region "$REGION" \
    --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
    --query 'DBInstances[0]' \
    --output json 2>/dev/null || true)"

  if [ -n "$RDS_JSON" ] && [ "$RDS_JSON" != "null" ]; then
    STATUS="$(echo "$RDS_JSON" | jq -r '.DBInstanceStatus // empty')"

    if [ "$STATUS" = "available" ]; then
      echo "RDS is available."
      break
    else
      echo "Current RDS status: $STATUS"
    fi
  fi

  if [ "$i" -eq 60 ]; then
    echo "ERROR: RDS did not become available in time."
    exit 1
  fi

  sleep 10
done

########################################
# Extract endpoint + secret ARN
########################################
DB_HOST="$(echo "$RDS_JSON" | jq -r '.Endpoint.Address // empty')"
DB_PORT="$(echo "$RDS_JSON" | jq -r '.Endpoint.Port // empty')"
SECRET_ARN="$(echo "$RDS_JSON" | jq -r '.MasterUserSecret.SecretArn // empty')"

if [ -z "$SECRET_ARN" ]; then
  echo "ERROR: MasterUserSecret not found. Is manage_master_user_password=true?"
  exit 1
fi

########################################
# Fetch secret
########################################
echo "Fetching DB secret from Secrets Manager..."

SECRET_JSON="$(aws secretsmanager get-secret-value \
  --region "$REGION" \
  --secret-id "$SECRET_ARN" \
  --query SecretString \
  --output text)"

DB_USER="$(echo "$SECRET_JSON" | jq -r '.username')"
DB_PASS="$(echo "$SECRET_JSON" | jq -r '.password')"
SECRET_DB_NAME="$(echo "$SECRET_JSON" | jq -r '.dbname // empty')"

# Use dbname from secret if exists, otherwise fallback
if [ -n "$SECRET_DB_NAME" ] && [ "$SECRET_DB_NAME" != "null" ]; then
  DB_NAME="$SECRET_DB_NAME"
else
  DB_NAME="$DB_NAME_FALLBACK"
fi

if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ]; then
  echo "ERROR: Missing required DB connection fields."
  exit 1
fi

########################################
# Create .env safely
########################################
install -d -m 0755 "$APP_DIR"

TMP_ENV="$(mktemp)"

umask 177

cat > "$TMP_ENV" <<EOF
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASS
DATABASE_URL=postgresql://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME?sslmode=require
EOF

mv "$TMP_ENV" "$ENV_FILE"
chmod 600 "$ENV_FILE"

echo ".env file created at $ENV_FILE"