resource "google_compute_firewall" "k8s-cluster-allow-internal" {
  name    = "k8s-cluster-allow-internal"
  network = "${google_compute_network.k8s-cluster-network.self_link}"

  source_ranges = ["10.240.0.0/24", "10.200.0.0/16"]

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "k8s-cluster-allow-external" {
  name    = "k8s-cluster-allow-external"
  network = "${google_compute_network.k8s-cluster-network.self_link}"

  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22", "6443"]
  }

  allow {
    protocol = "icmp"
  }
}
