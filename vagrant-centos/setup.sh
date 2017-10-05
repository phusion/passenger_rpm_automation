#!/bin/bash
set -e
set -o pipefail
set -x

echo "exclude = kernel*" >> /etc/yum.conf

yum install -y wget nano epel-release

cp /vagrant/internal/scripts/bashrc-local.sh /etc/
if ! grep -qF bashrc-local.sh /etc/bashrc; then
	echo ". /etc/bashrc-local.sh" >> /etc/bashrc
fi
if ! grep -q 'cd /vagrant' ~vagrant/.bash_profile; then
	echo 'if tty -s; then cd /vagrant; fi' >> ~vagrant/.bash_profile
fi
