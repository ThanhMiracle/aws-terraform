locals {
  prod = {
    environment = "prod"

    vpc = {
      cidr            = "10.1.0.0/16"
      subnet_count    = 3
      public_subnets  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
      private_subnets = ["10.1.10.0/24", "10.1.20.0/24", "10.1.30.0/24"]
    }

    ec2 = {
      instance_type               = "t3.small"
      ami_id                      = null
      enable_product_image_upload = true
    }

    mq = {
      deployment_mode      = "ACTIVE_STANDBY_MULTI_AZ"
      host_instance_type   = "mq.t3.micro"
      recovery_window_days = 7
    }

    secrets = {
      recovery_window_days = 7

      from_email_address = "noreply@example.com"
      from_email         = "noreply@example.com"

      jwt_secret     = "change-me-prod"
      admin_email    = "admin@example.com"
      admin_password = "change-me-prod-password"

      smtp_host     = "email-smtp.ap-southeast-1.amazonaws.com"
      smtp_port     = 587
      smtp_use_tls  = true
      smtp_use_auth = true
    }

    s3 = {
      images_bucket_name = "microshop-prod-product-images"
    }

    lb = {
      target_port      = 80
      healthcheck_path = "/health"
    }

    user_data = {
      template_path = "${path.root}/user_data/prod/app.sh"
      parts = {
        install_docker = "${path.root}/user_data/prod/install_docker.sh"
      }
      app_dir = "/opt/app"
    }

    db = {
      engine                = "postgres"
      engine_version        = "16.9"
      instance_class        = "db.t3.small"
      allocated_storage_gb  = 100
      storage_type          = "gp3"
      db_identifier         = "prod-appdb"
      db_name               = "appdb"
      username              = "appuser"
      port                  = 5432
      publicly_accessible   = false
      multi_az              = true
      backup_retention_days = 7
      deletion_protection   = true
      skip_final_snapshot   = false
      apply_immediately     = false
    }
  }
}