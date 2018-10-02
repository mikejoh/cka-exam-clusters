provider "google" {
  credentials = "${file("~/.config/gcloud/terraform_sa_key.json")}"
  project     = "${var.project}"
  region      = "${var.region}"
  zone        = "${var.zone}"
}
