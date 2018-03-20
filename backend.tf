terraform {
  backend "s3" {
    bucket = "ajp-terraform"
    key    = "tfstate"
    region = "eu-west-1"
  }
}

