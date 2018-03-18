provider "aws" {
  region = "${var.region}"
  version = "~> 1.11"
}

terraform {
  backend "s3" {
    bucket = "my-state-bucket"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}
