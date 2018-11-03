FROM arm32v7/ubuntu

ENV ARCH armhf

# add our user and group first to make sure their IDs get assigned consistently
RUN groupadd -r kibana && useradd -r -m -g kibana kibana

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
RUN wget https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_VERSION}-linux-x86.tar.gz
RUN sha1sum kibana-${KIBANA_VERSION}-linux-x86.tar.gz
RUN tar -xzf kibana-${KIBANA_VERSION}-linux-x86.tar.gz

# RUN set -x \
# 	&& apt-get update \
# 	&& apt-get install -y --no-install-recommends kibana=$KIBANA_VERSION \
# 	&& rm -rf /var/lib/apt/lists/* \
# 	\
# # the default "server.host" is "localhost" in 5+
# 	&& sed -ri "s!^(\#\s*)?(server\.host:).*!\2 '0.0.0.0'!" /etc/kibana/kibana.yml \
# 	&& grep -q "^server\.host: '0.0.0.0'\$" /etc/kibana/kibana.yml \
# 	\
# # ensure the default configuration is useful when using --link
# 	&& sed -ri "s!^(\#\s*)?(elasticsearch\.url:).*!\2 'http://elasticsearch:9200'!" /etc/kibana/kibana.yml \
# 	&& grep -q "^elasticsearch\.url: 'http://elasticsearch:9200'\$" /etc/kibana/kibana.yml

ENV PATH /usr/share/kibana/bin:$PATH

COPY docker-entrypoint.sh /

EXPOSE 5601
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["kibana"]
