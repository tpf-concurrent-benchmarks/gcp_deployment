SHELL := /bin/bash
SSH_OPTIONS := -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
SSH_KEY_PATH := ./key.pem

# Git repository that will be cloned on the VMs
GIT_REPO := git@github.com:tpf-concurrent-benchmarks/grid_search_scala.git
REPO_DEST := /home/ubuntu/grid_search_scala
GIT_BRANCH := master

# The command that will be run on each VM to build the images
BUILD_CMD := make build

# The command that will be run on the manager node to deploy the stack
DEPLOY_COMMAND := make deploy_jars

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
	terraform -chdir=terraform apply
	sleep 10
	ansible/get_bastion_ip.sh
	ansible/update_inventory.sh
	ansible/setup.sh
	ansible/swarm_init.sh
	ansible/get_source.sh "$(GIT_REPO)" "$(REPO_DEST)" "$(GIT_BRANCH)"
	ansible/build_images.sh "$(REPO_DEST)" "$(BUILD_CMD)"
.PHONY: setup

deploy:
	bastion_ip=$$(cat ansible/bastion_ip) && \
	manager_ip=$$(cat ansible/hosts | grep -A 1 "\[vms\]" | tail -n 1) && \
	ssh $(SSH_OPTIONS) \
		-o ProxyCommand="ssh $(SSH_OPTIONS) -i $(SSH_KEY_PATH) -W %h:%p ubuntu@$$bastion_ip" \
		-i $(SSH_KEY_PATH) ubuntu@$$manager_ip "cd $(REPO_DEST) && $(DEPLOY_COMMAND)"
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