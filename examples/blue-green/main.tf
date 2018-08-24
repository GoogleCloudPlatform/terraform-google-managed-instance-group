variable "rolling_update_policy" {
  type = "map"

  default = {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 2
    max_unavailable_fixed = 0
    min_ready_sec         = 50
  }
}

variable "deploy_color" {
  default = "blue"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-b"
}

provider "google" {
  region = "${var.region}"
}

variable "network_name" {
  default = "mig-blue-green-example"
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
    COLOR      = "${var.deploy_color}"
  }
}

data "google_compute_zones" "available" {
  region = "${var.region}"
}

module "mig1" {
  source             = "../../"
  region             = "${var.region}"
  zone               = "${var.zone}"
  name               = "${var.network_name}"
  size               = 2
  target_tags        = ["${var.network_name}"]
  service_port       = 80
  service_port_name  = "http"
  startup_script     = "${data.template_file.startup-script.rendered}"
  wait_for_instances = true
  http_health_check  = false
  network            = "${google_compute_subnetwork.default.name}"
  subnetwork         = "${google_compute_subnetwork.default.name}"
  target_pools       = ["${module.gce-lb-fr.target_pool}"]

  update_strategy       = "ROLLING_UPDATE"
  rolling_update_policy = ["${var.rolling_update_policy}"]
}

module "gce-lb-fr" {
  source       = "GoogleCloudPlatform/lb/google"
  version      = "1.0.3"
  region       = "${var.region}"
  name         = "${var.network_name}"
  service_port = "${module.mig1.service_port}"
  target_tags  = ["${module.mig1.target_tags}"]
  network      = "${google_compute_subnetwork.default.name}"
}

output "load-balancer-ip" {
  value = "${module.gce-lb-fr.external_ip}"
}

output "deploy-color" {
  value = "${var.deploy_color}"
}
