FROM openjdk:jre-alpine

LABEL maintainer "Yuhang Ge <abeyuhang@gmail.com>"

ENV ES_VERSION=5.5.1 \
    KIBANA_VERSION=5.5.1

RUN apk add --quiet --no-progress --no-cache git bash openssh nodejs wget \
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

RUN kibana/node/bin/npm install http-server
RUN git clone --depth=1 https://github.com/mobz/elasticsearch-head.git

CMD sh elasticsearch/bin/elasticsearch -E http.host=0.0.0.0 --quiet & kibana/bin/kibana --host 0.0.0.0 -Q & node_modules/.bin/http-server elasticsearch-head/_site -p 9100


EXPOSE 9200 5601 9100