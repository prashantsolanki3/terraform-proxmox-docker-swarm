variable "PM_API_TOKEN_ID" {
  description = "PM_API_TOKEN_ID"
  type        = string
}

variable "PM_API_TOKEN_SECRET" {
  description = "PM_API_TOKEN_SECRET"
  type        = string
}

variable "PROXMOX_IP" {
  description = "PROXMOX_IP"
  type        = string
}

variable "TARGET_NODES" {
  description = "TARGET_NODES"
  type        = list(string)
}

variable "public_key_file" {
  description = "public_key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "private_key_file" {
  description = "private_key_file"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "template" {
  description = "Template Name"
  type        = string
  default     = "U2004-DOCKER-TEMPLATE"
}

variable "admin_password" {
  description = "admin Password"
  type        = string
}

variable "admin_user" {
  description = "admin Username"
  type        = string
}

variable "docker_manager_count" {
  description = "docker_manager_count"
  type        = number
  default     = 3
}

variable "docker_worker_count" {
  description = "docker_worker_count"
  type        = number
  default     = 4
}

variable "docker_manager_cpu_count" {
  description = "docker_manager_cpu_count"
  type        = number
  default     = 4
}

variable "docker_worker_cpu_count" {
  description = "docker_worker_cpu_count"
  type        = number
  default     = 4
}

variable "docker_manager_memory" {
  description = "docker manager memory"
  type        = number
  default     = 4096
}

variable "docker_worker_memory" {
  description = "docker worker memory"
  type        = number
  default     = 8192
}

variable "docker_manager_hostname" {
  description = "docker manager hostname - Note: vm count would be added to the hostname. eg: tf-u2004-docker-manager1, tf-u2004-docker-manager2, etc."
  type        = string
  default     = "tf-u2004-docker-manager"
}

variable "docker_worker_hostname" {
  description = "docker worker hostname - Note: vm count would be added to the hostname. eg: tf-u2004-docker-worker1, tf-u2004-docker-worker2, etc."
  type        = string
  default     = "tf-u2004-docker-worker"
}

variable "ipv4_gateway" {
  description = "Default Gateway"
  type        = string
}

variable "docker_manager_ipv4_range" {
  description = "The ipv4 range docker managers should be created in. e.g. if range=10.2.1.10 and docker_manager_range_offset=2 the resultant VM would have a IPs in the range of 10.2.1.102-10.2.1.109"
  type        = string
  default     = "10.2.21.12"
}

variable "docker_manager_data_ipv4_range" {
  description = "The ipv4 range docker managers should be created in. e.g. if range=10.2.1.10 and docker_manager_range_offset=2 the resultant VM would have a IPs in the range of 10.2.1.102-10.2.1.109"
  type        = string
  default     = "10.2.21.12"
}

variable "docker_worker_data_ipv4_range" {
  description = "The ipv4 range docker workers should be created in. e.g. if range=10.2.1.10 and docker_manager_range_offset=2 the resultant VM would have a IPs in the range of 10.2.1.102-10.2.1.109"
  type        = string
  default     = "10.2.21.12"
}

variable "docker_worker_ipv4_range" {
  description = "The ipv4 range docker workers should be created in. e.g. if range=10.2.1.10 and docker_worker_range_offset=2 the resultant VM would have a IPs in the range of 10.2.1.102-10.2.1.109"
  type        = string
  default     = "10.2.21.12"
}

variable "docker_manager_range_offset" {
  description = "The offset appended to the ipv4 range. e.g. if range=10.2.1.10 and docker_manager_range_offset=2 the resultant VM would have a IPs in the range of 10.2.1.102-10.2.1.109"
  type        = number
  default     = 0
}

variable "docker_worker_range_offset" {
  description = "The offset appended to the ipv4 range. e.g. if range=10.2.1.10 and docker_worker_range_offset=2 the resultant VM would have a IPs in the range of 10.2.1.102-10.2.1.109"
  type        = number
  default     = 5
}

variable "docker_worker_disk_size" {
  description = "Disk size of docker workers"
  type        = string
  default     = "64G"
}

variable "docker_manager_disk_size" {
  description = "Disk size of docker workers"
  type        = string
  default     = "64G"
}

variable "docker_manager_disk_storage" {
  description = "storage location of docker manager disk"
  type        = string
  default     = "local-lvm"
}

variable "docker_worker_disk_storage" {
  description = "storage location of docker worker disk"
  type        = string
  default     = "local-lvm"
}

variable "test_only" {
  description = "Enable to only create a test-vm"
  type        = bool
  default     = false
}
