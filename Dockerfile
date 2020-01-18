FROM alpine:edge

ENV MBEDTLS_VERSION 2.16.4
ENV LIBSODIUM_VERSION stable
ENV LIBEV_VERSION 4.31
ENV SHADOWSOCKS_VERSION master
ENV SIMPLE_OBFS_VERSION master
ENV KCPTUN_VERSION 20200103
ENV MBEDTLS_URL=https://tls.mbed.org/download/mbedtls-$MBEDTLS_VERSION-gpl.tgz
ENV LIBSODIUM_URL https://github.com/jedisct1/libsodium/archive/stable.tar.gz
ENV LIBEV_URL https://fossies.org/linux/misc/libev-$LIBEV_VERSION.tar.gz
ENV SHADOWSOCKS_URL https://github.com/shadowsocks/shadowsocks-libev/archive/$SHADOWSOCKS_VERSION.tar.gz
ENV SIMPLE_OBFS_URL https://github.com/shadowsocks/simple-obfs.git
ENV KCPTUN_URL https://github.com/xtaci/kcptun/releases/download/v$KCPTUN_VERSION/kcptun-linux-amd64-$KCPTUN_VERSION.tar.gz

RUN apk upgrade --update \
  && apk add --no-cache --virtual .build-deps build-base alpine-sdk cmake linux-headers \
  udns-dev pcre-dev c-ares-dev zlib-dev libcap autoconf automake libtool wget curl git gawk \
  && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing libcorkipset-dev libbloom-dev \
  && cd /tmp \
  && curl -sSLO "$LIBEV_URL" \
  && tar xfz libev-$LIBEV_VERSION.tar.gz \
  && cd libev-$LIBEV_VERSION \
  && bash autogen.sh \
  && ./configure --prefix=/usr \
  && make install \
  && cd /tmp \
  && curl -sSLO "$MBEDTLS_URL" \
  && tar xfz mbedtls-$MBEDTLS_VERSION-gpl.tgz \
  && cd mbedtls-$MBEDTLS_VERSION \
  && sed -i -e 's|//\(#define MBEDTLS_THREADING_C\)|\1|' -e 's|//\(#define MBEDTLS_THREADING_PTHREAD\)|\1|' include/mbedtls/config.h \
  && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DUSE_SHARED_MBEDTLS_LIBRARY=1 -DUSE_STATIC_MBEDTLS_LIBRARY=1 -DENABLE_PROGRAMS=0 -DENABLE_TESTING=0 -DLINK_WITH_PTHREAD=1 -DCMAKE_VERBOSE_MAKEFILE=0 -Wno-dev \
  && make install \
  && cd /tmp \
  && curl -sSLO "$LIBSODIUM_URL" \
  && tar xfz libsodium-$LIBSODIUM_VERSION.tar.gz \
  && cd libsodium-$LIBSODIUM_VERSION \
  && ./autogen.sh \
  && ./configure --prefix=/usr --enable-opt \
  && make install \
  && cd /tmp \
  && curl -sSLO "$SHADOWSOCKS_URL" \
  && tar xfz $SHADOWSOCKS_VERSION.tar.gz \
  && cd shadowsocks-libev-$SHADOWSOCKS_VERSION \
  && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DWITH_DOC_HTML=0 -DWITH_DOC_MAN=0 -DWITH_EMBEDDED_SRC=0 -DWITH_SS_REDIR=0 -DWITH_STATIC=0 -DCMAKE_VERBOSE_MAKEFILE=0 \
  && make install \
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
