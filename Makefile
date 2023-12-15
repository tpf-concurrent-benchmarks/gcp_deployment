SSH_OPTIONS := -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
SSH_KEY_PATH := ./key.pem

# Images with this prefix will be saved and uploaded to the VMs
# This is useful for images that are built locally and not in a registry
DOCKER_IMAGES_PREFIX := grid_search_scala_

# Git repository that will be cloned on the VMs
GIT_REPO := git@github.com:tpf-concurrent-benchmarks/grid_search_scala.git
REPO_DEST := /home/ubuntu/grid_search_scala
GIT_BRANCH := master

# The command that will be run on the manager node to deploy the stack
DEPLOY_COMMAND := make deploy_cloud

# Get a list of local docker images that start with the variable DOCKER_IMAGES_PREFIX, that are not from a external registry, and that are tagged as latest
DOCKER_IMAGES := $(shell docker images --format '{{.Repository}}:{{.Tag}}' | grep $(DOCKER_IMAGES_PREFIX) | grep latest | grep -v -E '^([^/]+)/' | sort)

init:
	gcloud auth login
	terraform -chdir=terraform init
	./get_keys.sh
	ansible-galaxy collection install community.docker
.PHONY: init

define ssh_to_vm
	bastion_ip=$$(cat ansible/bastion_ip) && \
	vm_ip=$$(cat ansible/hosts | grep -A $(1) "\[vms\]" | tail -n 1) && \
	ssh $(SSH_OPTIONS) \
		-o ProxyCommand="ssh $(SSH_OPTIONS) -i $(SSH_KEY_PATH) -W %h:%p ubuntu@$$bastion_ip" \
		-i $(SSH_KEY_PATH) ubuntu@$$vm_ip
endef

define ssh_tunnel_to_vm
	bastion_ip=$$(cat ansible/bastion_ip) && \
	manager_ip=$$(cat ansible/hosts | grep -A 1 "\[vms\]" | tail -n 1) && \
	ssh -L $(1):$$manager_ip:$(1) $(SSH_OPTIONS) \
		-i ./key.pem -o ProxyCommand="ssh $(SSH_OPTIONS) -i ./key.pem -W %h:%p ubuntu@$$bastion_ip" \
		ubuntu@$$manager_ip
endef

_save_docker_images:
	$(foreach image,$(DOCKER_IMAGES),docker save $(image) | gzip > ./.docker_images/$(image).tar.gz;)
.PHONY: _save_docker_images

setup:
	terraform -chdir=terraform apply
	ansible/get_bastion_ip.sh
	ansible/update_inventory.sh
	ansible/setup.sh
	ansible/init_swarm.sh
	ansible/deploy.sh $(GIT_REPO) $(REPO_DEST) $(GIT_BRANCH)
	make _save_docker_images
	ansible/upload_images.sh
.PHONY: setup

deploy:
	bastion_ip=$$(cat ansible/bastion_ip) && \
	manager_ip=$$(cat ansible/hosts | grep -A 1 "\[vms\]" | tail -n 1) && \
	ssh $(SSH_OPTIONS) \
		-o ProxyCommand="ssh $(SSH_OPTIONS) -i $(SSH_KEY_PATH) -W %h:%p ubuntu@$$bastion_ip" \
		-i $(SSH_KEY_PATH) ubuntu@$$manager_ip "cd $(REPO_DEST) && $(DEPLOY_COMMAND)"

bash_%:
	$(call ssh_to_vm,$*)
.PHONY: bash_%

tunnel_%:
	$(call ssh_tunnel_to_vm,$*)
.PHONY: tunnel_%