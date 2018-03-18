resource "aws_s3_bucket" "kops_state" {
    bucket = "${var.prefix}-${var.kops_state}"
    region   = "${var.region}"
    versioning {
      enabled = true
    }
}
