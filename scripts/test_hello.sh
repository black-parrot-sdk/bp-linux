#!/bin/sh

echo "[bsg] Running test_hello.sh with argument $1"

case "$1" in
    'start')
        echo "[bsg] Hello, welcome to your shell"
        ;;
    'stop')
        echo "[bsg] test_hello.sh stop -> null"
        ;;
esac
exit 0

