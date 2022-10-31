variable "test_only" {
  description = "Enable to only create a test-vm"
  type        = bool
  default     = false
}

variable "TARGET_NODES" {
  description = "TARGET_NODES"
  type        = list(string)
}


variable "public_key_file" {
  description = "public_key"
  type        = string
}

variable "private_key_file" {
  description = "private_key_file"
  type        = string
}


variable "ipv4_gateway" {
  description = "Default Gateway"
  type        = string
}


variable "test_vm_ip" {
  type = string
}

variable "test_vm_ip2" {
  type = string
}

variable "template" {
  description = "Template Name"
  type        = string
}


variable "test_vm_disk_storage" {
  description = "storage location of docker manager disk"
  type        = string
}

variable "admin_password" {
  description = "admin Password"
  type        = string
}

variable "admin_user" {
  description = "admin Username"
  type        = string
}
