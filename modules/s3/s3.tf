provider "aws" {
  region = var.region
}
resource "aws_s3_bucket" "default" {
  bucket = var.bucket
  acl    = "private"
  tags = {
    Name        = "${var.Name}"
    Environment = "${var.Environment}"
  }
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        #kms_master_key_id = "${aws_kms_key.mykey.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.default.id

  block_public_acls   = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}
resource "aws_s3_bucket_policy" "b" {
  bucket = aws_s3_bucket.default.id

  policy = <<POLICY
{
	"Version": "2012-10-17",
	"Id": "Policy1573782037453",
	"Statement": [{
		"Sid": "Stmt1573782014292",
		"Effect": "Allow",
		"Principal": {
			"AWS": [
				"arn:aws:iam::833874834655:user/venkata.kollipara",
        "arn:aws:iam::833874834655:role/s3_role"
				
			]
		},
		"Action": [
			"s3:Delete*",
			"s3:Get*",
			"s3:List*",
			"s3:Put*"
		],
		"Resource": [
			"arn:aws:s3:::onica-venkata-kollipara",
			"arn:aws:s3:::onica-venkata-kollipara/*"
		]
	}]
}
POLICY
}

