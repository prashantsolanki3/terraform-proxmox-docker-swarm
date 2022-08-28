resource "proxmox_vm_qemu" "docker_worker" {
  count       = var.docker_worker_count
  name        = "${var.docker_worker_hostname}${count.index + 1}"
  target_node = var.TARGET_NODE

  vmid     = "1900${count.index + 1}"
  clone    = var.template
  agent    = 1
  os_type  = "cloud-init"
  cores    = var.docker_worker_cpu_count
  sockets  = 1
  cpu      = "host"
  memory   = var.docker_worker_memory
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    slot     = 0
    size     = "16G"
    type     = "scsi"
    storage  = "fast"
    iothread = 1
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  network {
    model  = "virtio"
    bridge = "vmbr1"
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  ipconfig0 = "ip=${var.docker_worker_ipv4_range}${count.index + var.docker_worker_range_offset}/24,gw=${var.ipv4_gateway}"
  ipconfig1 = "ip=${var.docker_worker_data_ipv4_range}${count.index + var.docker_worker_range_offset}/24"

  sshkeys = <<EOF
  ${file(var.public_key_file)}
  EOF


  # Remove Existing ssh fingerprint
  provisioner "local-exec" {
    command = "ssh-keygen -f ~/.ssh/known_hosts -R \"${var.docker_worker_ipv4_range}${count.index + var.docker_worker_range_offset}\""
  }

  connection {
    type        = "ssh"
    user        = var.admin_user
    password    = var.admin_password
    private_key = file(var.private_key_file)
    host        = "${var.docker_worker_ipv4_range}${count.index + var.docker_worker_range_offset}"
    insecure    = true
  }

  # Install Docker
  # provisioner "remote-exec" {
  #   inline = [
  #     "curl -fsSL https://get.docker.com -o get-docker.sh",
  #     "sh ./get-docker.sh"
  #   ]
  # }

  # This helps to wait and test connection before executing local commands.
  provisioner "remote-exec" {
    inline = [
      "date",
      "sleep 90",
    ]
  }

  # provisioner "local-exec" {
  #   command = "ansible-playbook -i ${var.docker_worker_ipv4_range}${count.index + var.docker_worker_range_offset}, ansible/playbook.yml -u ${var.admin_user}"
  # }

  # Remove Existing ssh fingerprint
  provisioner "local-exec" {
    command = "ssh-keygen -f ~/.ssh/known_hosts -R \"${var.docker_worker_ipv4_range}${count.index + var.docker_worker_range_offset}\""
  }
  # Copy Docker Swarm CMD 
  provisioner "local-exec" {
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./.docker-swarm-worker-join-token ${var.admin_user}@${var.docker_worker_ipv4_range}${count.index + var.docker_worker_range_offset}:~/docker-swarm-worker-join-token"
  }

  # Join Docker Swarm
  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/docker-swarm-worker-join-token",
      "~/docker-swarm-worker-join-token",
      "rm -f ~/docker-swarm-worker-join-token"
    ]
  }

  depends_on = [
    proxmox_vm_qemu.docker_manager
  ]


}
