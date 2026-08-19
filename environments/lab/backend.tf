terraform {
  backend "s3" {
    bucket       = "devsecops-lab-tfstate-631421280888"
    key          = "lab/terraform.tfstate"
    region       = "ca-central-1"
    encrypt      = true
    use_lockfile = true
  }
}