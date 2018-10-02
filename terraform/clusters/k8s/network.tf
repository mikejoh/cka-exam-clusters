resource "google_compute_network" "k8s-cluster-network" {
  name                    = "k8s-cluster-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "k8s-cluster-subnet" {
  name          = "k8s-cluster-subnet"
  region        = "${var.region}"
  ip_cidr_range = "${var.ip_cidr_range}"
  network       = "${google_compute_network.k8s-cluster-network.self_link}"
}

resource "google_compute_address" "k8s-cluster-external" {
  name         = "k8s-cluster-external"
  address_type = "EXTERNAL"
  region       = "${var.region}"
}
