resource "google_compute_instance" "etcd-0" {
  name         = "etcd-0"
  project      = "${var.project}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  tags         = ["k8s", "etcd-0"]

  boot_disk {
    initialize_params {
      image = "${var.image}"
      size  = "${var.disk_size}"
    }
  }

  network_interface {
    subnetwork    = "${google_compute_subnetwork.k8s-cluster-subnet.self_link}"
    address       = "10.240.0.11"
    access_config = {}
  }

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }
}

resource "google_compute_instance" "master-0" {
  name         = "master-0"
  project      = "${var.project}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  tags         = ["k8s", "master-0"]

  can_ip_forward = true

  boot_disk {
    initialize_params {
      image = "${var.image}"
      size  = "${var.disk_size}"
    }
  }

  network_interface {
    subnetwork    = "${google_compute_subnetwork.k8s-cluster-subnet.self_link}"
    address       = "10.240.0.10"
    access_config = {}
  }

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }
}

resource "google_compute_instance" "worker-0" {
  name         = "worker-0"
  project      = "${var.project}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  tags         = ["k8s", "worker-0"]

  can_ip_forward = true

  metadata {
    pod-cidr = "10.200.0.0/24"
  }

  boot_disk {
    initialize_params {
      image = "${var.image}"
      size  = "${var.disk_size}"
    }
  }

  network_interface {
    subnetwork    = "${google_compute_subnetwork.k8s-cluster-subnet.self_link}"
    address       = "10.240.0.20"
    access_config = {}
  }

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }
}

resource "google_compute_instance" "worker-1" {
  name         = "worker-1"
  project      = "${var.project}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  tags         = ["k8s", "worker-1"]

  can_ip_forward = true

  metadata {
    pod-cidr = "10.200.1.0/24"
  }

  boot_disk {
    initialize_params {
      image = "${var.image}"
      size  = "${var.disk_size}"
    }
  }

  network_interface {
    subnetwork    = "${google_compute_subnetwork.k8s-cluster-subnet.self_link}"
    address       = "10.240.0.21"
    access_config = {}
  }

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }
}
