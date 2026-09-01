terraform {
  # Partial backend configuration. Bucket, key, region and an optional state
  # KMS key are supplied by the caller or GitHub Environment variables.
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}
