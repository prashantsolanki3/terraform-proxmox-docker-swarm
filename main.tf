module "docker_swarm" {
  count                          = var.test_only == true ? 0 : 1
  source                         = "./swarm"
  TARGET_NODES                   = var.TARGET_NODES
  public_key_file                = var.public_key_file
  private_key_file               = var.private_key_file
  template                       = var.template
  admin_password                 = var.admin_password
  admin_user                     = var.admin_user
  docker_manager_count           = var.docker_manager_count
  docker_worker_count            = var.docker_worker_count
  docker_manager_cpu_count       = var.docker_manager_cpu_count
  docker_worker_cpu_count        = var.docker_worker_cpu_count
  docker_manager_memory          = var.docker_manager_memory
  docker_worker_memory           = var.docker_worker_memory
  docker_manager_hostname        = var.docker_manager_hostname
  docker_worker_hostname         = var.docker_worker_hostname
  ipv4_gateway                   = var.ipv4_gateway
  docker_manager_ipv4_range      = var.docker_manager_ipv4_range
  docker_manager_data_ipv4_range = var.docker_manager_data_ipv4_range
  docker_worker_data_ipv4_range  = var.docker_worker_data_ipv4_range
  docker_worker_ipv4_range       = var.docker_worker_ipv4_range
  docker_manager_range_offset    = var.docker_manager_range_offset
  docker_worker_range_offset     = var.docker_worker_range_offset
  docker_worker_disk_size        = var.docker_worker_disk_size
  docker_worker_disk_storage     = var.docker_worker_disk_storage
  docker_manager_disk_size       = var.docker_manager_disk_size
  docker_manager_disk_storage    = var.docker_manager_disk_storage
}


module "test_vm" {
  count                = var.test_only == true ? 1 : 0
  source               = "./test-vm"
  ipv4_gateway         = var.ipv4_gateway
  TARGET_NODES         = var.TARGET_NODES
  admin_user           = var.admin_user
  admin_password       = var.admin_password
  template             = var.template
  test_vm_ip2          = "192.168.1.111"
  test_vm_ip           = "172.16.1.111"
  private_key_file     = var.private_key_file
  public_key_file      = var.public_key_file
  test_vm_disk_storage = "local-lvm"
}
