.PHONY: build

CONTAINER_REGISTRY ?= ghcr.io
REPOSITORY=wegel/ostreefy
CONTAINER_TAG ?= $(shell V="$$(git describe --tags --match='[0-9][0-9.]*' --dirty 2>/dev/null)"; if [ "$$V" = "" ]; then git fetch --no-tags --prune origin +refs/heads/main:refs/remotes/origin/main && echo "0.0.0-$$(git rev-list --count origin/main)-$$(git rev-parse --short HEAD)"; else echo "$$V"; fi)

CONTAINER_RUNTIME ?= docker
CONTAINER_BUILD_ARGS ?= --pull
CONTAINER_BUILD_OTHER_ARGS ?=
CONTAINER_BUILD_OUTPUT ?= type=image
CONTAINER_BUILD_COMMAND ?= build

.ONESHELL:

build:
	@for F in flavours/*/; do \
		cd $$F
		IMAGE_NAME="$(CONTAINER_REGISTRY)/$(REPOSITORY)/base/$$(basename $$F):$(CONTAINER_TAG)"
		echo "Building $$IMAGE_NAME"
		docker $(CONTAINER_BUILD_COMMAND) \
			--file Containerfile \
			--tag $$IMAGE_NAME \
			--label build.commit.hash="$(shell git log -1 --format=%H)" \
			--label build.commit.shorthash="$(shell git log -1 --format=%h)" \
			--label build.docker.image.tag="$(CONTAINER_TAG)" \
			--label build.docker.image.name="$(IMAGE_NAME)" \
			--label build.git.repo="$(shell (git remote get-url origin 2>/dev/null || echo local) | sed 's#^https://github.com/##g' | sed 's#^git@github.com:##g' | sed 's#.git##g' )" \
			--label build.docker.image.created_on="$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")" \
			--output=$(CONTAINER_BUILD_OUTPUT) \
			$(CONTAINER_BUILD_ARGS) \
			$(CONTAINER_BUILD_OTHER_ARGS) \
			.
		cd -
	done

release: CONTAINER_BUILD_OUTPUT=type=registry
release: CONTAINER_BUILD_OTHER_ARGS += --push
release: build

get-registry:
	@echo $(CONTAINER_REGISTRY)

get-tag:
	@echo $(CONTAINER_TAG)

get-next-tag:
	@git describe --tags --abbrev=0 | perl -p -e 's/([0-9]+)\.([0-9])+\.([0-9]+)/$$1.".".$$2.".".($$3+1)/pe'