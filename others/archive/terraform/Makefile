TF_DIR=./gcp/compute
CREDENTIALS=./gcp-terraform.json

ifeq ($(wildcard $(CREDENTIALS)),)
$(error Missing credentials file: $(CREDENTIALS))
endif

PROJECT_ID := $(shell jq -r .project_id $(CREDENTIALS))

export GOOGLE_APPLICATION_CREDENTIALS := $(abspath $(CREDENTIALS))
export TF_VAR_project_id := $(PROJECT_ID)

plan:
	terraform -chdir=$(TF_DIR) plan -var="project_id=$(PROJECT_ID)" -out=tfplan

apply:
	terraform -chdir=$(TF_DIR) apply -var="project_id=$(PROJECT_ID)" tfplan

fmt:
	terraform -chdir=$(TF_DIR) fmt -recursive
# TF_DIR=./gcp/compute
# CREDENTIALS=./gcp-terraform.json

# PROJECT_ID := $(shell jq -r .project_id $(CREDENTIALS))

# export GOOGLE_APPLICATION_CREDENTIALS := $(abspath $(CREDENTIALS))
# export TF_VAR_project_id := $(PROJECT_ID)

# plan:
# 	terraform -chdir=$(TF_DIR) plan

# apply:
# 	terraform -chdir=$(TF_DIR) apply

# destroy:
# 	terraform -chdir=$(TF_DIR) destroy