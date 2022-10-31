resource "proxmox_vm_qemu" "docker_manager" {
  count       = var.docker_manager_count
  name        = "${var.docker_manager_hostname}${count.index + 1}"
  target_node = var.TARGET_NODES[count.index % length(var.TARGET_NODES)]

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
    size     = count.index == 0 ? var.docker_manager_disk_size : "1G"
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

  # # Install Docker
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
      "sleep 20"
    ]
  }

  # Copy run-as-sudo.sh
  provisioner "local-exec" {
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./run-as-sudo.sh ${var.admin_user}@${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}:~/run-as-sudo.sh"
  }

  # Copy firstboot.sh 
  provisioner "local-exec" {
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./firstboot.sh ${var.admin_user}@${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}:~/firstboot.sh"
  }

  # Copy nvidia-driver-install.sh 
  provisioner "local-exec" {
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./nvidia-driver-install.sh ${var.admin_user}@${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}:~/nvidia-driver-install.sh"
  }

  # Copy .env 
  provisioner "local-exec" {
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./.env ${var.admin_user}@${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}:~/.env"
  }

  # CHMOD firstboot.sh and execute
  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/firstboot.sh",
      "chmod +x ~/run-as-sudo.sh",
      "chmod +x ~/nvidia-driver-install.sh",
      "~/run-as-sudo.sh ~/firstboot.sh 2>&1 | tee  run-as-sudo.output",
      # "rm -f ~/docker-swarm-worker-join-token"
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
      "docker swarm init --advertise-addr ${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset} >> ~/.temp-worker",
      "grep '\\-\\-token' ~/.temp-worker  > docker-swarm-worker-join-token",
      "rm -f ~/.temp-worker",
    ] : ["echo \"Swarm Not Initialized\""]
  }

  # Copy the worker join command.
  provisioner "local-exec" {
    command = var.docker_manager_count - count.index == var.docker_manager_count ? "rsync -e 'ssh -o stricthostkeychecking=no' ${var.admin_user}@${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}:~/docker-swarm-worker-join-token ./.docker-swarm-worker-join-token" : "echo \"Not Copied\""
  }

  # Run on Manager 1, if count > 1.
  provisioner "remote-exec" {
    inline = var.docker_manager_count - count.index == var.docker_manager_count ? [
      "docker swarm join-token manager >> ~/.temp-manager",
      "grep '\\-\\-token' ~/.temp-manager  > docker-swarm-manager-join-token",
      "rm -f ~/.temp-manager",
    ] : ["echo \"count: ${var.docker_manager_count}\""]
  }

  # Copy Manager Join Token to host, from manager 1
  provisioner "local-exec" {
    command = var.docker_manager_count - count.index == var.docker_manager_count ? "rsync -e 'ssh -o stricthostkeychecking=no' ${var.admin_user}@${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}:~/docker-swarm-manager-join-token ./.docker-swarm-manager-join-token" : "echo \"Not Copied\""
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
    command = var.docker_manager_count - count.index < var.docker_manager_count ? "rsync -e 'ssh -o stricthostkeychecking=no' ./.docker-swarm-manager-join-token ${var.admin_user}@${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}:~/docker-swarm-manager-join-token" : "echo \"Copy Manager Join token from host to VM on VM1+\""
  }

  provisioner "remote-exec" {
    inline = count.index == 0 ? [
      "echo \"Copied Join Tokens\""
    ] : ["sleep 20"]
  }

  # Join Docker Swarm

  provisioner "remote-exec" {
    inline = var.docker_manager_count - count.index < var.docker_manager_count ? [
      "chmod +x ~/docker-swarm-manager-join-token",
      "~/docker-swarm-manager-join-token",
      "rm -f ~/docker-swarm-manager-join-token"
      ] : ["echo \"count: ${var.docker_manager_count}\"",
      "rm -f ~/docker-swarm-manager-join-token"
    ]
  }

  # Install NVIDIA DRIVERS on Manager-1
  provisioner "remote-exec" {
    inline = count.index == 0 ? [
      "~/run-as-sudo.sh ~/nvidia-driver-install.sh 2>&1 | tee  sudo-nvidia.output",
      "echo \"Nvidia Drivers Installed\""
    ] : ["echo \"Nvidia Drivers Not Installed\""]
  }

}
