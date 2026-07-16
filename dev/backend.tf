# One S3 state key per environment. Same bucket is fine; different keys = different state.
# Replace bucket / dynamodb_table / region with your org values before real applies.
terraform {
  backend "s3" {
    bucket         = "tf-env-isolation-poc-state"
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-env-isolation-poc-locks"
    encrypt        = true
  }
}
