#!/bin/sh

echo "[bsg] Running test_shutdown.sh with argument $1"

case "$1" in
    'start')
        echo "[bsg] About to poweroff"
        poweroff
        ;;
    'stop')
        echo "[bsg] test_shutdown.sh stop -> null"
        ;;
esac
exit 0

