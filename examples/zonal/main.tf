variable "labels" {
  type    = "map"
  default = {}
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-b"
}

variable "module_enabled" {
  default = true
}

variable "http_health_check" {
  default = true
}

provider "google" {
  region = "${var.region}"
}

variable "network_name" {
  default = "mig-zonal-example"
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
  source             = "../../"
  module_enabled     = "${var.module_enabled}"
  region             = "${var.region}"
  zone               = "${var.zone}"
  zonal              = true
  name               = "${var.network_name}"
  size               = 3
  target_tags        = ["${var.network_name}"]
  service_port       = 80
  service_port_name  = "http"
  startup_script     = "${data.template_file.startup-script.rendered}"
  wait_for_instances = true
  network            = "${google_compute_subnetwork.default.name}"
  subnetwork         = "${google_compute_subnetwork.default.name}"
  instance_labels    = "${var.labels}"
  http_health_check  = "${var.http_health_check}"
  update_strategy    = "ROLLING_UPDATE"

  rolling_update_policy = [{
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 4
    max_unavailable_fixed = 4
    min_ready_sec         = 50
  }]
}

output "instance_self_link_1" {
  value = "${element(module.mig1.instances[0], 0)}"
}

output "instance_self_link_2" {
  value = "${element(module.mig1.instances[0], 1)}"
}

output "instance_self_link_3" {
  value = "${element(module.mig1.instances[0], 2)}"
}
