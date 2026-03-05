locals {
  lab01 = {
    environment = "lab01"

    vpc = {
      cidr         = "10.0.0.0/16"
      subnet_count = 2
      public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      private_subnets = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
    }

    ec2 = {
      instance_type  = "t3.micro"
      ami_id         = null
      attach_deny_s3 = false
      enable_product_image_upload = true

    }

    mq = {
      recovery_window_days = 0
    }

    secrets = {
      from_email_address = "noreply@yourdomain.com"
      from_email         = "MicroShop <noreply@yourdomain.com>"

      jwt_secret         = "change-me"
      admin_email        = "admin@example.com"
      admin_password     = "admin123"

      smtp_host     = "email-smtp.ap-southeast-1.amazonaws.com"
      smtp_port     = 587
      smtp_use_tls  = true
      smtp_use_auth = true
      smtp_user     = "YOUR_SES_SMTP_USERNAME"
      smtp_pass     = "YOUR_SES_SMTP_PASSWORD"
    }

    s3 = {
      images_bucket_name = "lab01-product-images"
      # or a fixed name if you prefer:
      # images_bucket_name = "lab01-product-images-yourname"
    }

    # ✅ add LB config (so root doesn't invent defaults)
    lb = {
      target_port      = 80
      healthcheck_path = "/health"
    }

    user_data = {
      template_path = "${path.module}/user_data/lab01/lab01.sh"
      parts = {
        install_docker = "${path.module}/user_data/lab01/install_docker.sh"
      }
      app_dir = "/opt/app"
    }

    db = {
      engine         = "postgres"
      engine_version = "16.9"
      instance_class = "db.t3.micro"
      allocated_storage_gb = 20
      storage_type         = "gp3"
      db_identifier = "lab01-appdb"
      db_name       = "appdb"
      username = "appuser"
      port     = 5432
      publicly_accessible = false
      multi_az            = false
      backup_retention_days = 0
      deletion_protection   = false
      skip_final_snapshot   = true
      apply_immediately = true
    }
  }
}