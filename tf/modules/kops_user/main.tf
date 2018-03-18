resource "aws_iam_group" "kops" {
  name = "kops"
}

resource "aws_iam_group_policy_attachment" "kops_AmazonEC2FullAccess" {
  group      = "${aws_iam_group.kops.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_group_policy_attachment" "kops_AmazonRoute53FullAccess" {
  group      = "${aws_iam_group.kops.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

resource "aws_iam_group_policy_attachment" "kops_AmazonS3FullAccess" {
  group      = "${aws_iam_group.kops.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_group_policy_attachment" "kops_IAMFullAccess" {
  group      = "${aws_iam_group.kops.name}"
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_group_policy_attachment" "kops_AmazonVPCFullAccess" {
  group      = "${aws_iam_group.kops.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_user" "kops" {
  name = "kops"
}

resource "aws_iam_access_key" "kops" {
  user = "${aws_iam_user.kops.name}"
}

resource "aws_iam_group_membership" "kops" {
  name = "kops"

  users = [
    "${aws_iam_user.kops.name}"
  ]

  group = "${aws_iam_group.kops.name}"
}
