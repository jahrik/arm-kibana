# AGENTS.md

Multi-arch Kibana image: pinned `FROM` over official `docker.elastic.co/kibana/kibana`, deployed in the `elk` swarm stack behind traefik.

## Commands

```bash
make build                                  # build jahrik/arm-kibana:latest
docker run -d -p 5601:5601 jahrik/arm-kibana:latest   # /api/status answers degraded without ES
make deploy                                 # swarm stack deploy (stack: elk)
```

## CI

`build.yml`: Test (build + HTTP poll on `/api/status`) on PR; Release (buildx amd64/arm64 push to Docker Hub) on merge to main. Needs `DOCKERHUB_USERNAME`/`DOCKERHUB_TOKEN` secrets. No armv7 — Elastic has no 32-bit images.

## Quirks

- Bump Kibana via the `FROM` tag; keep it on the same major as arm-elasticsearch.
- ES endpoint is `ELASTICSEARCH_HOSTS` (9.x renamed it from `ELASTICSEARCH_URL`).
- External `traefik` + `elk` overlay networks — keep that wiring. Traefik labels are 1.x syntax, updated when the traefik stack is.
- `playbook.yml` just creates `/mnt/g1/kibana` on cluster nodes.
