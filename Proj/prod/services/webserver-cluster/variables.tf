variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket used for the database's remote state storage"
  type        = string
  default     = "terraform-up-and-running-state-apz-2025-01"
}

variable "db_remote_state_key" {
  description = "The key of in the S3 bucket used for the database's remote state storage"
  type        = string
  default     = "prod/data-stores/mysql/terraform.tfstate"

}

variable "cluster_name" {
  description = "The name of the webserver cluster"
  type        = string
  default     = "webservers-prod"

}
