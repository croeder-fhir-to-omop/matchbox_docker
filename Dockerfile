ARG IG_SOURCE=""
ARG IG_COMMIT=""
ARG IG_BUILD_DATE=""

FROM bellsoft/liberica-openjdk-debian:26
EXPOSE 8080

ARG IG_SOURCE
ARG IG_COMMIT
ARG IG_BUILD_DATE
LABEL fhir-omop-ig.source="${IG_SOURCE}" \
      fhir-omop-ig.commit="${IG_COMMIT}" \
      fhir-omop-ig.build-date="${IG_BUILD_DATE}"

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y curl \
 && rm -rf /var/lib/apt/lists/*

COPY --from=ig_dir /hl7.fhir.uv.omop-1.0.0.tgz /tmp/ig.tgz
COPY --from=certs_dir /enchilada.jks /certs/enchilada.jks

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

# Merge system CAs with enchilada's self-signed cert so both local enchilada
# and public echidna.fhir.org work over HTTPS without overriding the CA bundle.
RUN keytool -importkeystore \
      -srckeystore "$JAVA_HOME/lib/security/cacerts" \
      -srcstorepass changeit \
      -destkeystore /certs/combined.jks \
      -deststorepass changeit \
      -noprompt 2>/dev/null; \
    keytool -importkeystore \
      -srckeystore /certs/enchilada.jks \
      -srcstorepass changeit \
      -destkeystore /certs/combined.jks \
      -deststorepass changeit \
      -noprompt 2>/dev/null || true; \
    chown -R matchbox:matchbox /certs

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

ENV JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=/certs/combined.jks -Djavax.net.ssl.trustStorePassword=changeit"
ENV HEALTHCHECK_URL=http://localhost:8080/matchboxv3/actuator/health

HEALTHCHECK --interval=10s --timeout=3s --start-period=60s --retries=6 \
  CMD curl -sf $HEALTHCHECK_URL || exit 1

ENTRYPOINT ["java", "-Xmx4g", \
  "-Dfhir.settings.path=/config/fhir-settings.json", \
  "-Dspring.config.additional-location=optional:file:/defaults/application.yaml,optional:file:/config/application.yaml", \
  "-jar", "/matchbox.jar"]
