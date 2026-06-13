# arm-kibana

[![Build](https://github.com/jahrik/arm-kibana/actions/workflows/build.yml/badge.svg)](https://github.com/jahrik/arm-kibana/actions/workflows/build.yml)

Multi-arch [Kibana](https://www.elastic.co/kibana) image for the `elk` swarm stack. Originally a 2018 ARM port (x86 tarball with the bundled node swapped for ARM node); now a pinned layer over the official `docker.elastic.co/kibana/kibana` image.

## Run

```bash
docker run -d -p 5601:5601 -e ELASTICSEARCH_HOSTS=http://elasticsearch:9200 jahrik/arm-kibana:latest
```

## Deploy (swarm)

```bash
docker network create -d overlay elk   # once
make deploy                            # stack: elk, behind traefik
ansible-playbook playbook.yml          # create /mnt/g1/kibana on cluster nodes
```

## Build

```bash
make build
make push
```

CI: PR builds + HTTP check; merge to main pushes multi-arch (amd64/arm64) to Docker Hub. No armv7: modern Kibana is 64-bit only.
