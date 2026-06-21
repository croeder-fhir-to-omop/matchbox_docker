FROM bellsoft/liberica-openjdk-debian:26
EXPOSE 8080

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y curl \
 && rm -rf /var/lib/apt/lists/*

COPY --from=ig_dir /hl7.fhir.uv.omop-1.0.0.tgz /tmp/ig.tgz

COPY ./target/matchbox.jar /matchbox.jar
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
RUN mkdir -p /data/hapi/lucenefiles && chmod 775 /data/hapi/lucenefiles

RUN adduser --disabled-password --gecos '' matchbox
ENV HOME=/home/matchbox
RUN mkdir -p /database && chown matchbox:matchbox /database
RUN mkdir -p /config && chown matchbox:matchbox /config
RUN mkdir -p /igs \
 && mv /tmp/ig.tgz /igs/hl7.fhir.uv.omop-1.0.0.tgz \
 && chown -R matchbox:matchbox /igs
RUN chown matchbox:matchbox /

RUN mkdir -p /defaults
COPY --chown=matchbox:matchbox <<EOF /defaults/application.yaml
spring:
  datasource:
    url: "jdbc:h2:file:/database/h2"
    username: sa
    password: null
    driverClassName: org.h2.Driver
  jpa:
    properties:
      hibernate.dialect: ca.uhn.fhir.jpa.model.dialect.HapiFhirH2Dialect

hapi:
  fhir:
    fhir_version: R5
    implementationguides:
      fhiromop:
        name: hl7.fhir.uv.omop
        version: 1.0.0
        url: file:///igs/hl7.fhir.uv.omop-1.0.0.tgz

matchbox:
  fhir:
    context:
      txServer: https://echidna.fhir.org/r4
      translateMode: fallback
      onlyOneEngine: true
      igsPreloaded:
        - hl7.fhir.uv.omop#1.0.0
EOF

USER matchbox

ENV HEALTHCHECK_URL=http://localhost:8080/matchboxv3/actuator/health

HEALTHCHECK --interval=10s --timeout=3s --start-period=60s --retries=6 \
  CMD curl -sf $HEALTHCHECK_URL || exit 1

ENTRYPOINT ["java", "-Xmx4g", \
  "-Dfhir.settings.path=/config/fhir-settings.json", \
  "-Dspring.config.additional-location=optional:file:/defaults/application.yaml,optional:file:/config/application.yaml", \
  "-jar", "/matchbox.jar"]
