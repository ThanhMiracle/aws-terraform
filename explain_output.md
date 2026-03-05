Here’s what each output is, and what you typically use it for in this stack (VPC + RDS + Secrets + Lambda + API Gateway + S3).

---

## API Gateway (your public HTTP entrypoint)

### `api_id`

* **What it is:** The ID of the HTTP API in API Gateway (`cstnqxt1o0`).
* **Used for:** Debugging, IAM permissions, CLI queries, attaching custom domains, authorizers, WAF, etc.

### `api_endpoint`

### `api_invoke_url`

* **What it is:** The base URL clients call.
* **Used for:** Testing your API right now:

  * `GET https://.../health`
  * `ANY https://.../{proxy+}` (proxy route)
* Since stage is `$default`, `api_endpoint` and `api_invoke_url` are the same.

### `api_stage_name = "$default"`

* **What it is:** The stage name for the API.
* **Used for:** Deployment behavior + URL formatting.

  * With `$default`, you don’t need `/stage` in the URL.

### `api_routes`

* **What it is:** The routes you created in API Gateway.
* **Used for:** Knowing what endpoints are live:

  * `GET /health` → usually a simple health check
  * `ANY /{proxy+}` → catch-all proxy to your Lambda for all methods/paths

---

## Lambda (your compute)

### `lambda_function_name`

* **What it is:** Lambda name (`lab02-api`).
* **Used for:** Updating code manually later:

  ```bash
  aws lambda update-function-code --function-name lab02-api --zip-file fileb://your.zip
  ```

### `lambda_function_arn`

* **What it is:** The unique ARN of the function.
* **Used for:** Permissions, integrations, alarms, event sources.

### `lambda_invoke_arn`

* **What it is:** A special “invoke path” ARN used by API Gateway integrations.
* **Used for:** API Gateway → Lambda integration (you already wired this).

### `lambda_role_arn`

* **What it is:** IAM role Lambda assumes at runtime.
* **Used for:** Controlling what your Lambda can access (Secrets Manager, S3, CloudWatch logs, etc.).
* If Lambda fails to read secrets / access S3, this role is where you fix permissions.

---

## Networking (VPC + subnets + security group)

### `vpc_id`

* **What it is:** Your VPC ID.
* **Used for:** Networking reference for everything: subnets, routing, SGs, endpoints, etc.

### `public_subnet_ids`

* **What it is:** Public subnets (typically have a route to Internet Gateway).
* **Used for:** Internet-facing resources (ALB, NAT gateway if you add it, bastion host, public services).

### `private_subnet_ids`

* **What it is:** Private subnets (no direct inbound from internet).
* **Used for:** RDS (you did this), private compute, Lambda VPC attachment.
* **Important:** If Lambda is attached to private subnets and you don’t have NAT/VPC endpoints, it may not reach the internet.

### `app_security_group_id`

* **What it is:** SG used by your app/Lambda to access RDS.
* **Used for:** Database access control:

  * RDS allows inbound from this SG on port 5432.
  * If DB connection fails, you check SG rules first.

---

## Database (RDS Postgres)

### `rds_endpoint`

* **What it is:** DNS hostname to connect to Postgres.
* **Used for:** Connection strings from app/Lambda:

  * `host=pg-lab02-microshop....rds.amazonaws.com`

### `rds_port`

* **What it is:** Postgres port (5432).
* **Used for:** DB connections / security group rules.

### `rds_db_name`

* **What it is:** Default database name (`microshop`).
* **Used for:** DB connection string.

### `rds_master_username`

* **What it is:** The master DB username (`microshop`).
* **Used for:** Login to DB (though you should prefer the secret, not hardcoding).

### `rds_master_user_secret_arn`

* **What it is:** ARN of the Secrets Manager secret that contains the DB master credentials (RDS-managed secret).
* **Used for:** Your app/Lambda can fetch DB credentials securely at runtime.

  * Typical approach: Lambda reads this secret and builds the DB connection.

---

## Secrets Manager (your admin bootstrap secret)

### `asm_secret_name` / `asm_secret_arn`

* **What it is:** A secret you created: `lab02/auth/admin` (admin email/password bootstrap).
* **Used for:** Bootstrapping an admin user on first run, or for internal services needing initial credentials.
* Best practice: app reads it once at startup or on demand.

---

## S3 (buckets)

### `s3_bucket_names`

* **What it is:** Actual bucket names:

  * `microshop-lab02-frontend`
  * `microshop-lab02-assets`
* **Used for:**

  * **frontend bucket:** host static frontend (or origin for CloudFront)
  * **assets bucket:** user uploads, images, static assets, etc.

### `s3_bucket_arns`

* **What it is:** Bucket ARNs.
* **Used for:** IAM policies (grant Lambda/service permissions to these buckets).

---

## Lab metadata

### `lab_name` / `environment`

* **What it is:** Which environment config is active (`lab02`).
* **Used for:** Tagging, naming, multi-env deployments.

---

# How the request flows end-to-end (big picture)

1. Client calls:

   * `https://cstnqxt1o0.execute-api.../health` or any path
2. API Gateway routes request → Lambda (via `lambda_invoke_arn`)
3. Lambda runs inside your VPC private subnets (if you configured VPC attachment)
4. Lambda talks to Postgres using:

   * `rds_endpoint` + `rds_port` + DB creds from `rds_master_user_secret_arn`
5. Lambda may read admin bootstrap secret:

   * `asm_secret_arn`
6. Lambda may read/write S3 buckets:

   * `s3_bucket_names`/`arns`

---

# What you should test right now

### 1) Health endpoint

```bash
curl -i https://cstnqxt1o0.execute-api.ap-southeast-1.amazonaws.com/health
```

### 2) If Lambda should connect to RDS

* Make sure Lambda has permission to read `rds_master_user_secret_arn`
* Make sure VPC networking allows Lambda → RDS (it usually does if SG is correct)
* Ensure your Lambda code actually uses those env vars / secrets

---

If you tell me what runtime you’re using (Python/Node) and how you want the Lambda to fetch DB creds (Secrets Manager vs hardcoded), I can give you a minimal working handler that:

* reads `rds_master_user_secret_arn`
* connects to Postgres
* returns `/health` and maybe a `/db-check` endpoint.
