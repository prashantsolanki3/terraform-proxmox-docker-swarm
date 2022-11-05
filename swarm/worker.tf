# WIP
resource "proxmox_vm_qemu" "docker_worker" {
  count       = var.docker_worker_count
  name        = "${var.docker_worker_hostname}${count.index + 1}"
  target_node = var.TARGET_NODES[count.index % length(var.TARGET_NODES)]
  onboot      = var.run_on_boot
  vmid        = "1900${count.index + 1}"
  clone       = var.template
  agent       = 1
  os_type     = "cloud-init"
  cores       = var.docker_worker_cpu_count
  sockets     = 1
  cpu         = "host"
  memory      = var.docker_worker_memory
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  disk {
    slot     = 0
    size     = var.docker_worker_disk_size
    type     = "scsi"
    storage  = var.docker_worker_disk_storage
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
  }


  # This helps to wait and test connection before executing local commands.
  provisioner "remote-exec" {
    inline = [
      "date",
      "sleep 20"
    ]
  }

  # Copy run-as-sudo.sh
  provisioner "local-exec" {
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./scripts/run-as-sudo.sh ${var.admin_user}@${var.docker_worker_ipv4_range}${count.index + var.docker_worker_range_offset}:/tmp/run-as-sudo.sh"
  }

  # Copy firstboot.sh 
  provisioner "local-exec" {
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./scripts/firstboot.sh ${var.admin_user}@${var.docker_worker_ipv4_range}${count.index + var.docker_worker_range_offset}:/tmp/firstboot.sh"
  }

  # Copy .env 
  provisioner "local-exec" {
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./.env ${var.admin_user}@${var.docker_worker_ipv4_range}${count.index + var.docker_worker_range_offset}:/tmp/.env"
  }

  # Copy cleanup.sh
  provisioner "local-exec" {
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./scripts/cleanup.sh ${var.admin_user}@${var.docker_worker_ipv4_range}${count.index + var.docker_worker_range_offset}:/tmp/cleanup.sh"
  }

  # CHMOD firstboot.sh and execute
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/firstboot.sh",
      "chmod +x /tmp/run-as-sudo.sh",
      "chmod +x /tmp/cleanup.sh",
      "/tmp/run-as-sudo.sh /tmp/firstboot.sh",
      # "rm -f ~/docker-swarm-worker-join-token"
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
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./tokens/.docker-swarm-worker-join-token ${var.admin_user}@${var.docker_worker_ipv4_range}${count.index + var.docker_worker_range_offset}:/tmp/docker-swarm-worker-join-token"
  }




  # Join Docker Swarm
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/docker-swarm-worker-join-token",
      "/tmp/docker-swarm-worker-join-token"
    ]
  }

  depends_on = [
    proxmox_vm_qemu.docker_manager
  ]


}
