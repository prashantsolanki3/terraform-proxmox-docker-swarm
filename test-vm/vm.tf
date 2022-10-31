resource "proxmox_vm_qemu" "test_vm" {
  name        = "test-vm"
  target_node = var.TARGET_NODES[0]
  vmid        = "9999"
  clone       = var.template
  agent       = 1
  os_type     = "cloud-init"
  cores       = 2
  sockets     = 1
  cpu         = "host"
  memory      = 4096
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  disk {
    slot     = 0
    size     = "8G"
    type     = "scsi"
    storage  = var.test_vm_disk_storage
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

  ipconfig0 = "ip=${var.test_vm_ip}/24,gw=${var.ipv4_gateway}"
  ipconfig1 = "ip=${var.test_vm_ip2}/24"

  sshkeys = <<EOF
  ${file(var.public_key_file)}
  EOF

  connection {
    type        = "ssh"
    user        = var.admin_user
    password    = var.admin_password
    private_key = file(var.private_key_file)
    host        = var.test_vm_ip
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
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./run-as-sudo.sh ${var.admin_user}@${var.test_vm_ip}:~/run-as-sudo.sh"
  }

  # Copy firstboot.sh 
  provisioner "local-exec" {
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./firstboot.sh ${var.admin_user}@${var.test_vm_ip}:~/firstboot.sh"
  }

  # Copy .env 
  provisioner "local-exec" {
    command = "rsync -e 'ssh -o stricthostkeychecking=no' ./.env ${var.admin_user}@${var.test_vm_ip}:~/.env"
  }

  # CHMOD firstboot.sh and execute
  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/firstboot.sh",
      "chmod +x ~/run-as-sudo.sh",
      "~/run-as-sudo.sh 2>&1 | tee  run-as-sudo.output"
    ]
  }

  # Do not remove the "," after the ip address.
  # provisioner "local-exec" {
  #   command = "ansible-playbook -i ${var.docker_manager_ipv4_range}${count.index + var.docker_manager_range_offset}, ./ansible/playbook.yml -u ${var.admin_user}"
  # }

  # Remove Existing ssh fingerprint
  provisioner "local-exec" {
    command = "ssh-keygen -f ~/.ssh/known_hosts -R \"${var.test_vm_ip}\""
  }

}
