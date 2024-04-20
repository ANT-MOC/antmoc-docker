#===============================================================================
# Default User Options
#===============================================================================
UBUNTU_CODE ?= jammy
SPACK_IMAGE  = spack/ubuntu-$(UBUNTU_CODE):0.21.2

BUILD_TYPE   ?= mpi # serial or mpi
DOCKER_IMAGE ?= antmoc/antmoc
DOCKER_TAG   := 0.1.15-mpi

#===============================================================================
# Variables and objects
#===============================================================================

OCI_CREATED=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
OCI_SOURCE=$(shell git config --get remote.origin.url)

# Get the latest commit
GIT_COMMIT = $(strip $(shell git rev-parse --short HEAD))

#===============================================================================
# Targets to Build
#===============================================================================

.PHONY : build push output

default: build
release: build push output

build:
	# Build Docker image
	docker build \
                 --build-arg UBUNTU_CODE=$(UBUNTU_CODE) \
                 --build-arg SPACK_VERSION=$(SPACK_VERSION) \
                 --build-arg SPACK_IMAGE=$(SPACK_IMAGE) \
                 --build-arg BUILD_TYPE=$(BUILD_TYPE) \
                 --build-arg OCI_CREATED=$(OCI_CREATED) \
                 --build-arg OCI_SOURCE=$(OCI_SOURCE) \
                 --build-arg OCI_REVISION=$(GIT_COMMIT) \
                 -t $(DOCKER_IMAGE):$(DOCKER_TAG)-alpha .

	slim build \
                --http-probe=false \
                --show-clogs \
                --include-path /opt/software \
                --include-shell \
                --include-exe-file slim/include-exe.$(BUILD_TYPE) \
                --target $(DOCKER_IMAGE):$(DOCKER_TAG)-alpha \
                --tag $(DOCKER_IMAGE):$(DOCKER_TAG) \
                --exec antmoc

push:
	# Push to DockerHub
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

output:
	@echo Docker Image: $(DOCKER_IMAGE):$(DOCKER_TAG)
