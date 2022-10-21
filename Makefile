ACCOUNT_ID := $(shell eai account get --fields id --no-header)
ACCOUNT_NAME := $(shell eai account get --field name --no-header)
USER_ID := $(shell id -u ${USER})

GIT_HEAD_REF := $(shell git rev-parse HEAD)
REGISTRY_ACCOUNT_NAME := snow.code_llm

IMAGE_NAME := registry.console.elementai.com/$(REGISTRY_ACCOUNT_NAME)/bigcode_eval_harness

REPO_TOOLKIT_WORKDIR_STORAGE_NAME := text2code_dataset_repo_workdir

.PHONY: build-image
build-image:
	DOCKER_BUILDKIT=1 docker build  -f ./Dockerfile -t $(IMAGE_NAME):$(GIT_HEAD_REF) .

.PHONY: push-image
push-image:
	docker push $(IMAGE_NAME):$(GIT_HEAD_REF)

.PHONY: run
run : build-image push-image
	eai job new \
		--mem 256 --cpu 32 \
		--preemptable \
		--restartable \
		--account $(ACCOUNT_ID) \
		--image $(IMAGE_NAME):$(GIT_HEAD_REF) \
		--data snow.$(ACCOUNT_NAME).$(REPO_TOOLKIT_WORKDIR_STORAGE_NAME):/repo_workdir:rw \
		$(MORE_JOB_ARGS) \
		-- bash -c "/beh/run.sh"
#		-- bash -c "while true; do sleep 3600; done"


	eai job logs -f

