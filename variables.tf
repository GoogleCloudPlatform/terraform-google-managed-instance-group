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
 
variable module_enabled {
  description = ""
  default     = true
}

variable project {
  description = "The project to deploy to, if not set the default provider project is used."
  default     = ""
}

variable region {
  description = "Region for cloud resources."
  default     = "us-central1"
}

variable zone {
  description = "Zone for managed instance groups."
  default     = "us-central1-f"
}

variable network {
  description = "Name of the network to deploy instances to."
  default     = "default"
}

variable subnetwork {
  description = "The subnetwork to deploy to"
  default     = "default"
}

variable name {
  description = "Name of the managed instance group."
}

variable size {
  description = "Target size of the manged instance group."
  default     = 1
}

variable startup_script {
  description = "Content of startup-script metadata passed to the instance template."
  default     = ""
}

variable access_config {
  description = "The access config block for the instances. Set to [] to remove external IP."
  type        = "list"
  default     = [{}]
}

variable metadata {
  description = "Map of metadata values to pass to instances."
  type        = "map"
  default     = {}
}

variable can_ip_forward {
  description = "Allow ip forwarding."
  default     = false
}

variable network_ip {
  description = "Set the network IP of the instance in the template. Useful for instance groups of size 1."
  default     = ""
}

variable machine_type {
  description = "Machine type for the VMs in the instance group."
  default     = "f1-micro"
}

variable compute_image {
  description = "Image used for compute VMs."
  default     = "debian-cloud/debian-8"
}

variable service_port {
  description = "Port the service is listening on."
}

variable service_port_name {
  description = "Name of the port the service is listening on."
}

variable target_tags {
  description = "Tag added to instances for firewall and networking."
  type        = "list"
  default     = ["allow-service"]
}

variable target_pools {
  description = "The target load balancing pools to assign this group to."
  type        = "list"
  default     = []
}

variable depends_id {
  description = "The ID of a resource that the instance group depends on."
  default     = ""
}

variable local_cmd_destroy {
  description = "Command to run on destroy as local-exec provisioner for the instance group manager."
  default     = ":"
}
