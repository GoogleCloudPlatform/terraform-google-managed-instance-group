resource "google_compute_instance_template" "default" {
  tags = ["${var.target_tags}"] 
}
