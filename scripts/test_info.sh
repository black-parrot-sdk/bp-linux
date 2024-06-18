#!/bin/sh

echo "[bsg] Running test_info.sh with argument $1"

case "$1" in
    'start')
        echo "[bsg] Getting /proc/cpuinfo"
        cat /proc/cpuinfo
        echo "[bsg] Getting /proc/meminfo"
        cat /proc/meminfo
        ;;
    'stop')
        echo "[bsg] test_info.sh stop -> null"
        ;;
esac
exit 0

