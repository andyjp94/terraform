provider "aws" {
  region  = "eu-west-1"
}

# Additional provider configuration for west coast region
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}
