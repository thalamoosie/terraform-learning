provider "aws" {
  region = "us-east-2"
}

resource "aws_db_instance" "example" {
  identifier_prefix   = "terraform-up-and-running"
  engine              = "mysql"
  allocated_storage   = 10 #10gb
  instance_class      = "db.t3.micro"
  skip_final_snapshot = true
  db_name             = var.db_name

  username = var.db_username
  password = var.db_password
}

terraform {
  backend "s3" {
    key            = "prod/data-stores/mysql/terraform.tfstate"
    bucket         = "terraform-up-and-running-state-apz-2025-01"
    region         = "us-east-2"
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}
