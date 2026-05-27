output "public_ip" {
  description = "Public IPv4 address of the Stackonomics VM."
  value       = oci_core_instance.app.public_ip
}

output "app_url" {
  description = "URL where the app will be available once cloud-init finishes (~3-5 min after apply)."
  value       = "http://${oci_core_instance.app.public_ip}"
}

output "ssh_command" {
  description = "Convenience: SSH into the VM as the 'ubuntu' user."
  value       = "ssh ubuntu@${oci_core_instance.app.public_ip}"
}

output "instance_id" {
  description = "OCID of the provisioned instance."
  value       = oci_core_instance.app.id
}

output "post_apply_hint" {
  description = "Reminder of what happens after 'terraform apply' returns."
  value = <<-EOT
    The VM is up, but cloud-init still has to install Docker, clone the repo,
    build the image and start the stack. Give it ~3-5 minutes, then:

      curl -v http://${oci_core_instance.app.public_ip}

    To watch progress:
      ssh ubuntu@${oci_core_instance.app.public_ip} \\
        'sudo tail -f /var/log/cloud-init-output.log'
  EOT
}
