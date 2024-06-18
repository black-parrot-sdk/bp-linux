#!/bin/sh

case "$1" in
    'start')
        echo "[bsg] Hello from rootFS!"
        ;;
    'stop')
        echo "[bsg] Goodbye from rootFS!"
        ;;
esac
exit 0

