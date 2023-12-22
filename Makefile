SHELL := /bin/bash
SSH_OPTIONS := -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
SSH_KEY_PATH := ./key.pem

###########################################################################
########## Uncomment depending on the project you want to deploy ##########
### Grid Search in Scala ###
GIT_REPO := git@github.com:tpf-concurrent-benchmarks/grid_search_scala.git
REPO_DEST := /home/ubuntu/grid_search_scala
GIT_BRANCH := master
BUILD_CMD := make build
DEPLOY_COMMAND := make deploy_cloud
###########################################################################
### Grid Search in C++ ###
# GIT_REPO := git@github.com:tpf-concurrent-benchmarks/grid_search_cpp.git
# REPO_DEST := /home/ubuntu/grid_search_cpp
# GIT_BRANCH := main
# BUILD_CMD := make build
# DEPLOY_COMMAND := make deploy_remote
###########################################################################
### Grid Search in Julia ###
# NOTE: Remember to add the following directories to .common/grid_search_julia:
# - .keys: containing the keys manager_rsa and manager_rsa.pub
# - ips (empty)
# The resulting directory structure should be:
# .common/grid_search_julia
# ├── .keys
# │   ├── manager_rsa
# │   └── manager_rsa.pub
# └── ips
# GIT_REPO := git@github.com:tpf-concurrent-benchmarks/grid_search_julia.git
# REPO_DEST := /home/ubuntu/grid_search_julia
# GIT_BRANCH := master
# BUILD_CMD := make build
# DEPLOY_COMMAND := make deploy
###########################################################################
### Grid Search in Go ###
# GIT_REPO := git@github.com:tpf-concurrent-benchmarks/grid_search_go.git
# REPO_DEST := /home/ubuntu/grid_search_go
# GIT_BRANCH := main
# BUILD_CMD := make build
# DEPLOY_COMMAND := make deploy_remote
###########################################################################
### Image Processing in Scala ###
# GIT_REPO := git@github.com:tpf-concurrent-benchmarks/image_processing_scala.git
# REPO_DEST := /home/ubuntu/image_processing_scala
# GIT_BRANCH := master
# BUILD_CMD := make build
# DEPLOY_COMMAND := make deploy_cloud
###########################################################################
### Image Processing in C++ ###
# GIT_REPO := git@github.com:tpf-concurrent-benchmarks/image_processing_cpp.git
# REPO_DEST := /home/ubuntu/image_processing_cpp
# GIT_BRANCH := main
# BUILD_CMD := make build
# DEPLOY_COMMAND := make deploy_remote
###########################################################################
### Image Processing in Julia ###
# NOTE: Remember to add the following directories to .common/image_processing_julia:
# - .keys: containing the keys manager_rsa and manager_rsa.pub
# - ips (empty)
# The resulting directory structure should be:
# .common/image_processing_julia
# ├── .keys
# │   ├── manager_rsa
# │   └── manager_rsa.pub
# └── ips
# GIT_REPO := git@github.com:tpf-concurrent-benchmarks/image_processing_julia.git
# REPO_DEST := /home/ubuntu/image_processing_julia
# GIT_BRANCH := master
# BUILD_CMD := make build
# DEPLOY_COMMAND := make deploy
###########################################################################
### Image Processing in Go ###
# GIT_REPO := git@github.com:tpf-concurrent-benchmarks/image_processing_go.git
# REPO_DEST := /home/ubuntu/image_processing_go
# GIT_BRANCH := main
# BUILD_CMD := make build
# DEPLOY_COMMAND := make deploy_remote
###########################################################################

init:
	gcloud auth login
	mkdir -p .docker_images
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

setup:
	# If you get "unreachable" errors, wait a minute and run again
	mkdir -p .common/$(shell basename ${REPO_DEST})
	# Image processing project requires a filestore to store the images
	if [[ "$(GIT_REPO)" == *"image_processing"* ]]; then \
		terraform -chdir=terraform apply -var="create_filestore=true"; \
	else \
		terraform -chdir=terraform apply; \
	fi

	sleep 10
	ansible/get_bastion_ip.sh
	ansible/update_inventory.sh
	ansible/setup.sh
	ansible/swarm_init.sh
	ansible/get_source.sh "$(GIT_REPO)" "$(REPO_DEST)" "$(GIT_BRANCH)"
	ansible/build_images.sh "$(REPO_DEST)" "$(BUILD_CMD)"
.PHONY: setup

_deploy_with_filestore:
	bastion_ip=$$(cat ansible/bastion_ip) && \
	manager_ip=$$(cat ansible/hosts | grep -A 1 "\[vms\]" | tail -n 1) && \
	ssh $(SSH_OPTIONS) \
		-o ProxyCommand="ssh $(SSH_OPTIONS) -i $(SSH_KEY_PATH) -W %h:%p ubuntu@$$bastion_ip" \
		-i $(SSH_KEY_PATH) ubuntu@$$manager_ip "\
		cd $(REPO_DEST) && \
		NFS_SERVER_IP=$$(terraform -chdir=terraform output filestore_ip) \
		NFS_SERVER_PATH=$$(terraform -chdir=terraform output filestore_share_name) \
		$(DEPLOY_COMMAND)"
.PHONY: _deploy_with_filestore

_deploy_without_filestore:
	bastion_ip=$$(cat ansible/bastion_ip) && \
	manager_ip=$$(cat ansible/hosts | grep -A 1 "\[vms\]" | tail -n 1) && \
	ssh $(SSH_OPTIONS) \
		-o ProxyCommand="ssh $(SSH_OPTIONS) -i $(SSH_KEY_PATH) -W %h:%p ubuntu@$$bastion_ip" \
		-i $(SSH_KEY_PATH) ubuntu@$$manager_ip "cd $(REPO_DEST) && $(DEPLOY_COMMAND)"
.PHONY: _deploy_without_filestore

deploy:
	if [[ "$(GIT_REPO)" == *"image_processing"* ]]; then \
  		make _deploy_with_filestore; \
	else \
		make _deploy_without_filestore; \
	fi
.PHONY: deploy

configure_grafana:
	if [[ "$(GIT_REPO)" == *"grid_search"* ]]; then \
  		echo "Importing Grid Search dashboard"; \
		ansible/configure_grafana.sh "gs_dashboard"; \
	elif [[ "$(GIT_REPO)" == *"image_processing"* ]]; then \
		echo "Importing Image Processing dashboard"; \
		ansible/configure_grafana.sh "ip_dashboard"; \
	else
	  	echo "Unable to determine which dashboard to import"; \
	fi
.PHONY: configure_grafana

bash_%:
	$(call ssh_to_vm,$*)
.PHONY: bash_%

tunnel_%:
	$(call ssh_tunnel_to_vm,$*)
.PHONY: tunnel_%