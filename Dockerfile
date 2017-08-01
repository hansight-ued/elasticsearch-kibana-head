FROM node:alpine

LABEL maintainer "Yuhang Ge <abeyuhang@gmail.com>"

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk/jre
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

ENV JAVA_VERSION 8u131
ENV JAVA_ALPINE_VERSION 8.131.11-r2

RUN set -x \
	&& apk add --no-cache \
		openjdk8-jre="$JAVA_ALPINE_VERSION" \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ]

ENV ES_VERSION=5.5.1 \
    KIBANA_VERSION=5.5.1

RUN apk add --quiet --no-progress --no-cache git bash openssh wget \
 && adduser -D elasticsearch

USER elasticsearch

WORKDIR /home/elasticsearch

RUN wget -q -O - https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ES_VERSION}.tar.gz \
 |  tar -zx \
 && mv elasticsearch-${ES_VERSION} elasticsearch \
 && wget -q -O - https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz \
 |  tar -zx \
 && mv kibana-${KIBANA_VERSION}-linux-x86_64 kibana \
 && rm -f kibana/node/bin/node kibana/node/bin/npm \
 && ln -s $(which node) kibana/node/bin/node \
 && ln -s $(which npm) kibana/node/bin/npm

RUN npm install http-server
RUN git clone --depth=1 https://github.com/mobz/elasticsearch-head.git

RUN echo $'\n\nhttp.host: 0.0.0.0\nhttp.cors.enabled: true\nhttp.cors.allow-origin: "*"\nhttp.cors.allow-headers: Authorization\n' >> elasticsearch/config/elasticsearch.yml

RUN elasticsearch/bin/elasticsearch-plugin install x-pack --batch

RUN kibana/bin/kibana-plugin install x-pack

CMD sh elasticsearch/bin/elasticsearch --quiet & kibana/bin/kibana --host 0.0.0.0 -Q & node_modules/.bin/http-server elasticsearch-head/_site -p 9100


EXPOSE 9200 5601 9100 9300