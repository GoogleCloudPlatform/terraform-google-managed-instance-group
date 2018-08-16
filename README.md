# Managed Instance Group Terraform Module

Modular Google Compute Engine managed instance group for Terraform.

## Usage

```ruby
module "mig1" {
  source            = "GoogleCloudPlatform/managed-instance-group/google"
  version           = "1.1.13"
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
