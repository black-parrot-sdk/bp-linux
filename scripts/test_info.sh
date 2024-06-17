#!/bin/sh

echo "[bsg] running test.sh"
echo "[bsg] running /proc/cpuinfo"
cat /proc/cpuinfo
echo "[bsg] running /proc/meminfo"
cat /proc/meminfo
echo "[bsg] powering off"
poweroff

