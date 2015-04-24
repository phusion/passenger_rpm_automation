#!/bin/bash
set -e
export PATH=/opt/rh/ruby193/root/usr/bin:/opt/rh/ruby193/root/usr/local/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/ruby193/root/usr/lib64:/opt/rh/ruby193/root/usr/lib
exec "$@"
