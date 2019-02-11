output "k8s_external_address" {
  value = "${google_compute_address.k8s-cluster-external.address}"
}
