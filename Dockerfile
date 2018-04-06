
FROM openjdk:8-jre-alpine

# Expose ports
EXPOSE 80

# Add tags
LABEL \
  maintainer="The Petals team" \
  contributors="Pierre Souquet (Linagora), Vincent Zurczak (Linagora)" \
  github="https://github.com/petalslink"

# Build arguments
ARG CLI_VERSION="LATEST"
ARG MAVEN_POLICY="releases"
ARG BASE_URL="https://repository.ow2.org/nexus/service/local/artifact/maven/redirect"

# Copy the script (first)
COPY docker-wrapper.sh /opt/petals-deployer/docker-wrapper.sh

RUN apk add --no-cache --virtual .bootstrap-deps wget ca-certificates && \
  wget --progress=bar:force:noscroll -O /tmp/petals-cli-distrib.zip "${BASE_URL}?g=org.ow2.petals&r=${MAVEN_POLICY}&a=petals-cli-distrib-zip&v=${CLI_VERSION}&p=zip" && \
  wget --progress=bar:force:noscroll -O /tmp/petals-cli-distrib.zip.sha1 "${BASE_URL}?g=org.ow2.petals&r=${MAVEN_POLICY}&a=petals-cli-distrib-zip&v=${CLI_VERSION}&p=zip.sha1" && \
  [ `sha1sum /tmp/petals-cli-distrib.zip | cut -d" " -f1` = `cat /tmp/petals-cli-distrib.zip.sha1` ] && \
  mkdir /tmp/petals-cli-distrib-zip && \
  unzip /tmp/petals-cli-distrib.zip -d /tmp/petals-cli-distrib-zip && \
  cp -r /tmp/petals-cli-distrib-zip/petals-cli-distrib-zip-*/* /opt/petals-deployer && \
  rm -rf /tmp/petals-cli-distrib* && \
  chmod -R 775 /opt/petals-deployer/ && \
  apk del .bootstrap-deps wget ca-certificates && \
  rm -rf /var/cache/apk/*

# Set the working directory
WORKDIR /opt/petals-deployer

# Indicate the default script
CMD /opt/petals-deployer/docker-wrapper.sh 
