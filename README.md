# Deployment automation for GCP

## Requirements

- [gcloud](https://cloud.google.com/sdk/docs/install)
  - Install: https://cloud.google.com/sdk/docs/install#deb
  - Setup auth: `gcloud auth application-default login`
- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
  - `sudo apt install ansible`
- Gzip

## Usage

Set the following variables in the [Makefile](Makefile):

- `DOCKER_IMAGES_PREFIX`: Prefix of the images that will be copied to the VMs.
  All images that are not in a public registry (e.g. Docker Hub) need to be included
- `GIT_REPO`: Repository to be cloned in the VMs
- `REPO_DEST`: Path where the repository will be cloned
- `GIT_BRANCH`: Branch of the repository to use
- `DEPLOY_COMMAND`: Command that will be executed inside `REPO_DEST` to deploy the stack

Then, run

```shell
$ make init # Only the first time
```

```shell
$ make setup
```

```shell
$ make deploy
```

### Scaling the system

Modify the [variables.tf](terraform/variables.tf) file to increase or decrease the amount
of VMs to deploy
