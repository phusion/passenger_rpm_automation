#!/bin/bash
set -e

function header()
{
	echo
	echo "----- $@ -----"
}

function run()
{
	echo "+ $@"
	"$@"
}

export HOME=/root
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

header "Creating users"
run groupadd --gid 2467 app
run adduser --uid 2467 --gid 2467 --password '#' app

header "Installing dependencies"
run dnf install -y epel-release
run dnf update -y
run dnf install -y --skip-broken \
	git sudo gcc gcc-c++ ccache \
	curl-devel openssl-devel \
	httpd httpd-devel zlib-devel ca-certificates \
	libxml2-devel libxslt-devel sqlite-devel \
	libev-devel pcre-devel source-highlight \
	apr-devel apr-util-devel which \
	gd-devel gperftools-devel perl-devel perl-ExtUtils-Embed \
	centos-release bash procps-ng \
	nodejs npm createrepo mock rpmdevtools \
	ruby ruby-devel rubygem-bundler
run dnf --disablerepo=\* --enablerepo=baseos groupinstall -y "Development Tools"

run env BUNDLE_GEMFILE=/pra_build/Gemfile bundle install -j 4

header "Miscellaneous"
run sed -i 's/Defaults    requiretty//' /etc/sudoers
run cp /pra_build/sudoers.conf /etc/sudoers.d/app
run chmod 440 /etc/sudoers.d/app
sed -ie 's/\(account     required      pam_unix.so\)/\1 broken_shadow/g' /etc/pam.d/system-auth
run usermod -a -G mock app
run sudo -u app -H rpmdev-setuptree

run mkdir -p /etc/container_environment
run cp /pra_build/my_init_python /sbin/my_init_python
run cp /pra_build/site-defaults.cfg /etc/mock/site-defaults.cfg

header "Cleaning up"
run dnf clean all
run rm -rf /pra_build
