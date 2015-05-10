#!/bin/bash
set -e
set -o pipefail
set -x

echo "exclude = kernel*" >> /etc/yum.conf

yum install -y wget nano epel-release device-mapper-event-libs
if [[ ! -e /usr/bin/docker ]]; then
	wget -qO- https://get.docker.com/ | bash
fi
if ! grep -q '^docker:' /etc/group; then
	groupadd docker
fi
usermod -aG docker vagrant
service docker start
systemctl enable docker.service

cp /vagrant/internal/scripts/bashrc-local.sh /etc/
if ! grep -qF bashrc-local.sh /etc/bashrc; then
	echo ". /etc/bashrc-local.sh" >> /etc/bashrc
fi
if ! grep -q 'cd /vagrant' ~vagrant/.bash_profile; then
	echo 'if tty -s; then cd /vagrant; fi' >> ~vagrant/.bash_profile
fi

mkdir -p /home/vagrant/cache
mkdir -p /home/vagrant/work
mkdir -p /home/vagrant/output
chown vagrant: /home/vagrant/cache
chown vagrant: /home/vagrant/work
chown vagrant: /home/vagrant/output
