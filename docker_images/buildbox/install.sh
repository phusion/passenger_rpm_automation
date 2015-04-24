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

header "Creating users"
run groupadd --gid 2467 app
run adduser --uid 2467 --gid 2467 --password '#' app

header "Installing dependencies"
run rpm -Uvh http://mirror.overthewire.com.au/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
run yum update -y
run yum install -y --enablerepo centosplus --skip-broken centos-release-SCL
run yum install -y --enablerepo centosplus --skip-broken createrepo \
	@development-tools fedora-packager git sudo gcc gcc-c++ ccache \
	curl-devel openssl-devel python27-python \
	httpd httpd-devel zlib-devel \
	libxml2-devel libxslt-devel sqlite-devel \
	libev-devel pcre-devel rubygem-rack source-highlight \
	apr-devel apr-util-devel which GeoIP-devel \
	gd-devel gperftools-devel perl-devel perl-ExtUtils-Embed \
	nodejs010-nodejs nodejs010-npm ruby193-ruby ruby193-ruby-devel
source /opt/rh/ruby193/enable
export PATH=/opt/rh/ruby193/root/usr/local/bin:$PATH
run gem update --system --no-rdoc --no-ri
run gem install bundler --no-rdoc --no-ri -v 1.9.2
run env BUNDLE_GEMFILE=/pra_build/Gemfile bundle install -j 4

header "Miscellaneous"
run sed -i 's/Defaults    requiretty//' /etc/sudoers
run cp /pra_build/sudoers.conf /etc/sudoers.d/app
run chmod 440 /etc/sudoers.d/app

run usermod -a -G mock app
run sudo -u app -H rpmdev-setuptree

run mkdir -p /etc/container_environment
run cp /pra_build/my_init_python /sbin/my_init_python
run cp /pra_build/site-defaults.cfg /etc/mock/site-defaults.cfg

header "Cleaning up"
run yum clean all
run rm -rf /pra_build
