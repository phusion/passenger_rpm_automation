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
run yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
run curl --fail -sSLo /etc/yum.repos.d/mock.repo https://copr.fedorainfracloud.org/coprs/g/mock/mock-stable/repo/epel-7/group_mock-mock-stable-epel-7.repo
run yum update -y
run yum install -y --enablerepo centosplus --skip-broken centos-release-scl
run yum install -y --enablerepo centosplus --skip-broken createrepo \
	fedora-packager git sudo gcc gcc-c++ ccache \
	curl-devel openssl-devel python27-python \
	httpd httpd-devel zlib-devel \
	libxml2-devel libxslt-devel sqlite-devel \
	libev-devel pcre-devel rubygem-rack source-highlight \
	apr-devel apr-util-devel which GeoIP-devel \
	gd-devel gperftools-devel perl-devel perl-ExtUtils-Embed \
	centos-release bash procps-ng python2-pyroute2 \
	nodejs npm
run yum --disablerepo=\* --enablerepo=base,updates groupinstall "Development Tools"

run gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
run curl --fail -sSLo /tmp/rvm.sh https://get.rvm.io
run bash /tmp/rvm.sh stable
source /usr/local/rvm/scripts/rvm
run rvm install ruby-2.6.3
rvm use ruby-2.6.3
rvm --default ruby-2.6.3
run gem install bundler --no-document
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
