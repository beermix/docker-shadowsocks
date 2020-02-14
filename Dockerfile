FROM alpine:edge

ENV SHADOWSOCKS_VERSION 3.3.4
ENV KCPTUN_VERSION 20200201
ENV SIMPLE_OBFS_VERSION 486bebd
ENV SHADOWSOCKS_URL https://github.com/shadowsocks/shadowsocks-libev/releases/download/v$SHADOWSOCKS_VERSION/shadowsocks-libev-$SHADOWSOCKS_VERSION.tar.gz
ENV SIMPLE_OBFS_URL https://github.com/shadowsocks/simple-obfs.git
ENV KCPTUN_URL https://github.com/xtaci/kcptun/releases/download/v$KCPTUN_VERSION/kcptun-linux-amd64-$KCPTUN_VERSION.tar.gz

RUN apk upgrade --update \
  && apk add --no-cache --virtual .build-deps build-base gcc abuild binutils autoconf automake libtool curl git flex bison gawk sed \
  alpine-sdk linux-headers udns-dev pcre-dev mbedtls-dev libsodium-dev c-ares-dev libev-dev libcap \
  && cd /tmp \
  && curl -sSLO "$SHADOWSOCKS_URL" \
  && tar xfz shadowsocks-libev-$SHADOWSOCKS_VERSION.tar.gz \
  && cd shadowsocks-libev-$SHADOWSOCKS_VERSION \
  && ./configure CFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt" CXXFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt" CPPFLAGS="-D_FORTIFY_SOURCE=2" LDFLAGS="-Wl,-O1,--sort-common,-z,relro,-z,now -s" --prefix=/usr --disable-documentation --disable-silent-rules --disable-ssp \
  && make install \
  && ls /usr/bin/ss-* | xargs -n1 setcap cap_net_bind_service+ep \
  && cd /tmp \
  && git clone $SIMPLE_OBFS_URL \
  && cd simple-obfs \
  && git checkout -b v$SIMPLE_OBFS_VERSION \
  && git submodule update --init --recursive \
  && ./configure CFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt" CXXFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt" CPPFLAGS="-D_FORTIFY_SOURCE=2" LDFLAGS="-Wl,-O1,--sort-common,-z,relro,-z,now -s" --disable-documentation --disable-ssp \
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
