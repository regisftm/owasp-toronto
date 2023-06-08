output "control_plane_public_ip" {
  value = aws_instance.control_plane.public_ip
}

locals {
  worker_public_ips = [for i in aws_instance.worker : i.public_ip]
}

output "workers_public_ips" {
  value = { for i, ip in local.worker_public_ips : "worker-${format("%02d", i + 1)}" => ip }
}
