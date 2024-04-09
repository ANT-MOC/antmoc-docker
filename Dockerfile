ARG SPACK_VERSION="0.21.2"
ARG SPACK_IMAGE="spack/ubuntu-jammy"
FROM ${SPACK_IMAGE}:${SPACK_VERSION}
ARG UBUNTU_CODE
ENV UBUNTU_CODE=${UBUNTU_CODE:-"jammy"}

LABEL maintainer="An Wang <wangan.cs@gmail.com>"

USER root
WORKDIR /root

#-------------------------------------------------------------------------------
# Install system compilers and libraries
#-------------------------------------------------------------------------------
ADD etc/apt/ /etc/apt/
RUN <<EOF bash # install cmake, openssh, etc.
set -e

# add apt sources
sed -i -e "s/jammy/${UBUNTU_CODE}/g" /etc/apt/sources.list

# install CMake, etc.
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    sudo \
    cmake \
    openssh-server
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

#-------------------------------------------------------------------------------
# Set up spack
#-------------------------------------------------------------------------------
ENV SPACK_ROOT=/opt/spack
ARG CONFIG_DIR=/etc/spack
ARG INSTALL_DIR=/opt/software
ARG REPO_DIR=/opt/repo
ARG ENV_DIR=/opt/spack-env
ARG MIRROR_DIR=/opt/mirror

# copy a self-hosted spack repo to the image
ADD repo/ ${REPO_DIR}/

# hold a local package mirror as needed
ADD mirror/ ${MIRROR_DIR}/

RUN <<EOF bash # create spack directories, add repos and mirrors
set -e
mkdir -p ${CONFIG_DIR}
mkdir -p ${INSTALL_DIR}
mkdir -p ${ENV_DIR}
spack mirror add --scope system local ${MIRROR_DIR}
spack repo add --scope system ${REPO_DIR}
EOF

RUN <<EOF bash # set up compilers and external packages for spack
set -e
spack compiler find --scope system
spack external find --scope system --not-buildable \
    gcc \
    autoconf \
    automake \
    cmake \
    gmake \
    libtool \
    openssh \
    perl \
    python
EOF

#-------------------------------------------------------------------------------
# Install dependencies for antmoc
#-------------------------------------------------------------------------------
# To avoid the default --reuse option of spack 0.21,
# add %clang or %gcc for every MPI spec in spack.yaml.
ADD spack.yaml ${ENV_DIR}/
RUN <<EOF bash # create a spack environment
set -e
cd ${ENV_DIR} && spack env activate .
spack install -j \$(nproc) --fail-fast -ny
spack gc -y && spack clean -a
spack debug report
spack find -v # Check spack and dependency installation
EOF

# Strip all the binaries
RUN find -L "${INSTALL_DIR}" -type f -exec readlink -f '{}' \; | \
  xargs file -i | \
  grep 'charset=binary' | \
  grep 'x-executable\|x-archive\|x-sharedlib' | \
  awk -F: '{print $1}' | \
  xargs strip -s

#-------------------------------------------------------------------------------
# Install antmoc
#-------------------------------------------------------------------------------
ADD ant-moc/ /opt/ant-moc
RUN <<EOF bash # installing antmoc
spack env activate -d ${ENV_DIR}
spack load cmake%gcc antmoc

cp -r /opt/ant-moc ./ant-moc && cd ./ant-moc
PRESET=gcc-serial-release
BUILD_DIR=build/\$PRESET
[ -d \$BUILD_DIR ] && rm -rf \$BUILD_DIR

cmake --preset \$PRESET -DENABLE_TESTS=ON
cmake --build \$BUILD_DIR -j \$(nproc)
ctest --test-dir \$BUILD_DIR --output-on-failure --stop-on-failure
cmake --install \$BUILD_DIR
ldd \$(which antmoc)
antmoc --help
EOF

#-------------------------------------------------------------------------------
# Reset the entrypoint or CMD
#-------------------------------------------------------------------------------
ENTRYPOINT ["/bin/bash", "-l", "-c", "$*", "--"]
CMD ["antmoc"]

#-----------------------------------------------------------------------
# OCI annotations
#-----------------------------------------------------------------------
ARG OCI_CREATED
ARG OCI_REVISION
ARG OCI_SOURCE
LABEL org.opencontainers.image.created=${OCI_CREATED} \
  org.opencontainers.image.source=${OCI_SOURCE} \
  org.opencontainers.image.revision=${OCI_REVISION} \
  org.opencontainers.image.title="ANT-MOC image" \
  org.opencontainers.image.description="ANT-MOC for neutron transport" \
  org.opencontainers.image.url="https://hub.docker.com/r/antmoc/antmoc"
