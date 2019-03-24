FROM alpine:3.6

# Install NGiNX.
RUN apk update && \
    apk upgrade && \
    apk add --update curl openssl bash ruby nodejs && \
    rm -rf /var/cache/apk/*

# We're going to install Kibana 4.4.X, which supports Elasticsearch 2.x

ENV KIBANA_44_VERSION 4.4.2
ENV KIBANA_44_SHA1SUM 6251dbab12722ea1a036d8113963183f077f9fa7
ENV PKG_NAME kibana
ENV PKG_PLATFORM linux-x64
ENV KIBANA_44_PKG $PKG_NAME-$KIBANA_44_VERSION-$PKG_PLATFORM

# Kibana 4.4
RUN echo "Downloading https://download.elastic.co/kibana/kibana/${KIBANA_44_PKG}.tar.gz" && \
    curl -O "https://download.elastic.co/kibana/kibana/${KIBANA_44_PKG}.tar.gz" && \
    mkdir /opt && \
    echo "${KIBANA_44_SHA1SUM}  ${KIBANA_44_PKG}.tar.gz" | sha1sum -c - && \
    tar xzf "${KIBANA_44_PKG}.tar.gz" -C /opt && \
    rm "${KIBANA_44_PKG}.tar.gz"

# Download Oauth2 Proxy 2.2, extract into /opt/oauth2_proxy
RUN curl -L -O https://github.com/bitly/oauth2_proxy/releases/download/v2.2/oauth2_proxy-2.2.0.linux-amd64.go1.8.1.tar.gz && \
  echo "1c73bc38141e079441875e5ea5e1a1d6054b4f3b  oauth2_proxy-2.2.0.linux-amd64.go1.8.1.tar.gz" | sha1sum -c - && \
  tar zxf oauth2_proxy-2.2.0.linux-amd64.go1.8.1.tar.gz -C /opt && \
  mv /opt/oauth2_proxy-2.2.0.linux-amd64.go1.8.1 /opt/oauth2_proxy

# Overwrite default config with our config.
RUN rm "/opt/${KIBANA_44_PKG}/config/kibana.yml"
ADD templates/opt/kibana-4.4.x/ /opt/kibana-${KIBANA_44_VERSION}/config

ADD patches /patches
RUN patch -p1 -d /opt/kibana-4.4.1-linux-x64 < /patches/0001-Set-authorization-header-when-connecting-to-ES.patch

# Add script that starts NGiNX in front of Kibana and tails the NGiNX access/error logs.
ADD bin .
RUN chmod 700 ./run-kibana.sh

# Add tests. Those won't run as part of the build because customers don't need to run
# them when deploying, but they'll be run in test.sh
ADD test /tmp/test

EXPOSE 80

CMD ["./run-kibana.sh"]