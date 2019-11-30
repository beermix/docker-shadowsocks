FROM alpine:edge

ENV MBEDTLS_VERSION 2.16.3
ENV LIBSODIUM_VERSION 1.0.18
ENV SHADOWSOCKS_VERSION 3.3.3
ENV SIMPLE_OBFS_VERSION 486bebd
ENV KCPTUN_VERSION 20191127
ENV MBEDTLS_URL=https://tls.mbed.org/download/mbedtls-$MBEDTLS_VERSION-gpl.tgz
ENV LIBSODIUM_URL https://github.com/jedisct1/libsodium/releases/download/$LIBSODIUM_VERSION-RELEASE/libsodium-$LIBSODIUM_VERSION.tar.gz
# ENV SHADOWSOCKS_URL https://github.com/shadowsocks/shadowsocks-libev/releases/download/v$SHADOWSOCKS_VERSION/shadowsocks-libev-$SHADOWSOCKS_VERSION.tar.gz
ENV SHADOWSOCKS_URL https://github.com/shadowsocks/shadowsocks-libev/archive/v$SHADOWSOCKS_VERSION.tar.gz
ENV SIMPLE_OBFS_URL https://github.com/shadowsocks/simple-obfs.git
ENV KCPTUN_URL https://github.com/xtaci/kcptun/releases/download/v$KCPTUN_VERSION/kcptun-linux-amd64-$KCPTUN_VERSION.tar.gz

RUN apk upgrade --update \
  && apk add --virtual .build-deps curl git \
     build-base gcc abuild binutils \
     pcre-dev c-ares-dev linux-headers libev-dev zlib-dev \
     asciidoc xmlto cmake \
     autoconf automake libtool \
  && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing libcorkipset-dev libbloom-dev \
  && cd /tmp \
  && curl -sSLO "$MBEDTLS_URL" \
  && tar xfz mbedtls-$MBEDTLS_VERSION-gpl.tgz \
  && cd mbedtls-$MBEDTLS_VERSION \
  && sed -i -e 's|//\(#define MBEDTLS_THREADING_C\)|\1|' -e 's|//\(#define MBEDTLS_THREADING_PTHREAD\)|\1|' include/mbedtls/config.h \
  && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DUSE_SHARED_MBEDTLS_LIBRARY=ON -DUSE_STATIC_MBEDTLS_LIBRARY=OFF -DENABLE_TESTING=OFF -DENABLE_PROGRAMS=OFF -Wno-dev && make && make install \
  && cd /tmp \
  && curl -sSLO "$LIBSODIUM_URL" \
  && tar xfz libsodium-$LIBSODIUM_VERSION.tar.gz \
  && cd libsodium-$LIBSODIUM_VERSION \
  && ./configure --prefix=/usr --enable-minimal --enable-opt \
  && make && make install \
  && cd /tmp \
  && curl -sSLO "$SHADOWSOCKS_URL" \
  && tar xfz shadowsocks-libev-$SHADOWSOCKS_VERSION.tar.gz \
  && cd shadowsocks-libev-$SHADOWSOCKS_VERSION \
  && sed -i 's|AC_CONFIG_FILES(\[libbloom/Makefile libcork/Makefile libipset/Makefile\])||' configure.ac \
  && ./autogen.sh \
  && ./configure CFLAGS="-march=native -O2 -pipe" --prefix=/usr --disable-documentation  --enable-shared --enable-system-shared-lib \
  && make && make install \
  && cd /tmp \
  && git clone $SIMPLE_OBFS_URL \
  && cd simple-obfs \
  && git checkout -b v$SIMPLE_OBFS_VERSION \
  && git submodule update --init --recursive \
  && ./autogen.sh \
  && ./configure \
  && make && make install \
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
  && apk add --virtual .run-deps $runDeps libsodium \
  && apk add --virtual .sys-deps bash \
  && apk del .build-deps \
  && rm -rf /tmp/* /var/cache/apk/*

ADD sysctl.conf /etc/sysctl.conf
ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
