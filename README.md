# Managed Instance Group Terraform Module

Modular Google Compute Engine managed instance group for Terraform.

## Usage

```ruby
module "mig1" {
  source            = "GoogleCloudPlatform/managed-instance-group/google"
  version           = "1.1.14"
  region            = "${var.region}"
  zone              = "${var.zone}"
  name              = "group1"
  size              = 2
  service_port      = 80
  service_port_name = "http"
  http_health_check = false
  target_pools      = ["${module.gce-lb-fr.target_pool}"]
  target_tags       = ["allow-service1"]
  ssh_source_ranges = ["0.0.0.0/0"]
}
```

> NOTE: Make sure you are using [version pinning](https://www.terraform.io/docs/modules/usage.html#module-versions) to avoid unexpected changes when the module is updated.

## Resources created

- [`google_compute_instance_template.default`](https://www.terraform.io/docs/providers/google/r/compute_instance_template.html): The instance template assigned to the instance group.
- [`google_compute_instance_group_manager.default`](https://www.terraform.io/docs/providers/google/r/compute_instance_group_manager.html): The instange group manager that uses the instance template and target pools. 
- [`google_compute_firewall.default-ssh`](https://www.terraform.io/docs/providers/google/r/compute_firewall.html): Firewall rule to allow ssh access to the instances.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| access\_config | The access config block for the instances. Set to [] to remove external IP. | list | `<list>` | no |
| automatic\_restart | Automatically restart the instance if terminated by GCP - Set to false if using preemptible instances | string | `"true"` | no |
| autoscaling | Enable autoscaling. | string | `"false"` | no |
| autoscaling\_cpu | Autoscaling, cpu utilization policy block as single element array. https://www.terraform.io/docs/providers/google/r/compute_autoscaler.html#cpu_utilization | list | `<list>` | no |
| autoscaling\_lb | Autoscaling, load balancing utilization policy block as single element array. https://www.terraform.io/docs/providers/google/r/compute_autoscaler.html#load_balancing_utilization | list | `<list>` | no |
| autoscaling\_metric | Autoscaling, metric policy block as single element array. https://www.terraform.io/docs/providers/google/r/compute_autoscaler.html#metric | list | `<list>` | no |
| can\_ip\_forward | Allow ip forwarding. | string | `"false"` | no |
| compute\_image | Image used for compute VMs. | string | `"projects/debian-cloud/global/images/family/debian-9"` | no |
| cooldown\_period | Autoscaling, cooldown period in seconds. | string | `"60"` | no |
| depends\_id | The ID of a resource that the instance group depends on. | string | `""` | no |
| disk\_auto\_delete | Whether or not the disk should be auto-deleted. | string | `"true"` | no |
| disk\_size\_gb | The size of the image in gigabytes. If not specified, it will inherit the size of its base image. | string | `"0"` | no |
| disk\_type | The GCE disk type. Can be either pd-ssd, local-ssd, or pd-standard. | string | `"pd-ssd"` | no |
| distribution\_policy\_zones | The distribution policy for this managed instance group when zonal=false. Default is all zones in given region. | list | `<list>` | no |
| hc\_healthy\_threshold | Health check, healthy threshold. | string | `"1"` | no |
| hc\_initial\_delay | Health check, intial delay in seconds. | string | `"30"` | no |
| hc\_interval | Health check, check interval in seconds. | string | `"30"` | no |
| hc\_path | Health check, the http path to check. | string | `"/"` | no |
| hc\_port | Health check, health check port, if different from var.service_port, if not given, var.service_port is used. | string | `""` | no |
| hc\_timeout | Health check, timeout in seconds. | string | `"10"` | no |
| hc\_unhealthy\_threshold | Health check, unhealthy threshold. | string | `"10"` | no |
| http\_health\_check | Enable or disable the http health check for auto healing. | string | `"true"` | no |
| instance\_labels | Labels added to instances. | map | `<map>` | no |
| local\_cmd\_create | Command to run on create as local-exec provisioner for the instance group manager. | string | `":"` | no |
| local\_cmd\_destroy | Command to run on destroy as local-exec provisioner for the instance group manager. | string | `":"` | no |
| machine\_type | Machine type for the VMs in the instance group. | string | `"f1-micro"` | no |
| max\_replicas | Autoscaling, max replicas. | string | `"5"` | no |
| metadata | Map of metadata values to pass to instances. | map | `<map>` | no |
| min\_replicas | Autoscaling, min replics. | string | `"1"` | no |
| mode | The mode in which to attach this disk, either READ_WRITE or READ_ONLY. | string | `"READ_WRITE"` | no |
| module\_enabled |  | string | `"true"` | no |
| name | Name of the managed instance group. | string | n/a | yes |
| network | Name of the network to deploy instances to. | string | `"default"` | no |
| network\_ip | Set the network IP of the instance in the template. Useful for instance groups of size 1. | string | `""` | no |
| preemptible | Use preemptible instances - lower price but short-lived instances. See https://cloud.google.com/compute/docs/instances/preemptible for more details | string | `"false"` | no |
| project | The project to deploy to, if not set the default provider project is used. | string | `""` | no |
| region | Region for cloud resources. | string | `"us-central1"` | no |
| service\_account\_email | The email of the service account for the instance template. | string | `"default"` | no |
| service\_account\_scopes | List of scopes for the instance template service account | list | `<list>` | no |
| service\_port | Port the service is listening on. | string | n/a | yes |
| service\_port\_name | Name of the port the service is listening on. | string | n/a | yes |
| size | Target size of the managed instance group. | string | `"1"` | no |
| ssh\_fw\_rule | Whether or not the SSH Firewall Rule should be created | string | `"true"` | no |
| ssh\_source\_ranges | Network ranges to allow SSH from | list | `<list>` | no |
| startup\_script | Content of startup-script metadata passed to the instance template. | string | `""` | no |
| subnetwork | The subnetwork to deploy to | string | `"default"` | no |
| subnetwork\_project | The project the subnetwork belongs to. If not set, var.project is used instead. | string | `""` | no |
| target\_pools | The target load balancing pools to assign this group to. | list | `<list>` | no |
| target\_tags | Tag added to instances for firewall and networking. | list | `<list>` | no |
| update\_policy | The upgrade policy to apply when the instance template changes. | list | `<list>` | no |
| wait\_for\_instances | Wait for all instances to be created/updated before returning | string | `"false"` | no |
| zonal | Create a single-zone managed instance group. If false, a regional managed instance group is created. | string | `"true"` | no |
| zone | Zone for managed instance groups. | string | `"us-central1-f"` | no |

## Outputs

| Name | Description |
|------|-------------|
| depends\_id | Id of the dummy dependency created used for intra-module dependency creation with zonal groups. |
| health\_check | The healthcheck for the managed instance group |
| instance\_group | Link to the `instance_group` property of the instance group manager resource. |
| instance\_template | Link to the instance_template for the group |
| instances | List of instances in the instance group. Note that this can change dynamically depending on the current number of instances in the group and may be empty the first time read. |
| name | Pass through of input `name`. |
| network\_ip | Pass through of input `network_ip`. |
| region\_depends\_id | Id of the dummy dependency created used for intra-module dependency creation with regional groups. |
| region\_instance\_group | Link to the `instance_group` property of the region instance group manager resource. |
| service\_port | Pass through of input `service_port`. |
| service\_port\_name | Pass through of input `service_port_name`. |
| target\_tags | Pass through of input `target_tags`. |