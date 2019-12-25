FROM alpine:edge

ENV MBEDTLS_VERSION 2.16.3
ENV LIBSODIUM_VERSION 1.0.18
ENV LIBEV_VERSION 4.31
ENV SHADOWSOCKS_VERSION master
ENV SIMPLE_OBFS_VERSION master
ENV KCPTUN_VERSION 20191219
ENV MBEDTLS_URL=https://tls.mbed.org/download/mbedtls-$MBEDTLS_VERSION-gpl.tgz
ENV LIBSODIUM_URL https://github.com/jedisct1/libsodium/releases/download/$LIBSODIUM_VERSION-RELEASE/libsodium-$LIBSODIUM_VERSION.tar.gz
ENV LIBEV_URL https://fossies.org/linux/misc/libev-$LIBEV_VERSION.tar.gz
ENV SHADOWSOCKS_URL https://github.com/shadowsocks/shadowsocks-libev/archive/$SHADOWSOCKS_VERSION.tar.gz
ENV SIMPLE_OBFS_URL https://github.com/shadowsocks/simple-obfs.git
ENV KCPTUN_URL https://github.com/xtaci/kcptun/releases/download/v$KCPTUN_VERSION/kcptun-linux-amd64-$KCPTUN_VERSION.tar.gz

RUN apk upgrade --update \
  && apk add --no-cache --virtual .build-deps \
  && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing build-base libcorkipset-dev libbloom-dev udns-dev pcre-dev c-ares-dev linux-headers zlib-dev libcap autoconf automake libtool curl git cmake wget autoconf-archive gawk \
  && cd /tmp \
  && curl -sSLO "$LIBEV_URL" \
  && tar xfz libev-$LIBEV_VERSION.tar.gz \
  && cd libev-$LIBEV_VERSION \
  && bash autogen.sh \
  && ./configure --prefix=/usr --disable-shared --with-pic \
  && make install \
  && cd /tmp \
  && curl -sSLO "$MBEDTLS_URL" \
  && tar xfz mbedtls-$MBEDTLS_VERSION-gpl.tgz \
  && cd mbedtls-$MBEDTLS_VERSION \
  && sed -i -e 's|//\(#define MBEDTLS_THREADING_C\)|\1|' -e 's|//\(#define MBEDTLS_THREADING_PTHREAD\)|\1|' include/mbedtls/config.h \
  && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DUSE_SHARED_MBEDTLS_LIBRARY=0 -DUSE_STATIC_MBEDTLS_LIBRARY=1 -DENABLE_PROGRAMS=0 -DENABLE_TESTING=0 -DLINK_WITH_PTHREAD=1 -DCMAKE_C_FLAGS_RELEASE="-march=native -O3 -DNDEBUG -fPIC" -Wno-dev \
  && make install \
  && cd /tmp \
  && curl -sSLO "$LIBSODIUM_URL" \
  && tar xfz libsodium-$LIBSODIUM_VERSION.tar.gz \
  && cd libsodium-$LIBSODIUM_VERSION \
  && bash autogen.sh \
  && ./configure --prefix=/usr --enable-opt --disable-shared --with-pic \
  && make install \
  && cd /tmp \
  && curl -sSLO "$SHADOWSOCKS_URL" \
  && tar xfz $SHADOWSOCKS_VERSION.tar.gz \
  && cd shadowsocks-libev-$SHADOWSOCKS_VERSION \
  && wget https://raw.githubusercontent.com/alpinelinux/aports/master/testing/shadowsocks-libev/use-upstream-libcorkipset-libbloom.patch \
  && patch -p1 < use-upstream-libcorkipset-libbloom.patch \
  && bash autogen.sh \
  && ./configure --prefix=/usr --disable-documentation --enable-shared --enable-system-shared-lib --disable-silent-rules \
  && make install \
  && ls /usr/bin/ss-* | xargs -n1 setcap cap_net_bind_service+ep \
  && cd /tmp \
  && git clone --recursive $SIMPLE_OBFS_URL \
  && cd simple-obfs \
  && bash autogen.sh \
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
  && apk add --virtual .run-deps $runDeps \
  && apk add --virtual .sys-deps bash \
  && apk add ca-certificates rng-tools \
  && apk del .build-deps \
  && rm -rf /tmp/* /var/cache/apk/*

ADD sysctl.conf /etc/sysctl.conf
ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
