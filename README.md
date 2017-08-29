# Managed Instance Group Terraform Module

Modular Google Compute Engine managed instance group for Terraform.

## Usage

```ruby
data "template_file" "php-startup-script" {
  template = "${file("${format("%s/../scripts/gceme.sh.tpl", path.module)}")}"
  vars {
    PROXY_PATH = ""
  }
}

module "mig1" {
  source            = "github.com/GoogleCloudPlatform/terraform-google-managed-instance-group"
  region            = "${var.region}"
  zone              = "${var.zone}"
  name              = "group1"
  size              = 2
  service_port      = 80
  service_port_name = "http"
  target_pools      = ["${module.gce-lb-fr.target_pool}"]
  target_tags       = ["allow-service1"]
  startup_script    = "${data.template_file.php-startup-script.rendered}"
}
```

### Input variables

- `region` (optional): Region for cloud resources. Default is `us-central1`.
- `zone` (optional): Zone for managed instance groups. Default is `us-central1-f`.
- `network` (optional): Name of the network to deploy instances to. Default is `default`.
- `subnetwork` (optional): Name of the subnetwork to deploy instances to. Default is `default`.
- `name` (required): Name of the managed instance group.
- `size` (optional): Target size of the manged instance group. Default is `1`.
- `startup_script` (optional): Content of startup-script metadata passed to the instance template. 
- `access_config` (optiona): The access config block for the instances. Set to `[]` to remove external IP. Default is `[{}]`
- `metadata` (optional): Map of metadata values to pass to instances.
- `can_ip_forward` (optional): Allow ip forwarding. Default is `false`.
- `network_ip` (optional): Set the network IP of the instance in the template. Useful for instance groups of size 1.
- `machine_type` (optional): Machine type for the VMs in the instance group. Default is `f1-micro`.
- `compute_image` (optional): Image used for compute VMs. Default is `debian-cloud/debian-8`.
- `service_port` (required) Port the service is listening on.
- `service_port_name` (required): Name of the port the service is listening on.
- `target_tags` (required): List of tags added to instances for firewall and networking. Default is `["allow-service"]`.
- `target_pools` (optional): The target load balancing pools to assign this group to.
- `depends_id` (optional): The ID of a resource that the instance group depends on. This is added as metadata `tf_depends_id` on each instance.
- `local_cmd_destroy` (optional): Command to run on destroy as local-exec provisioner for the instance group manager.
- `module_enabled` (optional): Boolean input used to toggle creation of this modules resources.
- `service_account_email` (optional): The email of the service account for the instance template. Default is `default`.
- `service_account_scopes` (optional): List of scopes for the instance template service account. Default is `["compute", "logging.write", "monitoring.write", "devstorage.full_control"]`

### Output variables 

- `name`: Pass through of input `name`.
- `instance_group`: Link to the `instance_group` property of the instance group manager resource.
- `target_tags`: Pass through of input `target_tags`.
- `service_port`: Pass through of input `service_port`.
- `service_port_name`: Pass through of input `service_port_name`.
- `depends_id`: Id of the dummy dependency created used for intra-module dependency creation.
- `network_ip`: Pass through of input `network_ip`.

## Resources created

- [`google_compute_instance_template.default`](https://www.terraform.io/docs/providers/google/r/compute_instance_template.html): The instance template assigned to the instance group.
- [`google_compute_instance_group_manager.default`](https://www.terraform.io/docs/providers/google/r/compute_instance_group_manager.html): The instange group manager that uses the instance template and target pools. 
- [`google_compute_firewall.default-ssh`](https://www.terraform.io/docs/providers/google/r/compute_firewall.html): Firewall rule to allow ssh access to the instances.
