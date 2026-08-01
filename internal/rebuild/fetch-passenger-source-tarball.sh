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

if [ "$PASSENGER_RPM_NAME" != "passenger-enterprise" ]; then
    REPOS_DIR="/work/passenger.repos.d"
    REPO_URL="https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo"
else
    REPOS_DIR="/work/passenger-enterprise.repos.d"
    REPO_URL="https://www.phusionpassenger.com/enterprise_yum/el-passenger-enterprise.repo"

    if [ -z "$PASSENGER_ENTERPRISE_DOWNLOAD_TOKEN" ]; then
	echo "Please set PASSENGER_ENTERPRISE_DOWNLOAD_TOKEN env var when rebuilding enterprise packages" >&2
	exit 1
    else
	echo "machine www.phusionpassenger.com login download password $PASSENGER_ENTERPRISE_DOWNLOAD_TOKEN" > "$HOME/.netrc"
    fi
fi

mkdir -p "$REPOS_DIR"
if [ ! -f "$REPOS_DIR/el.repo" ]; then
    run curl --netrc-optional -fsSLo "$REPOS_DIR/el.repo" "$REPO_URL"
fi

header "Fetching Passenger official srpm"

SRCPKG=$(dnf -vy repoquery \
    --setopt=reposdir="$REPOS_DIR" \
    --releasever="$RELEASEVER" \
    --show-duplicates \
    --arch=src \
    "$PASSENGER_RPM_NAME" | grep "$PASSENGER_VERSION" | rev | cut -d. -f2- | rev | sort -Vr | head -1)

cd /work

run dnf -vy download \
    --source \
    --setopt=reposdir="$REPOS_DIR" \
    --releasever="$RELEASEVER" \
    "$SRCPKG"

header "Putting srpm in place"
mv ./*.src.rpm  "$1"
