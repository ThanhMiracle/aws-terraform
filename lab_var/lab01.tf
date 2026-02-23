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
      instance_type  = "c7i-flex.large"
      ami_id         = null
      attach_deny_s3 = true
    }

    # read from file
    ec2_user_data = {
      template_path = "${path.module}/user_data/lab01/lab01.sh"
      parts = {
        install_docker = "${path.module}/user_data/lab01/install_docker.sh"
        create_env = "${path.module}/user_data/lab01/create_env.sh"
      }
      app_dir = "/opt/app"
    }

    # -----------------------------
    # RDS PostgreSQL configuration
    # -----------------------------
    db = {
      engine         = "postgres"
      engine_version = "16.9"

      instance_class = "db.t3.micro"

      allocated_storage_gb = 20
      storage_type         = "gp3"

      # IMPORTANT:
      # - db_identifier dùng cho RDS identifier (có thể có dấu '-')
      # - db_name dùng cho tên database (nên chỉ chữ/số/_)
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