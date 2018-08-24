# Blue-green Deployment with Managed Instance Group Example

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/GoogleCloudPlatform/terraform-google-managed-instance-group&working_dir=examples/blue-green&page=shell&tutorial=README.md)

This example shows how to perform a blue/green deployment using the managed instance group module.

## Change to the example directory

```
[[ `basename $PWD` != blue-green ]] && cd examples/blue-green
```

## Install Terraform

1. Install Terraform if it is not already installed (visit [terraform.io](https://terraform.io) for other distributions):

```
../terraform-install.sh
```

## Set up the environment

1. Set the project, replace `YOUR_PROJECT` with your project ID:

```
PROJECT=YOUR_PROJECT
```

```
gcloud config set project ${PROJECT}
```

2. Configure the environment for Terraform:

```
[[ $CLOUD_SHELL ]] || gcloud auth application-default login
export GOOGLE_PROJECT=$(gcloud config get-value project)
```

## Run Terraform

```
terraform init
terraform apply
```

## Testing

1. Wait for the load balancer to be provisioned:

```
./test.sh
```

2. Open the URL of the load balancer in your browser:

```
echo http://$(terraform output load-balancer-ip)
```

You should see the example web page with __blue__ color.

3. Change the deployment color to green and perform update:

```
TF_VAR_deploy_color=green terraform apply
```

4. Wait for blue-green deployment to complete:

```
./test.sh
```

5. Open the URL of the load balancer in your browser:

```
echo http://$(terraform output load-balancer-ip)
```

You should see the example web page with __green__ color.

## Cleanup

1. Remove all resources created by terraform:

```
terraform destroy
```
