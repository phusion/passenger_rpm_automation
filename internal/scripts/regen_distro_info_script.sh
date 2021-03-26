#!/bin/bash
set -ex

cd "$(dirname "$0")/../../"

exec erb -T - internal/lib/distro_info.sh.erb > internal/lib/distro_info.sh
