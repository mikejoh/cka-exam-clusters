variable "image" {
  default = "ubuntu-os-cloud/ubuntu-1804-lts"
}

variable "disk_size" {
  default = 20
}

variable "machine_type" {
  default = "n1-standard-1"
}

variable "zone" {
  default = "europe-west1-b"
}

variable "region" {
  default = "europe-west1"
}

variable "project" {
  default = "cka-training-sandbox-1"
}

variable "ip_cidr_range" {
  default = "10.240.0.0/24"
}
