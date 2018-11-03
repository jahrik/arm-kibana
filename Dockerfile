FROM arm32v7/ubuntu

ENV ARCH armhf

# add our user and group first to make sure their IDs get assigned consistently
# RUN groupadd -r kibana && useradd -r -m -g kibana kibana

# dependencies
RUN apt-get update && apt-get install -y \
		apt-transport-https \
		ca-certificates \
    gpg-agent \
    dirmngr \
		wget \
    gnupg2 \
    gpg \
# generating PDFs requires libfontconfig and libfreetype6
		libfontconfig \
		libfreetype6 \
	--no-install-recommends && rm -rf /var/lib/apt/lists/*

# gosu
# grab gosu for easy step-down from root
RUN set -eux; \
	apt-get update; \
	apt-get install -y gosu; \
	rm -rf /var/lib/apt/lists/*; \
# verify that the binary works
	gosu nobody true

# Tini
# grab tini for signal processing and zombie killing
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
RUN wget https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_VERSION}-linux-x86.tar.gz
RUN sha1sum kibana-${KIBANA_VERSION}-linux-x86.tar.gz
RUN tar -xzf kibana-${KIBANA_VERSION}-linux-x86.tar.gz -C ${KIBANA_HOME} --strip-components 1
RUN rm kibana-${KIBANA_VERSION}-linux-x86.tar.gz
RUN mkdir -p /etc/kibana
RUN ln -sf ${KIBANA_HOME}/config/kibana.yml /etc/kibana/kibana.yml

ENV PATH ${KIBANA_HOME}/bin:$PATH

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

EXPOSE 5601
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["kibana"]
