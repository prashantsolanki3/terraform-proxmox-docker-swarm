# generate inventory file for Ansible
resource "local_file" "hosts_cfg" {
  depends_on = [module.docker_swarm]

  content = templatefile("${path.module}/templates/hosts.tpl",
    {
      docker_workers  = [for i in range(var.docker_worker_count) : "${var.docker_worker_ipv4_range}${i + var.docker_worker_range_offset}"]
      docker_managers = [for i in range(var.docker_manager_count) : "${var.docker_manager_ipv4_range}${i + var.docker_manager_range_offset}"]
    }
  )
  filename = "./ansible/inventory/hosts.cfg"
}
