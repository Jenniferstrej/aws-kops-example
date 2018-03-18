data "aws_acm_certificate" "jenninha" {
  domain   = ${var.domain}
  types = ["AMAZON_ISSUED"]
  most_recent = true
}

data "template_file" "node_web_app_service" {
  template = "${file("../k8s/node_web_app_service.yaml")}"
  vars {
    certificate_arn = "${data.aws_acm_certificate.jenninha.rendered}"
  }
}
