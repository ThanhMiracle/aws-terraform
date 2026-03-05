locals {
  lab02 = {
    environment = "lab02"

    vpc = {
      cidr            = "10.20.0.0/16"
      subnet_count    = 2
      public_subnets  = ["10.20.1.0/24", "10.20.2.0/24"]
      private_subnets = ["10.20.10.0/24", "10.20.20.0/24"]
    }

    db = {
      engine               = "postgres"
      engine_version       = "16"
      instance_class       = "db.t4g.micro"
      allocated_storage_gb = 20

      db_name  = "microshop"
      username = "microshop"
      port     = 5432

      publicly_accessible   = false
      multi_az              = false
      backup_retention_days = 0
      deletion_protection   = false
      skip_final_snapshot   = true
      apply_immediately     = true

      # optional override
      # db_identifier = "microshop-lab02"
    }

    sqs = {
      name               = "jobs"
      visibility_timeout = 60
      max_receive_count  = 5
    }

    s3 = {
      frontend_bucket = "microshop-lab02-frontend"
      assets_bucket   = "microshop-lab02-assets"
    }

    # Keep admin bootstrap values here (config-only).
    auth = {
      admin_email    = "admin@example.com"
      admin_password = "admin123"
    }

    # Optional: keep "policy settings" as config knobs only (no ARNs here)
    # Real JSON policies must be built in root using module outputs.
    policy = {
      enable_api_inline_policy = true
      enable_fe_bucket_policy  = true
    }

    lambda = {
      filename = "./artifacts/lambda_stub.zip"
      runtime  = "python3.11"
      handler  = "app.handler"
    }

    api = {
      # optional; defaults exist in root
      routes = [{ route_key = "GET /health" }, { route_key = "GET /db-check" }, { route_key = "ANY /{proxy+}" }]
    }
  }
}