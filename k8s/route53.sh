#!/bin/bash
set -e

cd k8s

# Print exposed address
export elb_dns_name=$(kubectl describe service node-web-app-public | grep "LoadBalancer Ingress" | sed 's/LoadBalancer Ingress:[ ]*//')

export elb_hosted_zone_id=$(aws elb describe-load-balancers --region=${TF_VAR_region} | python elb.py ${elb_dns_name})
export domain_name=${subdomain}

# get gettext package in order to run envsubst
envsubst < route53-record.template > route53-record.json

aws route53 change-resource-record-sets --hosted-zone-id ${hosted_zone_id} --change-batch file://$(pwd)/route53-record.json
