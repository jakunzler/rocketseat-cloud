resource "aws_s3_bucket" "s3_bucket" {
  bucket = "${var.org_name}-cloud-${terraform.workspace}"

  tags = {
    Name        = "My new bucket"
    Environment = "Dev"
    IAC = true
    context = "${terraform.workspace}"
  }
}