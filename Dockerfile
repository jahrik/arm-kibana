FROM arm32v7/node

ENV ARCH armhf

# Add kibana user and group first to make sure their IDs get assigned consistently
RUN groupadd -r kibana && useradd -r -m -g kibana kibana

# Dependencies
# Generating PDFs requires libfontconfig and libfreetype6
RUN apt-get update && apt-get install -y \
  --no-install-recommends \
  apt-transport-https \
  ca-certificates \
  libfontconfig \
  libfreetype6 \
  gpg-agent \
  dirmngr \
  gnupg2 \
  wget \
  gpg
RUN rm -rf /var/lib/apt/lists/*

# gosu
# grab gosu for easy step-down from root
RUN set -eux; \
	apt-get update; \
	apt-get install -y gosu; \
	rm -rf /var/lib/apt/lists/*; \
# verify that the binary works
	gosu nobody true

# Tini
# For signal processing and zombie killing
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-${ARCH} /usr/local/bin/tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-${ARCH}.asc /usr/local/bin/tini.asc
RUN gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7
RUN gpg --verify /usr/local/bin/tini.asc
RUN rm -rf /usr/local/bin/tini.asc
RUN chmod +x /usr/local/bin/tini
RUN tini -h

# Kibana
# https://www.elastic.co/guide/en/kibana/5.5/deb.html
# https://unix.stackexchange.com/questions/215864/running-x86-binaries-on-armv7
ENV KIBANA_VERSION 5.6.12
ENV KIBANA_HOME /usr/share/kibana
WORKDIR ${KIBANA_HOME}
# Install from tar file.  Didn't have much luck with the .deb file
RUN wget https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_VERSION}-linux-x86.tar.gz
RUN sha1sum kibana-${KIBANA_VERSION}-linux-x86.tar.gz
RUN tar -xzf kibana-${KIBANA_VERSION}-linux-x86.tar.gz -C ${KIBANA_HOME} --strip-components 1
RUN rm kibana-${KIBANA_VERSION}-linux-x86.tar.gz
# Remove the version of node packed with kibana
# It doesn't work on the Renegade SBC
RUN rm -rf ${KIBANA_HOME}/node
# Symlink the version of node included with arm32v7/node
# as the default for kibana to use instead
RUN ln -sf /usr/local/bin/node ${KIBANA_HOME}/node
RUN mkdir -p /etc/kibana
# Symlink the config file changes made at run time
# to the config file kibana uses by default
RUN ln -sf ${KIBANA_HOME}/config/kibana.yml /etc/kibana/kibana.yml
RUN chown -R kibana:kibana ${KIBANA_HOME}
RUN chown -R kibana:kibana /etc/kibana/

ENV PATH ${KIBANA_HOME}/bin:$PATH

# the default "server.host" is "localhost" in 5+
RUN sed -ri "s!^(\#\s*)?(server\.host:).*!\2 '0.0.0.0'!" ${KIBANA_HOME}/config/kibana.yml
RUN grep -q "^server\.host: '0.0.0.0'\$" ${KIBANA_HOME}/config/kibana.yml
# ensure the default configuration is useful when using --link
RUN sed -ri "s!^(\#\s*)?(elasticsearch\.url:).*!\2 'http://elasticsearch:9200'!" ${KIBANA_HOME}/config/kibana.yml
RUN grep -q "^elasticsearch\.url: 'http://elasticsearch:9200'\$" ${KIBANA_HOME}/config/kibana.yml

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

EXPOSE 5601
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["kibana"]
