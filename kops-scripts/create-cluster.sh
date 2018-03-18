#!/bin/bash

kops create cluster \
    --zones ${availability_zones} \
    --state s3://${TF_VAR_prefix}-${TF_VAR_kops_state} \
    ${kops_cluster_name}.${TF_VAR_domain}
