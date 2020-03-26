module "s3" {
  source = "../../modules/s3"

  bucket = "onica-venkata-kollipara"
  region = "us-east-1"
  Name        = "My bucket"
  Environment = "Dev"
}