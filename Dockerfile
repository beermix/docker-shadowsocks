FROM alpine

ENV SHADOWSOCKS_VERSION ffc2ea42fc8a4332ffa9b8b022ec86b97a19748c
ENV SIMPLE_OBFS_VERSION 486bebd
ENV KCPTUN_VERSION 20191219
ENV SHADOWSOCKS_URL https://github.com/shadowsocks/shadowsocks-libev/archive/$SHADOWSOCKS_VERSION.tar.gz
ENV SIMPLE_OBFS_URL https://github.com/shadowsocks/simple-obfs.git
ENV KCPTUN_URL https://github.com/xtaci/kcptun/releases/download/v$KCPTUN_VERSION/kcptun-linux-amd64-$KCPTUN_VERSION.tar.gz

RUN set -ex \
  && apk upgrade --update \
  && apk add --no-cache --virtual .build-deps \
     build-base \
     pcre-dev c-ares-dev linux-headers libev-dev zlib-dev flex bison libcap libsodium-dev mbedtls-dev \
     autoconf automake libtool curl git cmake \
  && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing libcorkipset-dev libbloom-dev \
  && cd /tmp \
  && curl -sSLO "$SHADOWSOCKS_URL" \
  && tar xfz $SHADOWSOCKS_VERSION.tar.gz \
  && cd shadowsocks-libev-$SHADOWSOCKS_VERSION \
  && sed -i 's|AC_CONFIG_FILES(\[libbloom/Makefile libcork/Makefile libipset/Makefile\])||' configure.ac \
  && ./autogen.sh \
  && ./configure --prefix=/usr --disable-documentation --enable-shared --disable-static --enable-system-shared-lib --disable-silent-rules \
  && make install \
  && ls /usr/bin/ss-* | xargs -n1 setcap cap_net_bind_service+ep \
  && cd /tmp \
  && git clone $SIMPLE_OBFS_URL \
  && cd simple-obfs \
  && git checkout -b v$SIMPLE_OBFS_VERSION \
  && git submodule update --init --recursive \
  && ./autogen.sh \
  && ./configure --disable-documentation --disable-silent-rules \
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
  && apk add --virtual .run-deps $runDeps libsodium \
  && apk add --virtual .sys-deps bash \
  && apk del .build-deps \
  && rm -rf /tmp/* /var/cache/apk/*

ADD sysctl.conf /etc/sysctl.conf
ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
