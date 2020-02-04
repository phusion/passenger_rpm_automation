#!/bin/bash
set -e
set -o pipefail
set -x

export DEBIAN_FRONTEND=noninteractive

if [[ ! -e /usr/bin/docker ]]; then
	apt-get update
	apt-get install -y apt-transport-https ca-certificates curl software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
	add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	apt-get update
	apt-get install -y docker-ce
fi
usermod -aG docker vagrant
cp /vagrant/internal/scripts/bashrc-local.sh /etc/
if ! grep -qF bashrc-local.sh /etc/bash.bashrc; then
	echo ". /etc/bashrc-local.sh" >> /etc/bashrc
fi
if ! grep -q 'cd /vagrant' ~vagrant/.profile; then
	echo 'if tty -s; then cd /vagrant; fi' >> ~vagrant/.profile
fi

mkdir -p /home/vagrant/cache
mkdir -p /home/vagrant/work
mkdir -p /home/vagrant/output
chown vagrant: /home/vagrant/cache
chown vagrant: /home/vagrant/work
chown vagrant: /home/vagrant/output
