# matchbox_docker

Docker configuration for running [matchbox](https://github.com/croeder-fhir-to-omop/matchbox), a FHIR server with the [HL7 FHIR-to-OMOP Implementation Guide](https://hl7.org/fhir/uv/omop/) pre-loaded.

Part of the [croeder-fhir-to-omop](https://github.com/croeder-fhir-to-omop) FHIR→OMOP pipeline:

| Repo | Role |
|---|---|
| [matchbox](https://github.com/croeder-fhir-to-omop/matchbox) | FHIR server with OMOP IG (fork of ahdis/matchbox) |
| **[matchbox_docker](https://github.com/croeder-fhir-to-omop/matchbox_docker)** | **Docker config and IGs for matchbox ← you are here** |
| [matchbox_scripts](https://github.com/croeder-fhir-to-omop/matchbox_scripts) | Transform functions, ETL script, and FHIR fixtures |
| [jupyter_docker](https://github.com/croeder-fhir-to-omop/jupyter_docker) | Interactive Jupyter notebook environment |
| [dqd_docker](https://github.com/croeder-fhir-to-omop/dqd_docker) | Automated ETL + OHDSI Data Quality Dashboard |

## Contents

| Path | Description |
|---|---|
| `Dockerfile` | Builds the matchbox image from `matchbox.jar`; downloads the OMOP IG at build time |
| `config/application.yaml` | Spring/matchbox configuration — sets the OMOP IG, Echidna terminology server, and H2 database path |
| `igs/hl7.fhir.uv.omop-1.0.0.tgz` | OMOP IG package (also baked into the image; mount to override) |
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
docker compose -f docker-compose.build.yml push
```

## Using a locally built version of the OMOP IG

This section assumes you have cloned this repo (`matchbox_docker`) and are running `docker compose` from within it. The `./igs` and `./config` directories referenced below are inside that clone.

If you are developing the IG in a sibling `fhir-omop-ig` repo and want matchbox to use your local build:

1. Set the version in `fhir-omop-ig/sushi-config.yaml`:
   ```yaml
   version: 1.1.0
   ```
2. Build the IG (produces `fhir-omop-ig/output/hl7.fhir.uv.omop.en.tgz`)
3. Copy it into this repo's `igs/` folder using the `{name}-{version}.tgz` naming convention:
   ```bash
   cp ../fhir-omop-ig/output/hl7.fhir.uv.omop.en.tgz ./igs/hl7.fhir.uv.omop-1.1.0.tgz
   ```
4. Update `config/application.yaml` to reference the new version in both places:
   ```yaml
   hapi:
     fhir:
       implementationguides:
         fhiromop:
           name: hl7.fhir.uv.omop
           version: 1.1.0
   matchbox:
     fhir:
       context:
         igsPreloaded:
           - hl7.fhir.uv.omop#1.1.0
   ```
5. Restart matchbox:
   ```bash
   docker compose down && docker compose up
   ```

No image rebuild is required. Both `./igs` and `./config` are mounted into the container at runtime, so changes to either take effect on the next `docker compose up`. You would only need to rebuild the image if changing the `Dockerfile` itself or updating `matchbox.jar`.

The version in `config/application.yaml` must match the `"version"` field in `package/package.json` inside the tgz (which SUSHI sets from `sushi-config.yaml`).

## Role in the larger system

`dqd_docker` and `jupyter_docker` pull `croeder/matchbox:latest` directly — no clone of this repo is required to run them. The `config/` and `igs/` directories here are for local development overrides only.
