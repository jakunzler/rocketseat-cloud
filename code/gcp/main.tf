resource "google_compute_instance" "vm_instance" {
  name         = "example-instance"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = <<-EOT
              #!/bin/bash
              echo Hello, World! > /var/log/startup-script.log
            EOT

  tags = ["web", "dev"]
}