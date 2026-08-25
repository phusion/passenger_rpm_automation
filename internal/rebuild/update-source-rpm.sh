#!/bin/bash
set -e
ROOTDIR=$(dirname "$0")
ROOTDIR=$(cd "$ROOTDIR/../.." && pwd)
source "$ROOTDIR/internal/lib/library.sh"

#require_args_exact 2 "$@"
require_envvar PASSENGER_VERSION "$PASSENGER_VERSION"
require_envvar PASSENGER_RPM_NAME "$PASSENGER_RPM_NAME"
require_envvar PASSENGER_RPM_RELEASE "$PASSENGER_RPM_RELEASE"
require_envvar RPM_ARCH "$RPM_ARCH"
require_envvar RPM_SOURCES_DIR "$RPM_SOURCES_DIR"
require_envvar RPM_SPECS_DIR "$RPM_SPECS_DIR"
require_envvar RPM_SRPMS_DIR "$RPM_SRPMS_DIR"
require_envvar DISTRO_ID "$DISTRO_ID"

require_envvar ROCKY_NGINX_VERSION "$ROCKY_NGINX_VERSION"
require_envvar ALMA_NGINX_VERSION "$ALMA_NGINX_VERSION"
require_envvar RHEL_NGINX_VERSION "$RHEL_NGINX_VERSION"

# Being the upstream, RHEL should always update first. (Alma is based on CentOS Stream so that might not be true, but we can't help that)
if [[ "$RHEL_NGINX_VERSION" =~ (\.[0-9]+)$ ]]; then
    SUFFIX="${BASH_REMATCH[1]}"
    if ! [[ "$ROCKY_NGINX_VERSION" == *"$SUFFIX" && ( "$ALMA_NGINX_VERSION" == *"$SUFFIX".alma.* && "$DISTRO_ID" != "el10" || "$ALMA_NGINX_VERSION" == *"$SUFFIX" && "$DISTRO_ID" == "el10" ) ]]; then
	echo "RHEL, Rocky, & Alma packages out of sync." >&2
	echo "RHEL: $RHEL_NGINX_VERSION" >&2
	echo "Alma: $ALMA_NGINX_VERSION" >&2
	echo "Rocky: $ROCKY_NGINX_VERSION" >&2
	exit 1
    fi
fi

declare spec_target_dir="${RPM_SPECS_DIR}/${DISTRO_ID}"
declare spec_target_file="${spec_target_dir}/${PASSENGER_RPM_NAME}.spec"
readarray -t OLD_PASSENGER_RPM_NAME < <(find "${RPM_SOURCES_DIR}" -name "${PASSENGER_RPM_NAME}*${DISTRO_ID}*.src.rpm" -printf '%f\n')
if [ "${#OLD_PASSENGER_RPM_NAME[@]}" -ne 1 ]; then
    echo "Too many srpm files matched: ${OLD_PASSENGER_RPM_NAME[*]}" >&2
    exit 1
fi

mkdir -p "${spec_target_dir}"

pushd "${RPM_SOURCES_DIR}" >/dev/null
header "Extracting srpm"
rpm2cpio "./${OLD_PASSENGER_RPM_NAME[0]}" | cpio -idmuv
run rm "./${OLD_PASSENGER_RPM_NAME[0]}"
popd >/dev/null

if [[ "${OLD_PASSENGER_RPM_NAME[0]}" =~ -([0-9]+)\.el ]]; then
    declare -i OLD_PASSENGER_RPM_RELEASE="${BASH_REMATCH[1]}"
else
    echo "couldn't parse release number out of: ${OLD_PASSENGER_RPM_NAME[0]}" >&2
    exit 1
fi
declare -i NEW_PASSENGER_RPM_RELEASE=$((OLD_PASSENGER_RPM_RELEASE + 1))
declare NEW_PASSENGER_SRPM_NAME="${OLD_PASSENGER_RPM_NAME/$PASSENGER_VERSION-*.el/$PASSENGER_VERSION-$NEW_PASSENGER_RPM_RELEASE.el}"

header "Updating specfile"
sed -E \
    -e "s/^(%global latest_nginx_rocky_release) .*/\1 $ROCKY_NGINX_VERSION/" \
    -e "s/^(%global latest_nginx_alma_release) .*/\1 $ALMA_NGINX_VERSION/" \
    -e "s/^(%global latest_nginx_rhel_release) .*/\1 $RHEL_NGINX_VERSION/" \
    -e "s/^(%global package_release) +[0-9]+/\1 $NEW_PASSENGER_RPM_RELEASE/" \
    -e "s/^(Requires: %\{package_name\}(%\{\?_isa\})? = %\{version\})-%\{release\}/\1-${PASSENGER_RPM_RELEASE}%{?release_dist}/g" \
    "${RPM_SOURCES_DIR}/${PASSENGER_RPM_NAME}.spec" > "${spec_target_file}"

run rpmbuild -bs --root "$HOME/rpmbuild/root-passenger-${DISTRO_ID}" "${spec_target_file}"

mkdir -p "/work/${DISTRO_ID}-${RPM_ARCH}"

run cp "${RPM_SRPMS_DIR}/${NEW_PASSENGER_SRPM_NAME}" "/work/${DISTRO_ID}-${RPM_ARCH}/"
