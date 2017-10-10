#!/bin/bash

set -e

echo "PS1='\\u@testbox:\\w\\\$ '" >> /root/.bashrc

# Make setuser available in PATH
cp /system/internal/scripts/setuser /sbin/

export COMPILE_CONCURRENCY=${COMPILE_CONCURRENCY:-2}
export PATH=/usr/lib64/ccache:$PATH
export CCACHE_DIR=/cache/test-$DISTRIBUTION/ccache
export CCACHE_COMPRESS=1
export CCACHE_COMPRESS_LEVEL=3
export PASSENGER_TEST_NODE_MODULES_DIR=/tmp/passenger/node_modules

if ! /system/internal/test/test.sh "$@"; then
	echo
	echo "---------------------------------------------"
	if $DEBUG_CONSOLE_ON_FAIL; then
		echo "*** Test failed. A debugging console will now be opened for you."
		echo
		if [[ -e /tmp/passenger ]]; then
			cd /tmp/passenger
		fi
		bash -l
	elif $JENKINS; then
		echo "*** Test failed. To debug this problem, please read https://github.com/phusion/passenger_rpm_automation#debugging-a-packaging-test-failure"
	else
		echo "*** Test failed. If you want a debugging console to be launched, re-run the test with -D."
	fi
	exit 1
fi
