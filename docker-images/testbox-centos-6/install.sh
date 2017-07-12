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
run yum install -y --enablerepo centosplus centos-release-scl
run yum install -y --enablerepo centosplus \
	gcc gcc-c++ ccache python27-python \
	ruby ruby-devel rubygems rubygem-rack rubygem-rake perl git tar which \
	httpd httpd-devel httpd-tools zlib-devel sqlite-devel libcurl-devel \
	GeoIP gd libxslt openssl-devel
run gem install bundler -v 1.10.6 --no-rdoc --no-ri
run env BUNDLE_GEMFILE=/pra_build/Gemfile bundle install

header "Installing more dependencies"
run curl --silent --location https://rpm.nodesource.com/setup_6.x | bash -
run curl https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo
run yum clean all
run yum install -y nodejs yarn

header "Miscellaneous"
run mkdir /etc/container_environment
run mkdir /pra
run cp /pra_build/Gemfile* /pra/
run cp /pra_build/my_init_python /sbin/my_init_python

header "Cleaning up"
run yum clean all
run rm -rf /pra_build
