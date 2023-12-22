# Deployment automation for GCP

## Requirements

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- Gzip
- jmespath Python package

```shell
pip install jmespath
```

## Usage

Set the following variables in the [Makefile](Makefile):
- `DOCKER_IMAGES_PREFIX`: Prefix of the images that will be copied to the VMs. 
All images that are not in a public registry (e.g. Docker Hub) need to be included
- `GIT_REPO`: Repository to be cloned in the VMs
- `REPO_DEST`: Path where the repository will be cloned
- `GIT_BRANCH`: Branch of the repository to use
- `BUILD_CMD`: Command that will be executed inside `REPO_DEST` to build the images
- `DEPLOY_COMMAND`: Command that will be executed inside `REPO_DEST` to deploy the stack\

If you need to copy extra files to the VMs, put them in `.common/{REPO_DEST | basename}`.
For example, if you need to copy the file `foo.txt` to `/home/ubuntu/grid_search_scala/bar/foo.txt`,
put it in `.common/grid_search_scala/bar/foo.txt`.

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

### Importing Dashboards to Grafana

While the system is running, run

```shell
$ make configure_grafana
```

**For this to work, Grafana must be running in the manager node** (first node in the list of VMs).

## Tunneling

```shell
$ make tunnel_X
```

Where `X` is the port to be tunneled. For example, to access Grafana, run.

**For this to work, the service must be running in the manager node** (first node in the list of VMs).


