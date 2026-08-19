provider "aws" {
  region = "ca-central-1"

  default_tags {
    tags = {
      Project     = "devsecops-lab"
      Environment = "lab"
      ManagedBy   = "terraform"
      Owner       = "vihandu19"
      Component   = "bootstrap"
    }
  }
}