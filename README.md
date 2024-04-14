ANT-MOC
=======

[![Docker Image Version](https://img.shields.io/docker/v/antmoc/antmoc)](https://hub.docker.com/r/antmoc/antmoc/tags)
![Docker Image Size](https://img.shields.io/docker/image-size/antmoc/antmoc)
![Docker Pulls](https://img.shields.io/docker/pulls/antmoc/antmoc?color=informational)
![Automated Build](https://img.shields.io/docker/automated/antmoc/antmoc)

Official ANT-MOC images.

## How to use

> Note:
> - replace `<tag>` below with an available image tag
> - replace `<args>` below with ANT-MOC CLI arguments

```bash
docker pull antmoc/antmoc:<tag>
docker run -it --rm antmoc/antmoc:<tag> antmoc <args>
```

For ANT-MOC with MPI:

```bash
docker pull antmoc/antmoc:<tag>
docker run -it --rm antmoc/antmoc:<tag> mpirun -np 2 antmoc <args>
```

Reading local input files:

```bash
# assume that you have an input file named cases/settings.toml
docker pull antmoc/antmoc:<tag>
docker run -it --rm \
    -v cases/:/root/cases/ \
    antmoc/antmoc:<tag> \
    mpirun -np 2 antmoc -c cases/settings.toml
```

Interactive runs:
```bash
docker pull antmoc/antmoc:<tag>
docker run -it --rm antmoc/antmoc:<tag> bash
```