#!/bin/bash
set -e
if [[ ! -e /work ]]; then
	mkdir /work
	chown app: /work
fi

source /usr/local/rvm/scripts/rvm
rvm use 3.1.2

exec "$@"
