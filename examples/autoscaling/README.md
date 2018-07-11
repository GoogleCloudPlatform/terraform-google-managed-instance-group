# Managed instance group autoscaling example

This example creates a managed instance group with autoscaling enabled.

## Set up the environment

Configure your environment to use your default Google Cloud credentials:

```bash
gcloud auth application-default login
export GOOGLE_PROJECT=$(gcloud config get-value project)
```

## Run Terraform

Initialize and run Terraform to deploy the example:

```bash
terraform init
terraform plan
terraform apply
```

Open URL of load balancer in browser after the load balancer is ready:

```bash
EXTERNAL_IP=$(terraform output -module gce-lb-fr external_ip)
(until curl -sf -o /dev/null http://${EXTERNAL_IP}; do echo "Waiting for Load Balancer... "; sleep 5 ; done) && open http://${EXTERNAL_IP}
```

## Testing autoscaling

### CPU utilization test

The CPU autoscaler tries to balance the load across the managed instance group by adding capacity so that the average load is at or below the target utilization. For details, see the [docs on CPU based autoscaling](https://cloud.google.com/compute/docs/autoscaler/scaling-cpu-load-balancing). 

Run the [`lookbusy`](https://github.com/beloglazov/cpu-load-generator.git) command for 2 minutes on one of the instances to trigger CPU based autoscaling:

```bash
gcloud compute ssh $(terraform output instance) -- lookbusy -c 50
```

Open the [Cloud Console](https://console.cloud.google.com/compute/instanceGroups/details/us-central1/autoscale-cluster) to seee that 4 more instances were added to the group in response to the increased CPU.

Press CTRL-C to stop the lookbusy command. After a few minutes, the managed instance group should scale back down.

### Metric test

### Load balancing utilization test

## Cleanup

Remove all resources created by terraform:

```bash
terraform destroy
```
