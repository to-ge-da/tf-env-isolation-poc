# One S3 state key per environment. Same bucket is fine; different keys = different state.
# Replace bucket / region with your org values before real applies.
terraform {
  backend "s3" {
    bucket       = "tf-env-isolation-poc-state"
    key          = "env/uat/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
