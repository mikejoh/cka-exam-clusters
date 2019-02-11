# Using terraform to create the CKA training clusters

**Work in progress!**

Instead of running the `create_cluster.sh` script you can use terraform and the related files in the directories here to create the different clusters in GCP.

Within the current structure of the terraform specific files (`.tf`) there's some duplication of config. It leaves some room for optimization.

The `prepare_gcp.sh` creates, enables and configures what you'll need to run some Kubernetes clusters in GCP. _The operations done in this script could be moved to terraform in the end instead._

_Note that this takes care of creating all resources needed, what isn't fixed here are the rest of the steps within the `create_cluster.sh` script. These will be moved or replaced!_

## How-To

1. Install `terraform`
2. Change the `prepare_gcp.sh` script variables, use the project ID in step 3.
3. Change the `project` name within the `vars.tf` file of the directory (cluster) you want to run.
4. Run `prepare_gcp.sh`, you might need to enable the Compute Engine API manually from within the Google Cloud Portal.
5. Now from within one of the directories here, run `terraform`:
```
terraform init
terraform plan
terraform apply
```

## Todo

* Move preparation of GCP enviornment to terraform
* Optimize the creation of resources via terraform, use templates instead. Automate more with outputs.