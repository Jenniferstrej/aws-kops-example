#!/bin/bash

kops delete cluster \
    --name ${kops_cluster_name}.${TF_VAR_domain} \
    --state s3://${TF_VAR_prefix}-${TF_VAR_kops_state} $1 # explicitly add --yes
