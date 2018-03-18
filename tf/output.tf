output "kops_user_access_key_id" {
  value = "${module.kops_user.kops_user_access_key_id}"
}

output "kops_user_key_secret" {
  value = "${module.kops_user.kops_user_key_secret}"
}
