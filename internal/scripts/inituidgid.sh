#!/bin/bash
# Changes the 'app' user's UID and GID to the values specified
# in $APP_UID and $APP_GID.
set -e
set -o pipefail

# Hack to make the Passenger RPM packaging tests on our Jenkins infrastructure work. Jenkins has UID 999 and GID 998.

# There is a user saslauth and group ssh_keys in the CentOS 7 container with these UID/GID, but we don't need them so we just delete them.
if grep -q 'release 7' /etc/redhat-release; then
	userdel saslauth
	groupdel ssh_keys
fi

# There is a user systemd-coredump and group render in the CentOS 8 container with these UID/GID, but we don't need them so we just delete them.
if grep -q 'release 8' /etc/redhat-release; then
	userdel systemd-coredump
	groupdel render
fi

# There is a user pesign and group input in the CentOS 9 container with these UID/GID, but we don't need them so we just delete them.
if grep -q 'release 9' /etc/redhat-release; then
	userdel pesign
	groupdel input
fi

if [[ "$APP_UID" -lt 1024 ]]; then
	if awk -F: '{ print $3 }' < /etc/passwd | grep -q "^${APP_UID}$"; then
		echo "ERROR: you can only run this script with a user whose UID is at least 1024, or whose UID does not already exist in the Docker container. Current UID: $APP_UID"
		exit 1
	fi
fi
if [[ "$APP_GID" -lt 1024 ]]; then
	if awk -F: '{ print $3 }' < /etc/group | grep -q "^${APP_GID}$"; then
		echo "ERROR: you can only run this script with a user whose GID is at least 1024, or whose GID does not already exist in the Docker container. Current GID: $APP_GID"
		exit 1
	fi
fi

chown -R "$APP_UID:$APP_GID" /home/app
groupmod -g "$APP_GID" app
usermod -u "$APP_UID" -g "$APP_GID" app

# There's something strange with either Docker or the kernel, so that
# the 'app' user cannot access its home directory even after a proper
# chown/chmod. We work around it like this.
mv /home/app /home/app2
cp -dpR /home/app2 /home/app
rm -rf /home/app2

if [[ $# -gt 0 ]]; then
	exec "$@"
fi
