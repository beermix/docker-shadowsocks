FROM alpine:edge

ENV SHADOWSOCKS_VERSION master
ENV LIBSODIUM_VERSION 1.0.18
ENV SIMPLE_OBFS_VERSION master
ENV KCPTUN_VERSION 20200103
ENV LIBSODIUM_URL https://github.com/jedisct1/libsodium/releases/download/$LIBSODIUM_VERSION-RELEASE/libsodium-$LIBSODIUM_VERSION.tar.gz
ENV SHADOWSOCKS_URL https://github.com/shadowsocks/shadowsocks-libev/archive/$SHADOWSOCKS_VERSION.tar.gz
ENV SIMPLE_OBFS_URL https://github.com/shadowsocks/simple-obfs.git
ENV KCPTUN_URL https://github.com/xtaci/kcptun/releases/download/v$KCPTUN_VERSION/kcptun-linux-amd64-$KCPTUN_VERSION.tar.gz


RUN apk upgrade --update \
  && apk add --no-cache --virtual .build-deps build-base alpine-sdk cmake linux-headers \
  udns-dev pcre-dev zlib-dev libcap autoconf automake autoconf-archive c-ares-dev libtool curl git wget gawk \
  && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing libcorkipset-dev libbloom-dev \
  && cd /tmp \
  && curl -sSLO "$SHADOWSOCKS_URL" \
  && tar xfz $SHADOWSOCKS_VERSION.tar.gz \
  && cd shadowsocks-libev-$SHADOWSOCKS_VERSION \
  && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DWITH_DOC_HTML=0 -DWITH_DOC_MAN=0 -DWITH_EMBEDDED_SRC=0 -DWITH_SS_REDIR=0 -DWITH_STATIC=0 -DCMAKE_VERBOSE_MAKEFILE=0 \
  && make install \
  && ldd ./bin/ss-server \
  && ls /usr/bin/ss-* | xargs -n1 setcap cap_net_bind_service+ep \
  && cd /tmp \
  && git clone --recursive $SIMPLE_OBFS_URL \
  && cd simple-obfs \
  && ./autogen.sh \
  && ./configure --disable-documentation \
  && make install \
  && cd /tmp \
  && curl -sSLO $KCPTUN_URL \
  && tar xfz kcptun-linux-amd64-${KCPTUN_VERSION}.tar.gz \
  && mv server_linux_amd64 /usr/bin/kcptun-server \
  && mv client_linux_amd64 /usr/bin/kcptun-client \
  && runDeps="$( \
      scanelf --needed --nobanner /usr/bin/ss-* /usr/local/bin/obfs-* \
        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
        | xargs -r apk info --installed \
        | sort -u \
      )" \
  && apk add --virtual .run-deps $runDeps ca-certificates rng-tools \
  && apk add --virtual .sys-deps bash \
  && apk del .build-deps \
  && rm -rf /tmp/* /var/cache/apk/*

ADD sysctl.conf /etc/sysctl.conf
ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
