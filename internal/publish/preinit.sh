#!/bin/bash
set -e
if [[ ! -e /work ]]; then
	mkdir /work
	chown app: /work
fi

source /usr/local/rvm/scripts/rvm
rvm use 2.2.2

# Remove python27 from LD_LIBRARY_PATH. python27 was only used for my_init.
unset LD_LIBRARY_PATH

exec "$@"
