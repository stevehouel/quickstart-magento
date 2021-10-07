SHELL:=/bin/bash
BASE := $(shell /bin/pwd)
.DEFAULT_GOAL := lint
.PHONY: deploy

PROJECT_NAME ?= sample-magento
STAGE_NAME ?= dev
AWS_REGION ?= eu-west-1
S3_ARTIFACT_BUCKET ?= aws-fr-houes-magento-sample-artifact

CFN_PARAMS := ProjectName=$(PROJECT_NAME) \
		StageName=$(STAGE_NAME)

TAGS_PARAMS := Key="project",Value="${PROJECT_NAME}" \
        Key="owner",Value="houes" \
        Key="environment",Value=$(STAGE_NAME)

sync:
	aws s3 sync ./ s3://${S3_ARTIFACT_BUCKET} --delete --exclude "*" --include "templates/*" --include "code/*" --include "scripts/*"

create-stack:
	aws cloudformation create-stack \
		--template-body file://templates/magento-master.template.yaml \
		--stack-name ${PROJECT_NAME}-${STAGE_NAME} \
		--parameter file://config/config.${STAGE_NAME}.json \
		--capabilities CAPABILITY_NAMED_IAM \
		--disable-rollback \
		--region $(AWS_REGION) \
		--tags $(TAGS_PARAMS)

create-change-set:
	aws cloudformation create-change-set \
		--template-body file://templates/magento-master.template.yaml \
		--stack-name ${PROJECT_NAME}-${STAGE_NAME} \
		--parameter file://config/config.${STAGE_NAME}.json \
		--change-set-name ${PROJECT_NAME}-${STAGE_NAME}-changeset \
		--capabilities CAPABILITY_NAMED_IAM \
		--region $(AWS_REGION) \
		--tags $(TAGS_PARAMS)

execute-change-set:
	aws cloudformation execute-change-set \
		--change-set-name ${PROJECT_NAME}-${STAGE_NAME}-changeset \
		--stack-name ${PROJECT_NAME}-${STAGE_NAME}

delete-stack:
	aws cloudformation delete-stack \
        --stack-name $(PROJECT_NAME)-${STAGE_NAME} \
        --region $(AWS_REGION)

release:
	@make package
	@make create-change-set

output:
	aws cloudformation describe-stacks \
		--stack-name ${PROJECT_NAME}-${STAGE_NAME} \
		--query 'Stacks[].Outputs'