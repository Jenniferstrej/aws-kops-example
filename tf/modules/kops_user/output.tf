output "kops_user_access_key_id" {
  value = "${aws_iam_access_key.kops.id}"
}

output "kops_user_key_secret" {
  value = "${aws_iam_access_key.kops.secret}"
}
