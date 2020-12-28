#!/bin/bash
set -ex

echo "exclude = kernel*" >> /etc/yum.conf

yum install -y wget nano epel-release dbus setroubleshoot-server selinux-policy-devel ack pygpgme
service messagebus start

cp /vagrant/internal/vmtest/centos7/passenger-testing.repo /etc/yum.repos.d/

mkdir -p /app
mkdir -p /app/public
mkdir -p /app/tmp
mkdir -p /app/log
if [[ ! -e /app/config.ru ]]; then
	cp /vagrant/internal/vmtest/centos7/config.ru /app/
fi
chown vagrant: /app /app/public /app/tmp /app/log /app/config.ru
chcon -t httpd_sys_content_t -R /app

mkdir -p /etc/httpd/conf.d
mkdir -p /etc/nginx/conf.d
if [[ ! -e /etc/httpd/conf.d/app.conf ]]; then
	cp /vagrant/internal/vmtest/centos7/app-apache.conf /etc/httpd/conf.d/app.conf
fi
if [[ ! -e /etc/nginx/conf.d/app.conf ]]; then
	cp /vagrant/internal/vmtest/centos7/app-nginx.conf /etc/nginx/conf.d/app.conf
fi

cp /vagrant/internal/scripts/bashrc-local.sh /etc/
if ! grep -qF bashrc-local.sh /etc/bashrc; then
	echo ". /etc/bashrc-local.sh" >> /etc/bashrc
fi
if ! grep -q 'cd /vagrant' ~vagrant/.bash_profile; then
	echo 'if tty -s; then cd /vagrant; fi' >> ~vagrant/.bash_profile
fi

if ! grep -qF foo.com /etc/hosts; then
	echo "127.0.0.1 foo.com" >> /etc/hosts
fi

sed -i 's/^SELINUX=permissive$/SELINUX=enforcing/' /etc/selinux/config
setenforce 1
