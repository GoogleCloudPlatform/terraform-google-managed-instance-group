# Managed instance group zonal example

This example shows how to create a zonal instance group and perform a rolling upgrade.

## Setup Environment

```
gcloud auth application-default login
export GOOGLE_PROJECT=$(gcloud config get-value project)
```

## Run Terraform

```
terraform init
terraform plan
terraform apply
```

The output variables display the 3 instances that were created:

```
terraform output
```

## Rolling upgrade

Add a label to the instance template, this will trigger a rolling update.

```
cat > terraform.tfvars <<EOF
labels {
  created_by = "terraform"
}
EOF
```

```
terraform apply
```

Verify the change has taken place on all new instances:

```
./test.sh label created_by terraform
```

## Clean up

Remove all resources created by Terraform:

```
terraform destroy
```
