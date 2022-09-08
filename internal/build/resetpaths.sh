#!/bin/bash
set -e
source /usr/local/rvm/scripts/rvm
rvm use 3.1.2
exec "$@"
