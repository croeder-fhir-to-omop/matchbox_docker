# matchbox_docker

Docker configuration for running [matchbox](https://github.com/croeder-fhir-to-omop/matchbox), a FHIR server with the [HL7 FHIR-to-OMOP Implementation Guide](https://hl7.org/fhir/uv/omop/) pre-loaded.

## Contents

| Path | Description |
|---|---|
| `Dockerfile` | Builds the matchbox image from `matchbox.jar` |
| `config/application.yaml` | Spring/matchbox configuration — sets the OMOP IG, Echidna terminology server, and H2 database path |
| `igs/hl7.fhir.uv.omop-1.0.0.tgz` | OMOP IG package, mounted into the container at startup |
| `docker-compose.yml` | Runs matchbox standalone on port 8080 |
| `docker-compose.build.yml` | Builds the image from source (requires `matchbox` repo cloned alongside) |

## Running standalone

```bash
docker compose up
```

matchbox is available at http://localhost:8080. On first run it loads the OMOP IG (~1 min); subsequent runs use the cached H2 volume.

## Building the image from source

Requires the `matchbox` repo cloned into the same parent directory.

```bash
docker compose -f docker-compose.build.yml build
```

## Role in the larger system

`dqd_docker` and `jupyter_docker` both depend on this image (`croeder/matchbox:latest`) and mount `config/` and `igs/` from this repo. See the [organisation README](https://github.com/croeder-fhir-to-omop) for end-to-end usage.
