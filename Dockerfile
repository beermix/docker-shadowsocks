FROM alpine:edge

ENV KCPTUN_VERSION 20200201
ENV SIMPLE_OBFS_VERSION 486bebd
ENV SIMPLE_OBFS_URL https://github.com/shadowsocks/simple-obfs.git
ENV KCPTUN_URL https://github.com/xtaci/kcptun/releases/download/v$KCPTUN_VERSION/kcptun-linux-amd64-$KCPTUN_VERSION.tar.gz

RUN apk upgrade --update \
  && apk add --no-cache --virtual .build-deps build-base autoconf automake libtool curl git flex bison gawk sed \
  alpine-sdk linux-headers udns-dev pcre-dev mbedtls-dev libsodium-dev c-ares-dev libev-dev libcap \
  && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing libcorkipset-dev libbloom-dev \
  && cd /tmp \
  && git clone --depth 1 https://github.com/shadowsocks/shadowsocks-libev \
  && cd shadowsocks-libev \
  && sed -i 's|AC_CONFIG_FILES(\[libbloom/Makefile libcork/Makefile libipset/Makefile\])||' configure.ac \
  && ./autogen.sh \
  && ./configure CFLAGS="-march=native -O2 -pipe" CXXFLAGS="-march=native -O2 -pipe" CPPFLAGS="-D_FORTIFY_SOURCE=2" LDFLAGS="-Wl,-z,relro -Wl,-z,now -s" --prefix=/usr --disable-documentation --enable-shared --enable-system-shared-lib --disable-silent-rules \
  && make install \
  && ls /usr/bin/ss-* | xargs -n1 setcap cap_net_bind_service+ep \
  && cd /tmp \
  && git clone $SIMPLE_OBFS_URL \
  && cd simple-obfs \
  && git checkout -b v$SIMPLE_OBFS_VERSION \
  && git submodule update --init --recursive \
  && ./autogen.sh \
   && ./configure CFLAGS="-march=native -O2 -pipe" CXXFLAGS="-march=native -O2 -pipe" CPPFLAGS="-D_FORTIFY_SOURCE=2" LDFLAGS="-Wl,-z,relro -Wl,-z,now -s" --disable-documentation  --disable-silent-rules \
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
