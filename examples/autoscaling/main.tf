variable "region" {
  default = "us-central1"
}

provider "google" {
  region = "${var.region}"
}

variable "network_name" {
  default = "mig-autoscale-example"
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

module "mig1" {
  source             = "../../"
  region             = "${var.region}"
  zonal              = false
  name               = "${var.network_name}"
  wait_for_instances = true
  autoscaling        = true
  http_health_check  = true

  autoscaling_cpu = [{
    target = 0.8
  }]

  size              = 1
  min_replicas      = 1
  max_replicas      = 5
  cooldown_period   = 120
  target_tags       = ["${var.network_name}"]
  service_port      = 80
  service_port_name = "http"
  startup_script    = "${data.template_file.startup-script.rendered}"
  target_pools      = ["${module.gce-lb-fr.target_pool}"]
  network           = "${google_compute_subnetwork.default.name}"
  subnetwork        = "${google_compute_subnetwork.default.name}"
}

module "gce-lb-fr" {
  source       = "GoogleCloudPlatform/lb/google"
  version      = "1.0.2"
  region       = "${var.region}"
  name         = "${var.network_name}-lb"
  service_port = "${module.mig1.service_port}"
  target_tags  = ["${module.mig1.target_tags}"]
  network      = "${google_compute_subnetwork.default.name}"
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

output "instance_self_link" {
  value = "${lookup(data.google_compute_region_instance_group.mig1.instances[0], "instance")}"
}

output "instance_status" {
  value = "${lookup(data.google_compute_region_instance_group.mig1.instances[0], "status")}"
}
