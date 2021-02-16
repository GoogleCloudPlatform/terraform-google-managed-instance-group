/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_compute_instance_template" "default" {
  count       = var.module_enabled ? 1 : 0
  project     = var.project
  name_prefix = "${var.name}-"

  labels = var.template_labels

  machine_type = var.machine_type

  region = var.region

  tags = var.target_tags

  network_interface {
    network            = var.subnetwork == "" ? var.network : ""
    subnetwork         = var.subnetwork
    network_ip         = var.network_ip
    subnetwork_project = var.subnetwork_project == "" ? var.project : var.subnetwork_project

    dynamic "access_config" {
      for_each = var.access_config

      content {
        nat_ip       = access_config.value["nat_ip"]
        network_tier = access_config.value["network_tier"]
      }
    }
  }

  can_ip_forward = var.can_ip_forward

  disk {
    auto_delete  = var.disk_auto_delete
    boot         = true
    source_image = var.compute_image
    type         = "PERSISTENT"
    disk_type    = var.disk_type
    disk_size_gb = var.disk_size_gb
  }

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  metadata = merge(
    map("startup-script", var.startup_script, "tf_depends_id", var.depends_id),
    var.metadata
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "default" {
  provider           = google-beta
  count              = var.module_enabled && var.zonal ? 1 : 0
  project            = var.project
  name               = var.name
  description        = "compute VM Instance Group"
  wait_for_instances = var.wait_for_instances

  base_instance_name = var.name

  version {
    name              = var.name
    instance_template = google_compute_instance_template.default[count.index].self_link
  }

  zone = var.zone

  target_pools = var.target_pools

  // There is no way to unset target_size when autoscaling is true so for now, jsut use the min_replicas value.
  // Issue: https://github.com/terraform-providers/terraform-provider-google/issues/667
  target_size = var.autoscaling ? var.min_replicas : var.size

  named_port {
    name = var.service_port_name
    port = var.service_port
  }

  auto_healing_policies {
    health_check      = element(concat(google_compute_health_check.mig-http-health-check.*.self_link, google_compute_health_check.mig-https-health-check.*.self_link), 0)
    initial_delay_sec = var.hc_initial_delay
  }

  provisioner "local-exec" {
    when        = create
    command     = var.local_cmd_create
    interpreter = ["sh", "-c"]
  }

  lifecycle {
    ignore_changes = [version, target_size]
  }
}

resource "google_compute_autoscaler" "default" {
  count   = var.module_enabled && var.autoscaling && var.zonal ? 1 : 0
  name    = var.name
  zone    = var.zone
  project = var.project
  target  = google_compute_instance_group_manager.default[count.index].self_link

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = var.cooldown_period
    dynamic "cpu_utilization" {
      for_each = var.autoscaling_cpu

      content {
        target = metric.value["target"]
      }
    }

    dynamic "metric" {
      for_each = var.autoscaling_metric

      content {
        name   = metric.value["name"]
        target = metric.value["target"]
        type   = metric.value["type"]
      }
    }

    dynamic "load_balancing_utilization" {
      for_each = var.autoscaling_lb

      content {
        target = load_balancing_utilization.value["target"]
      }
    }
  }
}

resource "google_compute_region_instance_group_manager" "default" {
  provider           = google-beta
  count              = var.module_enabled && ! var.zonal ? 1 : 0
  project            = var.project
  name               = var.name
  description        = "compute VM Instance Group"
  wait_for_instances = var.wait_for_instances

  base_instance_name = var.name

  region = var.region

  dynamic "update_policy" {
    for_each = var.update_policy

    content {
      type                    = update_policy.value["type"]
      minimal_action          = update_policy.value["minimal_action"]
      max_surge_percent       = update_policy.value["max_surge_percent"]
      max_surge_fixed         = update_policy.value["max_surge_fixed"]
      max_unavailable_percent = update_policy.value["max_unavailable_percent"]
      max_unavailable_fixed   = update_policy.value["max_unavailable_fixed"]
      min_ready_sec           = update_policy.value["min_ready_sec"]
    }
  }

  distribution_policy_zones = var.distribution_policy_zones

  target_pools = var.target_pools

  // There is no way to unset target_size when autoscaling is true so for now, jsut use the min_replicas value.
  // Issue: https://github.com/terraform-providers/terraform-provider-google/issues/667
  target_size = var.autoscaling ? var.min_replicas : var.size

  auto_healing_policies {
    health_check      = element(concat(google_compute_health_check.mig-http-health-check.*.self_link, google_compute_health_check.mig-https-health-check.*.self_link), 0)
    initial_delay_sec = var.hc_initial_delay
  }

  named_port {
    name = var.service_port_name
    port = var.service_port
  }

  version {
    name              = var.name
    instance_template = google_compute_instance_template.default[count.index].self_link
  }

  provisioner "local-exec" {
    when        = create
    command     = var.local_cmd_create
    interpreter = ["sh", "-c"]
  }

  lifecycle {
    ignore_changes = [version, distribution_policy_zones, target_size]
  }
}

resource "google_compute_region_autoscaler" "default" {
  count   = var.module_enabled && var.autoscaling && ! var.zonal ? 1 : 0
  name    = var.name
  region  = var.region
  project = var.project
  target  = google_compute_region_instance_group_manager.default[count.index].self_link

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = var.cooldown_period

    dynamic "cpu_utilization" {
      for_each = var.autoscaling_cpu

      content {
        target = cpu_utilization.value["target"]
      }
    }

    dynamic "metric" {
      for_each = var.autoscaling_metric

      content {
        name   = metric.value["name"]
        target = metric.value["target"]
        type   = metric.value["type"]
      }
    }

    dynamic "load_balancing_utilization" {
      for_each = var.autoscaling_lb

      content {
        target = load_balancing_utilization.value["target"]
      }
    }
  }
}

resource "null_resource" "dummy_dependency" {
  count      = var.module_enabled && var.zonal ? 1 : 0
  depends_on = [google_compute_instance_group_manager.default]
}

resource "null_resource" "region_dummy_dependency" {
  count      = var.module_enabled && ! var.zonal ? 1 : 0
  depends_on = [google_compute_region_instance_group_manager.default]
}

resource "google_compute_health_check" "mig-https-health-check" {
  provider = google-beta
  count    = var.health_check_type == "HTTPS" ? 1 : 0
  name     = var.name
  project  = var.project

  check_interval_sec  = var.hc_interval
  timeout_sec         = var.hc_timeout
  healthy_threshold   = var.hc_healthy_threshold
  unhealthy_threshold = var.hc_unhealthy_threshold

  https_health_check {
    port         = var.hc_port == "" ? var.service_port : var.hc_port
    request_path = var.hc_path
  }
}

resource "google_compute_health_check" "mig-http-health-check" {
  provider = google-beta
  count    = var.health_check_type == "HTTP" ? 1 : 0
  name     = var.name
  project  = var.project

  check_interval_sec  = var.hc_interval
  timeout_sec         = var.hc_timeout
  healthy_threshold   = var.hc_healthy_threshold
  unhealthy_threshold = var.hc_unhealthy_threshold

  http_health_check {
    port         = var.hc_port == "" ? var.service_port : var.hc_port
    request_path = var.hc_path
  }
}

resource "google_compute_firewall" "mig-health-check" {
  count   = var.health_check_type == "" ? 0 : 1
  project = var.subnetwork_project == "" ? var.project : var.subnetwork_project
  name    = "${var.network}-${var.name}-group-hc"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = [var.hc_port == "" ? var.service_port : var.hc_port]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = var.target_tags
}

data "google_compute_instance_group" "zonal" {
  count   = var.zonal ? 1 : 0
  name    = google_compute_instance_group_manager.default[count.index].name
  zone    = var.zone
  project = var.project
}
