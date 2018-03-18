# Dependencies

* [Terraform](https://www.terraform.io/) - tested with Terraform v0.11.4 and provider.aws v1.11.0

* [kops, kubectl, awscli](https://github.com/kubernetes/kops/blob/master/docs/install.md) tested kops Version 1.8.1, kubectl 1.9.3, aws-cli/1.14.57

* [Python](https://www.python.org/) tested with Python 2.7

* [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html)

* You are running this on Linux or Mac OS

# Node app

The "Hello world" node app source code is in the root directory and a Docker image has already been published in [Docker Hub](https://hub.docker.com/r/jenniferstrej/node-web-app/) and it's publicly accessible. The Kubernetes deployment uses this Docker image.

# Running kubernetes with kops

We are using [kops with AWS](https://github.com/kubernetes/kops/blob/master/docs/aws.md) to run this infrastructure.

# Configuring variables

Using `start.sh.template` as a template, create a file called `start.sh` and add your preferred variables and set up domains:

```
export TF_VAR_prefix=prod
export TF_VAR_domain=yourdomain.com
export subdomain=subdomain.yourdomain.com
export TF_VAR_region=eu-west-1
export TF_VAR_kops_state=preferred-kops-state-bucket-name
export hosted_zone_id=Check_your_zone_ID_in_Route53
export availability_zones=eu-west-1a,eu-west-1b
export kops_cluster_name=kops-node-cluster
```
 - TF_VAR_prefix: Your prefix, in case you want to run different environments in different states

 - TF_VAR_domain: this will also be used as your kops domain when [Configuring DNS for kops](https://github.com/kubernetes/kops/blob/master/docs/aws.md#configure-dns). For simplicity, this example is using a domain registered on AWS. If you would like to configure DNS differently, see this section https://github.com/kubernetes/kops/blob/master/docs/aws.md#configure-dns

 - subdomain: The subdomain we will create and associate with your load balancer to reach our Node app

 - TF_VAR_region: The AWS region of choice to run our resources

 - TF_VAR_kops_state: The suffix for your kops state AWS bucket to be created. It will follow TF_VAR_prefix and a `-`

 - hosted_zone_id: For simplicity in this setup, we are assuming you have a domain already created in AWS and a hosted_zone. So, please check it on the console and paste on the file.

 - availability_zones: We are opting for using 2 availability zones for more resilience in our cluster

 - kops_cluster_name: a name of your preferrence to call your k8s cluster

 Once you've made the changes to this file, you need to source it (not execute it)

 ```
 source start.sh
 ```

# S3 Terraform state bucket

It's recommended that you save your terraform state in a versioned S3 bucket.

For separation and safety purposes, we will create our S3 terraform state bucket separated from our terraform code.

(Make sure you have your [AWS user configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) with the relevant S3 permissions)

```bash
aws s3api create-bucket --bucket ${terraform_state_bucket} --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1
aws s3api put-bucket-versioning --bucket ${terraform_state_bucket} --versioning-configuration Status=Enabled
```

Once the bucket is created, add your state bucket name to the `tf/provider.tf` file by replacing `changeme`. Unfortunately this needs to be done manually.

# Terraform kops user

In order to provision our cluster, we need to create a kops user in your AWS account.

Make sure you have your [AWS user configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) with permissions to create the kops user. Then run:

```
cd tf
terraform init
terraform plan
terraform apply
cd ..
```

The kops user credentials will appear on the output. Run [AWS CLI configure](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) command using the output credentials.

```bash
export AWS_ACCESS_KEY_ID=KOPSACCESSKEYID
export AWS_SECRET_ACCESS_KEY=kops+Access+key+secret
```

# Creating the kops cluster

In order to create the cluster, run:

```bash
kops create cluster \
    --zones ${availability_zones} \
    --state s3://${TF_VAR_prefix}-${TF_VAR_kops_state} \
    ${kops_cluster_name}.${TF_VAR_domain}
```

When you verify the configuration is correct, apply changes with:

```bash
kops update cluster \
    --state s3://${TF_VAR_prefix}-${TF_VAR_kops_state} \
    ${kops_cluster_name}.${TF_VAR_domain} --yes
```

For more options to configure after creation, see https://github.com/kubernetes/kops/blob/master/docs/aws.md#customize-cluster-configuration

Wait for about 5-10 minutes for the kops DNS to propagate and your cluster to be ready. You can watch until it's ready by running:

```bash
watch -b -n 30 kops validate cluster --state s3://${TF_VAR_prefix}-${TF_VAR_kops_state}
```

# Service

## k8s deployment

The configuration for k8s deployment is on the file `k8s/node-web-app-deployment.yaml`.

```
kubectl create -f k8s/node-web-app-deployment.yaml
```

## k8s service

In order to expose your created deployment you need to create a Load Balanced service. Run:

```
kubectl expose deployment node-web-app-deployment --type=LoadBalancer --port=80 --target-port=8080 --name=node-web-app-public
```

This will create an ELB. Once it's created, run:

```
sh k8s/route53.sh
```

This will lookup the Load Balancer DNS name and find the necessary values in order to create a subdomain that will point to the LB.


You should be able to see the Node app run on your subdomain
```
curl $subdomain
```

#### Destroying your resources  ####

Change back your [AWS CLI configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) to a user that has full permissions on the resources we are using.

```bash
export AWS_ACCESS_KEY_ID=YOURACCESSKEYID
export AWS_SECRET_ACCESS_KEY=your+Access+key+secret
```

Remove kops cluster (edit the file with your cluster name as Configuration Management hasn't been setup at the moment):

```bash
kops delete cluster \
    --name ${kops_cluster_name}.${TF_VAR_domain} \
    --state s3://${TF_VAR_prefix}-${TF_VAR_kops_state}
```

then apply changes:

```bash
kops delete cluster \
    --name ${kops_cluster_name}.${TF_VAR_domain} \
    --state s3://${TF_VAR_prefix}-${TF_VAR_kops_state} --yes
```

Now we will remove all AWS resources created with terraform that enabled kops to work (permissions, bucket, etc.)

```
cd tf
terraform plan --destroy
terraform destroy
```

You will get an error saying that you can't delete kops state bucket as the bucket is not empty. This is a good safety measure so we make sure no state versions are deleted by mistake (hence versioning being enabled). If you don't want to keep the kops state file versions, go to your AWS bucket and remove the objects/versions manually. Then run `terraform destroy` again.

You will get an error related to the output. This is because you no longer have the kops user credentials to output. That is fine.

The only chargeable resource left is the terraform state file that has been created by awscli, for the same separation reason (avoid unwanted destruction). So I didn't make a command to destroy it and direct you to go to the bucket on the console and delete it along with it's contents.

After that, make sure you delete your `.terraform` folder.


## Other things to consider later

1) SSL termination to the Load balancer;
2) caching;
3) the VPC provisioning in Terraform so then I can use the same VPC for other resources that I may need to create (databases, etc.), then provide it as a parameter to kops;
4) Monitoring (i.e. Prometheus, Riemann, Cloudwatch)
4) Add CI pipeline to deploy container.
