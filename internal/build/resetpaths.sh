#!/bin/bash
set -e
source /usr/local/rvm/scripts/rvm
rvm use 2.2.2
exec "$@"
