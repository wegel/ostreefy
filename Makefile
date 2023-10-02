.PHONY: build

CONTAINER_REGISTRY ?= public.ecr.aws/q8x0g0l6
BASE_REPOSITORY ?= ostreefy/base
EXAMPLE_REPOSITORY ?= ostreefy/examples
CONTAINER_TAG ?= $(shell V="$$(git describe --tags --match='[0-9][0-9.]*' --dirty 2>/dev/null)"; if [ "$$V" = "" ]; then git fetch --no-tags --prune origin +refs/heads/main:refs/remotes/origin/main && echo "0.0.0-$$(git rev-list --count origin/main)-$$(git rev-parse --short HEAD)"; else echo "$$V"; fi)

CONTAINER_RUNTIME ?= docker
CONTAINER_BUILD_ARGS ?=
CONTAINER_BUILD_COMMAND ?= build
PUSH_CONTAINER ?=

.ONESHELL:

build:
	@for F in flavours/*/; do \
		cd $$F
		IMAGE_NAME="$(CONTAINER_REGISTRY)/$(BASE_REPOSITORY)/$$(basename $$F):$(CONTAINER_TAG)"
		echo "Building $$IMAGE_NAME"
		$(CONTAINER_RUNTIME) $(CONTAINER_BUILD_COMMAND) \
			--file Containerfile \
			--tag $$IMAGE_NAME \
			--label build.commit.hash="$(shell git log -1 --format=%H)" \
			--label build.commit.shorthash="$(shell git log -1 --format=%h)" \
			--label build.docker.image.tag="$(CONTAINER_TAG)" \
			--label build.docker.image.name="$(IMAGE_NAME)" \
			--label build.git.repo="$(shell (git remote get-url origin 2>/dev/null || echo local) | sed 's#^https://github.com/##g' | sed 's#^git@github.com:##g' | sed 's#.git##g' )" \
			--label build.docker.image.created_on="$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")" \
			$(CONTAINER_BUILD_ARGS) \
			.
		if [ -n "$(PUSH_CONTAINER)" ]; then
			$(CONTAINER_RUNTIME) push $$IMAGE_NAME
		fi
		cd -
	done

release: PUSH_CONTAINER = true
release: build

build-examples: build
build-examples:
	@for F in flavours/*/examples/Containerfile.*; do \
		FLAVOUR=$$(echo "$$F" | awk -F'/' '{print $$2}'); \
		EXAMPLE_NAME=$$(echo "$$F" | awk -F'.' '{print $$2}' | cut -d'/' -f5); \
		IMAGE_NAME="$(CONTAINER_REGISTRY)/$(EXAMPLE_REPOSITORY)/$${FLAVOUR}:$${EXAMPLE_NAME}-$(CONTAINER_TAG)"; \
		echo "Building $$IMAGE_NAME"; \
		$(CONTAINER_RUNTIME) $(CONTAINER_BUILD_COMMAND) \
			--file "$${F}" \
			--tag $$IMAGE_NAME \
			--build-arg BASE_IMAGE="$(CONTAINER_REGISTRY)/$(BASE_REPOSITORY)/$${FLAVOUR}:$(CONTAINER_TAG)" \
			--label build.commit.hash="$(shell git log -1 --format=%H)" \
			--label build.commit.shorthash="$(shell git log -1 --format=%h)" \
			--label build.docker.image.tag="$(CONTAINER_TAG)" \
			--label build.docker.image.name="$(IMAGE_NAME)" \
			--label build.git.repo="$(shell (git remote get-url origin 2>/dev/null || echo local) | sed 's#^https://github.com/##g' | sed 's#^git@github.com:##g' | sed 's#.git##g' )" \
			--label build.docker.image.created_on="$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")" \
			$(CONTAINER_BUILD_ARGS) \
			$$(dirname "$${F}")
		if [ -n "$(PUSH_CONTAINER)" ]; then
			$(CONTAINER_RUNTIME) push $$IMAGE_NAME
		fi
	done

release-examples: PUSH_CONTAINER = true
release-examples: build-examples

get-registry:
	@echo $(CONTAINER_REGISTRY)

get-tag:
	@echo $(CONTAINER_TAG)

get-next-tag:
	@git describe --tags --abbrev=0 | perl -p -e 's/([0-9]+)\.([0-9])+\.([0-9]+)/$$1.".".$$2.".".($$3+1)/pe'