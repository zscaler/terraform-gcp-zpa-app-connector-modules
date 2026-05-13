################################################################################
# Create App Connector Instance Template (used by the autoscaling MIG)
################################################################################
resource "google_compute_instance_template" "ac_instance_template" {
  name_prefix = "${var.name_prefix}-ac-asg-template-${var.resource_tag}-"
  project     = var.project
  region      = var.region

  machine_type   = var.acvm_instance_type
  can_ip_forward = false

  disk {
    source_image = var.image_name
    auto_delete  = true
    boot         = true
    disk_type    = "pd-balanced"
    disk_size_gb = var.disk_size
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  network_interface {
    subnetwork = var.acvm_vpc_subnetwork
  }

  metadata = {
    ssh-keys                = "admin:${var.ssh_key}"
    enable-guest-attributes = "TRUE"
  }

  metadata_startup_script = var.user_data

  lifecycle {
    create_before_destroy = true
  }
}


################################################################################
# Create per-zone Managed Instance Groups. The MIGs are sized dynamically by the
# autoscaler resource below: target_size is intentionally left unset so the
# autoscaler is the sole authority on group size.
################################################################################
resource "google_compute_instance_group_manager" "ac_instance_group_manager" {
  count   = length(var.zones)
  name    = "${var.name_prefix}-ac-asg-${count.index + 1}-${var.resource_tag}"
  project = var.project
  zone    = element(var.zones, count.index)

  base_instance_name = "${var.name_prefix}-ac-asg-${count.index + 1}-acvm-${var.resource_tag}"

  version {
    instance_template = google_compute_instance_template.ac_instance_template.id
  }

  # GCP MIG health check grace period for new instances. Mirrors AWS
  # health_check_grace_period semantics so behaviour matches across clouds.
  auto_healing_policies {
    health_check      = google_compute_health_check.ac_asg_health_check.id
    initial_delay_sec = var.health_check_grace_period
  }

  update_policy {
    type                           = var.update_policy_type
    minimal_action                 = "REPLACE"
    most_disruptive_allowed_action = "REPLACE"
    max_surge_fixed                = var.update_policy_max_surge_fixed
    max_unavailable_fixed          = var.update_max_unavailable_fixed
    replacement_method             = var.update_policy_replacement_method
  }

  lifecycle {
    create_before_destroy = true
    # Once the autoscaler attaches, target_size is owned by it. Ignoring drift
    # here prevents Terraform from fighting the autoscaler on every plan.
    ignore_changes = [target_size]
  }
}


################################################################################
# Health check used for MIG auto-healing. The App Connector listens on no
# externally-routable port (it dials out to the Zscaler cloud), so we use a
# basic TCP check on the SSH port. It is intentionally generic; users that want
# tighter health semantics should override health_check_grace_period.
################################################################################
resource "google_compute_health_check" "ac_asg_health_check" {
  name    = "${var.name_prefix}-ac-asg-hc-${var.resource_tag}"
  project = var.project

  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3

  tcp_health_check {
    port = 22
  }
}


################################################################################
# Create the autoscaler. Exactly one of three target-tracking signals is wired
# in based on var.target_tracking_metric, mirroring the AWS module surface
# (ASGAverageCPUUtilization | ASGAverageNetworkIn | ASGAverageNetworkOut).
#
# Encoding notes:
# - CPU      -> native GCP `cpu_utilization` block. GCP wants a 0.0-1.0 fraction
#               so var.target_cpu_util_value (a percentage 1-100) is divided
#               by 100 here. This is the AWS default and the recommended signal.
# - NetworkIn / NetworkOut -> Cloud Monitoring metric (DELTA_PER_SECOND) using
#               the standard GCE compute.googleapis.com instance/network
#               counters. Target is interpreted as bytes/sec per instance.
################################################################################
resource "google_compute_autoscaler" "ac_asg" {
  count   = length(google_compute_instance_group_manager.ac_instance_group_manager[*].instance_group)
  name    = "${var.name_prefix}-ac-asg-policy-${count.index + 1}-${var.resource_tag}"
  project = var.project
  zone    = element(var.zones, count.index)
  target  = element(google_compute_instance_group_manager.ac_instance_group_manager[*].id, count.index)

  autoscaling_policy {
    max_replicas    = var.max_size
    min_replicas    = var.min_size
    cooldown_period = var.cooldown_period

    dynamic "cpu_utilization" {
      for_each = var.target_tracking_metric == "ASGAverageCPUUtilization" ? [1] : []
      content {
        target = var.target_cpu_util_value / 100
      }
    }

    dynamic "metric" {
      for_each = var.target_tracking_metric == "ASGAverageNetworkIn" ? [1] : []
      content {
        name   = "compute.googleapis.com/instance/network/received_bytes_count"
        target = var.target_cpu_util_value
        type   = "DELTA_PER_SECOND"
      }
    }

    dynamic "metric" {
      for_each = var.target_tracking_metric == "ASGAverageNetworkOut" ? [1] : []
      content {
        name   = "compute.googleapis.com/instance/network/sent_bytes_count"
        target = var.target_cpu_util_value
        type   = "DELTA_PER_SECOND"
      }
    }
  }
}


################################################################################
# Wait for MIG creation so downstream callers can read instance group details.
################################################################################
resource "time_sleep" "wait_60_seconds" {
  depends_on      = [google_compute_instance_group_manager.ac_instance_group_manager]
  create_duration = "60s"
}

data "google_compute_instance_group" "ac_instance_groups" {
  count     = length(google_compute_instance_group_manager.ac_instance_group_manager[*].instance_group)
  self_link = element(google_compute_instance_group_manager.ac_instance_group_manager[*].instance_group, count.index)

  depends_on = [
    time_sleep.wait_60_seconds
  ]
}
