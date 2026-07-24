#!/bin/bash
set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/internal/lib/library.sh"

run mkdir -p /cache/mock_lib
run mkdir -p /cache/mock_cache
run chown root:mock /cache/mock_cache
run chown root:mock /cache/mock_lib
run rm -rf /var/lib/mock
run rm -rf /var/cache/mock
run ln -s /cache/mock_lib /var/lib/mock
run ln -s /cache/mock_cache /var/cache/mock

# Disable caching in the Passenger build system
export CACHING=false

exec "$@"
