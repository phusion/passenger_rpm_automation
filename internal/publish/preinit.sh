#!/bin/bash
set -e
if [[ ! -e /work ]]; then
	mkdir /work
	chown app: /work
fi

export PATH=/opt/rh/ruby193/root/usr/bin:/opt/rh/ruby193/root/usr/local/bin:$PATH
# Intentionally removes python27 from LD_LIBRARY_PATH. python27 was only used for my_init.
export LD_LIBRARY_PATH=/opt/rh/ruby193/root/usr/lib64:/opt/rh/ruby193/root/usr/lib

exec "$@"
