#===============================================================================
# Default User Options
#===============================================================================

# Build-time arguments
UBUNTU_CODE    ?= jammy
SPACK_VERSION  ?= 0.21.2
SPACK_IMAGE     = spack/ubuntu-$(UBUNTU_CODE)

# Target
TARGET ?= x86_64

# Image name
DOCKER_IMAGE ?= antmoc/antmoc
DOCKER_TAG   := dev-alpha

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
                 --build-arg TARGET=$(TARGET) \
                 --build-arg OCI_CREATED=$(OCI_CREATED) \
                 --build-arg OCI_SOURCE=$(OCI_SOURCE) \
                 --build-arg OCI_REVISION=$(GIT_COMMIT) \
                 -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

push:
	# Push to DockerHub
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

output:
	@echo Docker Image: $(DOCKER_IMAGE):$(DOCKER_TAG)
