terraform {
  backend "s3" {
    key          = "test/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
