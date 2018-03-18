provider "aws" {
  region = "${var.region}"
  version = "~> 1.11"
}

terraform {
  backend "s3" {
    bucket = "changeme"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}
