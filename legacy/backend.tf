# ANTI-PATTERN: one shared state for all environment aliases.
# Same bucket as the isolated roots is fine; this single key is the problem.
# Replace bucket / region with your org values before real applies.
terraform {
  backend "s3" {
    bucket       = "tf-env-isolation-poc-state"
    key          = "env/legacy/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
