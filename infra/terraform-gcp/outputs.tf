output "public_ip" {
  description = "Ephemeral public IPv4 of the Stackonomics VM."
  value       = google_compute_instance.app.network_interface[0].access_config[0].nat_ip
}

output "app_url" {
  description = "URL where the app will be available once cloud-init finishes (~10-15 min after apply)."
  value       = "http://${google_compute_instance.app.network_interface[0].access_config[0].nat_ip}"
}

output "ssh_command" {
  description = "Convenience: SSH into the VM as 'ubuntu'."
  value       = "ssh ubuntu@${google_compute_instance.app.network_interface[0].access_config[0].nat_ip}"
}

output "instance_self_link" {
  description = "Fully-qualified resource path for the GCE instance."
  value       = google_compute_instance.app.self_link
}

output "post_apply_hint" {
  description = "Reminder of what happens after 'terraform apply' returns."
  value = <<-EOT
    The VM is up, but cloud-init still has to install Docker, allocate the
    2 GB swap file, clone the repo, build the image and start the stack.
    On e2-micro this takes roughly 10-15 minutes due to the memory-tight
    build phase. Watch progress with:

      ssh ubuntu@${google_compute_instance.app.network_interface[0].access_config[0].nat_ip} \\
        'sudo tail -f /var/log/cloud-init-output.log'

    Then visit:
      http://${google_compute_instance.app.network_interface[0].access_config[0].nat_ip}
  EOT
}
