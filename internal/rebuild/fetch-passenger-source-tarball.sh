#!/bin/bash
# Usage: fetch-passenger-orig-tarball.sh <OUTPUT> <RELEASEVER>
# Fetches the Passenger RPM source tarball from a Passenger repo.
#
# Required environment variables:
#
#   PASSENGER_VERSION
#   PASSENGER_TARBALL
#   PASSENGER_RPM_NAME

set -e
ROOTDIR=$(dirname "$0")
ROOTDIR=$(cd "$ROOTDIR/../.." && pwd)
source "$ROOTDIR/internal/lib/library.sh"

require_args_exact 2 "$@"
require_envvar PASSENGER_VERSION "$PASSENGER_VERSION"
require_envvar PASSENGER_TARBALL "$PASSENGER_TARBALL"
require_envvar PASSENGER_RPM_NAME "$PASSENGER_RPM_NAME"

RELEASEVER="${2#el}"

mkdir -p /work/passenger.repos.d
if [ ! -f /work/passenger.repos.d/el.repo ]; then
    curl --fail -sSLo /work/passenger.repos.d/el.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo
fi

header "Fetching Passenger official srpm"

SRCPKG=$(dnf -vy repoquery \
    --setopt=reposdir=/work/passenger.repos.d \
    --releasever="$RELEASEVER" \
    --show-duplicates \
    --arch=src \
    "$PASSENGER_RPM_NAME" | grep "$PASSENGER_VERSION" | rev | cut -d. -f2- | rev)

cd /work

run dnf -vy download \
    --source \
    --setopt=reposdir=/work/passenger.repos.d \
    --releasever="$RELEASEVER" \
    "$SRCPKG"

header "Putting srpm in place"
mv ./*.src.rpm  "$1"
