provider "aws" {
  region = "us-east-1"


  default_tags {
    tags = {
      "Automation"  = "terraform"
      "Project"     = "nest"
      "Environment" = "dev"
    }
  }
}
