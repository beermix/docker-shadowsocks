FROM alpine:edge

ENV SHADOWSOCKS_VERSION 3.3.3
ENV SIMPLE_OBFS_VERSION 486bebd
ENV KCPTUN_VERSION 20191127
ENV LIBSODIUM_URL https://github.com/jedisct1/libsodium/releases/download/1.0.18-RELEASE/libsodium-1.0.18.tar.gz
ENV SHADOWSOCKS_URL https://github.com/shadowsocks/shadowsocks-libev/releases/download/v$SHADOWSOCKS_VERSION/shadowsocks-libev-$SHADOWSOCKS_VERSION.tar.gz
ENV SIMPLE_OBFS_URL https://github.com/shadowsocks/simple-obfs.git
ENV KCPTUN_URL https://github.com/xtaci/kcptun/releases/download/v$KCPTUN_VERSION/kcptun-linux-amd64-$KCPTUN_VERSION.tar.gz

RUN apk upgrade --update \
  && apk add --virtual .build-deps curl git \
     build-base gcc abuild binutils binutils-doc gcc-doc \
     pcre-dev mbedtls-dev libsodium-dev c-ares-dev linux-headers libev-dev asciidoc xmlto \
     autoconf automake libtool \
  && cd /tmp \
   && curl -sSLO "$LIBSODIUM_URL" \
  && tar xfz libsodium-1.0.18.tar.gz \
  && cd libsodium-1.0.18 \
  && ./configure --prefix=/usr --enable-minimal --enable-opt \
  && make && make install \
  && cd /tmp \
  && curl -sSLO "$SHADOWSOCKS_URL" \
  && tar xfz shadowsocks-libev-$SHADOWSOCKS_VERSION.tar.gz \
  && cd shadowsocks-libev-$SHADOWSOCKS_VERSION \
  && ./configure --prefix=/usr --disable-documentation --disable-assert --disable-ssp \
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
