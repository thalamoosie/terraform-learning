provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "example-workspaces" {
  ami           = "ami-08221e706f343d7b7"
  instance_type = terraform.workspace == "default" ? "t2.medium" : "t2.micro"
}

terraform {
  backend "s3" {
    key = "workspaces-example/terraform.tfstate"
  }
}
