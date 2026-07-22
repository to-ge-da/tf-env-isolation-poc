# ANTI-PATTERN: one shared state for all environment aliases.
# Same bucket as the isolated roots is fine; this single key is the problem.
# Replace bucket / dynamodb_table / region with your org values before real applies.
terraform {
  backend "s3" {
    bucket         = "tf-env-isolation-poc-state"
    key            = "env/legacy/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-env-isolation-poc-locks"
    encrypt        = true
  }
}
