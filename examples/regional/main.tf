variable "labels" {
  type    = "map"
  default = {}
}

variable "region" {
  default = "us-central1"
}

provider "google" {
  region = "${var.region}"
}

variable "network_name" {
  default = "mig-regional-example"
}

resource "google_compute_network" "default" {
  name                    = "${var.network_name}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "default" {
  name                     = "${var.network_name}"
  ip_cidr_range            = "10.127.0.0/20"
  network                  = "${google_compute_network.default.self_link}"
  region                   = "${var.region}"
  private_ip_google_access = true
}

data "template_file" "startup-script" {
  template = "${file("${format("%s/gceme.sh.tpl", path.module)}")}"

  vars {
    PROXY_PATH = ""
  }
}

data "google_compute_zones" "available" {
  region = "${var.region}"
}

module "mig1" {
  source                    = "../../"
  region                    = "${var.region}"
  distribution_policy_zones = ["${data.google_compute_zones.available.names}"]
  zonal                     = false
  name                      = "${var.network_name}"
  size                      = 3
  target_tags               = ["${var.network_name}"]
  service_port              = 80
  service_port_name         = "http"
  startup_script            = "${data.template_file.startup-script.rendered}"
  wait_for_instances        = true
  http_health_check         = false
  network                   = "${google_compute_subnetwork.default.name}"
  subnetwork                = "${google_compute_subnetwork.default.name}"
  instance_labels           = "${var.labels}"
  update_strategy           = "ROLLING_UPDATE"

  rolling_update_policy = [{
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 4
    max_unavailable_fixed = 4
    min_ready_sec         = 50
  }]
}

// null resource used to create dependency with the instance group data source to trigger a refresh.
resource "null_resource" "template" {
  triggers {
    instance_template = "${element(module.mig1.instance_template, 0)}"
  }
}

data "google_compute_region_instance_group" "mig1" {
  self_link  = "${module.mig1.region_instance_group}"
  depends_on = ["null_resource.template"]
}

output "instance_self_link_1" {
  value = "${lookup(data.google_compute_region_instance_group.mig1.instances[0], "instance")}"
}

output "instance_status_1" {
  value = "${lookup(data.google_compute_region_instance_group.mig1.instances[0], "status")}"
}

output "instance_self_link_2" {
  value = "${lookup(data.google_compute_region_instance_group.mig1.instances[1], "instance")}"
}

output "instance_status_2" {
  value = "${lookup(data.google_compute_region_instance_group.mig1.instances[1], "status")}"
}

output "instance_self_link_3" {
  value = "${lookup(data.google_compute_region_instance_group.mig1.instances[2], "instance")}"
}

output "instance_status_3" {
  value = "${lookup(data.google_compute_region_instance_group.mig1.instances[2], "status")}"
}
