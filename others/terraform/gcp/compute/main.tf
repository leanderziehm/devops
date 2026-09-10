terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.17.0"
    }
  }
}

####################
# Free Tier Regions
####################
# availability zone a, b
locals {
  free_tier_regions = {
    us-east1 = {
      region = "us-east1"
      zone   = "us-east1-b"
      label  = "South Carolina"
    }
    us-central1 = {
      region = "us-central1"
      zone   = "us-central1-a"
      label  = "Iowa"
    }
    us-west1 = {
      region = "us-west1"
      zone   = "us-west1-a"
      label  = "Oregon"
    }
  }

  total_free_disk_gb = 30
  min_disk_per_vm   = 10

  disk_per_instance = floor(local.total_free_disk_gb / var.instance_count)
}




variable "active_region" {
  type    = string
  default = "us-east1"

  validation {
    condition     = contains(keys(local.free_tier_regions), var.active_region)
    error_message = "Region must be one of the Compute Engine Free Tier regions."
  }
}

variable "instance_count" {
  type    = number
  default = 1

  validation {
    condition     = var.instance_count >= 1
    error_message = "instance_count must be at least 1."
  }

  validation {
    condition     = floor(local.total_free_disk_gb / var.instance_count) >= local.min_disk_per_vm
    error_message = "Too many instances: disk per VM ${floor(local.total_free_disk_gb / var.instance_count)} GB would drop below ${local.min_disk_per_vm} GB and exceed Free Tier disk limits."
  }
}

####################
# Variables
####################

variable "project_id" {
  type = string
}


####################
# Provider
####################

provider "google" {
  project = var.project_id
  # region  = local.free_tier_regions[var.active_region].region
  # zone    = local.free_tier_regions[var.active_region].zone
}


# Enable the IAM API
resource "google_project_service" "iam" {
  # project = "908254196485"
  service = "iam.googleapis.com"
  # optional: prevent Terraform from deleting the service if you destroy resources
  disable_on_destroy = false
}

resource "google_service_account" "my-sa-resource-name" {
  account_id = "my-sa-resource-name-id"
  display_name = "Custom Service Account for VM Instance :)"
    depends_on = [google_project_service.iam]
  
}


####################
# Compute Instances
####################
# Question how do I find other images names
resource "google_compute_instance" "e2_micro" {
  count        = var.instance_count
  name         = "free-tier-${var.active_region}-${count.index}"
  machine_type = "e2-micro"
  zone         = local.free_tier_regions[var.active_region].zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-13"
      size  = local.disk_per_instance
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  scheduling {
    preemptible       = false
    automatic_restart = true
  }

  metadata = {
    ssh-keys = "ssh-key-from-my-admin:${file("~/.ssh/id_ed25519.pub")} ssh" # this needs to be filled
  }

  tags = ["ssh"]
 
  service_account {
    email = google_service_account.my-sa-resource-name.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_firewall" "ssh-firewall-access" {
  name = "ssh-access"
  network = "default"
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  target_tags = [ "ssh" ]
  source_ranges = ["0.0.0.0/0"]
  
}

####################
# Output
####################

output "disk_allocation" {
  value = {
    total_disk_gb     = local.total_free_disk_gb
    instance_count    = var.instance_count
    disk_per_instance = local.disk_per_instance
  }
}

output "instance_ips" {
  value = google_compute_instance.e2_micro[*].network_interface[0].access_config[0].nat_ip
}