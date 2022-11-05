resource "proxmox_vm_qemu" "docker_manager" {
  count       = var.docker_manager_count
  name        = "${var.docker_manager_hostname}${count.index + 1}"
  target_node = var.TARGET_NODES[count.index % length(var.TARGET_NODES)]
  onboot      = var.run_on_boot

  vmid     = "1800${count.index + 1}"
  clone    = var.template
  agent    = 1
  os_type  = "cloud-init"
  cores    = var.docker_manager_cpu_count
  sockets  = 1
  cpu      = "host"
  memory   = var.docker_manager_memory
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    slot     = 0
    size     = var.docker_manager_disk_size
    type     = "scsi"
    storage  = var.docker_manager_disk_storage
    iothread = 1
  }

  # SSD for transcoding
  disk {
    slot     = 1
    size     = count.index == 0 ? var.docker_manager_disk_size_secondary : "1G"
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

  ipconfig0 = "ip=${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}/24,gw=${var.ipv4_gateway}"
  ipconfig1 = "ip=${var.docker_manager_data_ipv4_range}${count.index + var.docker_manager_range_offset}/24"

  sshkeys = <<EOF
  ${file(var.public_key_file)}
  EOF

  connection {
    type        = "ssh"
    user        = var.admin_user
    password    = var.admin_password
    private_key = file(var.private_key_file)
    host        = "${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}"
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
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./scripts/run-as-sudo.sh ${var.admin_user}@${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}:/tmp/run-as-sudo.sh"
  }

  # Copy firstboot.sh 
  provisioner "local-exec" {
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./scripts/firstboot.sh ${var.admin_user}@${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}:/tmp/firstboot.sh"
  }

  # Copy nvidia-driver-install.sh 
  provisioner "local-exec" {
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./scripts/nvidia-driver-install.sh ${var.admin_user}@${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}:/tmp/nvidia-driver-install.sh"
  }

  # Copy .env 
  provisioner "local-exec" {
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./.env ${var.admin_user}@${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}:/tmp/.env"
  }

  # Copy plex-install.sh
  provisioner "local-exec" {
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./scripts/plex-install.sh ${var.admin_user}@${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}:/tmp/plex-install.sh"
  }

  # Copy cleanup.sh
  provisioner "local-exec" {
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./scripts/cleanup.sh ${var.admin_user}@${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}:/tmp/cleanup.sh"
  }

  # CHMOD firstboot.sh and execute
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/firstboot.sh",
      "chmod +x /tmp/run-as-sudo.sh",
      "chmod +x /tmp/nvidia-driver-install.sh",
      "chmod +x /tmp/plex-install.sh",
      "chmod +x /tmp/cleanup.sh",
      "/tmp/run-as-sudo.sh /tmp/firstboot.sh"
    ]
  }


  # Do not remove the "," after the ip address.
  # provisioner "local-exec" {
  #   command = "ansible-playbook -i ${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}, ./ansible/playbook.yml -u ${var.admin_user}"
  # }


  # Run on the Manager 1
  # Init Docker Swarm
  provisioner "remote-exec" {
    inline = var.docker_manager_count - count.index == var.docker_manager_count ? [
      "docker swarm init --advertise-addr ${var.docker_manager_data_ipv4_range}${count.index + var.docker_manager_range_offset} >> /tmp/.temp-worker",
      "grep '\\-\\-token' /tmp/.temp-worker  > /tmp/docker-swarm-worker-join-token"
    ] : ["echo \"Swarm Not Initialized\""]
  }

  # Copy the worker join command.
  provisioner "local-exec" {
    command = var.docker_manager_count - count.index == var.docker_manager_count ? "rsync -e 'ssh -o stricthostkeychecking=no' ${var.admin_user}@${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}:/tmp/docker-swarm-worker-join-token ./tokens/.docker-swarm-worker-join-token" : "echo \"Not Copied\""
  }

  # Run on Manager 1, if count > 1.
  provisioner "remote-exec" {
    inline = var.docker_manager_count - count.index == var.docker_manager_count ? [
      "docker swarm join-token manager >> /tmp/.temp-manager",
      "grep '\\-\\-token' /tmp/.temp-manager  > /tmp/docker-swarm-manager-join-token",
    ] : ["echo \"count: ${var.docker_manager_count}\""]
  }

  # Copy Manager Join Token to host, from manager 1
  provisioner "local-exec" {
    command = var.docker_manager_count - count.index == var.docker_manager_count ? "rsync -e 'ssh -o stricthostkeychecking=no' ${var.admin_user}@${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}:/tmp/docker-swarm-manager-join-token ./tokens/.docker-swarm-manager-join-token" : "echo \"Not Copied\""
  }


  provisioner "remote-exec" {
    inline = var.docker_manager_count - count.index < var.docker_manager_count ? ["sleep 10s"] : ["echo \"Docker Swarm Master: I'll sleep when I'm dead.\""]
  }

  # Remove Existing ssh fingerprint
  provisioner "local-exec" {
    command = "ssh-keygen -f ~/.ssh/known_hosts -R \"${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}\""
  }

  # Copy Manager Join token from host to VM on manager2+.
  provisioner "local-exec" {
    command = var.docker_manager_count - count.index < var.docker_manager_count ? "rsync -e 'ssh -o stricthostkeychecking=no' ./tokens/.docker-swarm-manager-join-token ${var.admin_user}@${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}:/tmp/docker-swarm-manager-join-token" : "echo \"Copy Manager Join token from host to VM on VM1+\""
  }

  provisioner "remote-exec" {
    inline = count.index == 0 ? [
      "echo \"Copied Join Tokens\""
    ] : ["sleep 20"]
  }

  # Join Docker Swarm

  provisioner "remote-exec" {
    inline = var.docker_manager_count - count.index < var.docker_manager_count ? [
      "chmod +x /tmp/docker-swarm-manager-join-token",
      "/tmp/docker-swarm-manager-join-token"
    ] : ["echo \"count: ${var.docker_manager_count}\""]
  }

  # Install NVIDIA DRIVERS on Manager-1
  provisioner "remote-exec" {
    inline = count.index == 0 ? [
      "/tmp/run-as-sudo.sh /tmp/nvidia-driver-install.sh",
      "echo \"Nvidia Drivers Installed\""
    ] : ["echo \"Nvidia Drivers Not Installed\""]
  }

  # Install Plex Server on Manager-1
  provisioner "remote-exec" {
    inline = count.index == 0 ? [
      "/tmp/run-as-sudo.sh /tmp/plex-install.sh",
      "echo \"Plex Server Installed\""
    ] : ["echo \"Plex Server Not Installed\""]
  }

}
