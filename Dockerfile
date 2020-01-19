
RUN apk upgrade --update \
  && apk add --no-cache --virtual .build-deps build-base alpine-sdk cmake linux-headers \
  udns-dev pcre-dev c-ares-dev zlib-dev libcap autoconf automake libtool wget \
  curl git gawk libev-dev libsodium-dev mbedtls-static mbedtls-dev \
  && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing libcorkipset-dev libbloom-dev \
  && cd /tmp \
  && curl -sSLO "$SHADOWSOCKS_URL" \
  && tar xfz $SHADOWSOCKS_VERSION.tar.gz \
  && cd shadowsocks-libev-$SHADOWSOCKS_VERSION \
  && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DWITH_EMBEDDED_SRC=0 \
  -DWITH_SS_REDIR=0 -DWITH_STATIC=0 -DCMAKE_VERBOSE_MAKEFILE=0 \
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

ADD sysctl.conf /etc/sysctl.conf
ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
