# backend.hcl
bucket         = "terraform-up-and-running-state-apz-2025-01"
region         = "us-east-2"
dynamodb_table = "terraform-up-and-running-locks"
encrypt        = true