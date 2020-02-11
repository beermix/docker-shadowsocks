#!/bin/bash

SHADOWSOCKS_PORT=${SHADOWSOCKS_PORT:-"443"}
SHADOWSOCKS_PASSWORD=${SHADOWSOCKS_PASSWORD:-"asdewq123"}
SHADOWSOCKS_CRYPTO=${SHADOWSOCKS_CRYPTO:-"chacha20"}
OBFS_PORT=${OBFS_PORT:-"993"}
OBFS_PROTOCOL=${OBFS_PROTOCOL:-"tls"}
KCPTUN_PORT=${KCPTUN_PORT:-"53"}
KCPTUN_MODE=${KCPTUN_MODE:-"fast"}
KCPTUN_KEY=${KCPTUN_KEY:-"asdewq123"}
KCPTUN_CRYPTO=${KCPTUN_CRYPTO:-"chacha20"}

if [ -z $KCPTUN_OVER_OBFS ]; then
  KCPTUN_TARGET_PORT=$SHADOWSOCKS_PORT
else
  KCPTUN_TARGET_PORT=$OBFS_PORT
fi

echo "Starting Shadowsocks Server on port $SHADOWSOCKS_PORT with crypto $SHADOWSOCKS_CRYPTO..."
ss-server -s 0.0.0.0 -p "$SHADOWSOCKS_PORT" -k "$SHADOWSOCKS_PASSWORD" -m "$SHADOWSOCKS_CRYPTO" --fast-open -u --reuse-port -d 1.0.0.1 &

echo "Starting Obfs Server on port $OBFS_PORT over $SHADOWSOCKS_PORT with protocol $OBFS_PROTOCOL..."
obfs-server -r "127.0.0.1:$SHADOWSOCKS_PORT" -p "$OBFS_PORT" --obfs "$OBFS_PROTOCOL" --fast-open

echo "Starting Kcptun Server on udp port $KCPTUN_PORT over $KCPTUN_TARGET_PORT with crypto $KCPTUN_CRYPTO..."
kcptun-server --target "127.0.0.1:$KCPTUN_TARGET_PORT" --listen ":$KCPTUN_PORT" --mode "$KCPTUN_MODE" --key "$KCPTUN_KEY" --crypt "$KCPTUN_CRYPTO" --mtu 1350 --sndwnd 1024 --rcvwnd 1024
