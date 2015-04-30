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
run yum install -y --enablerepo centosplus centos-release-SCL
run yum install -y --enablerepo centosplus \
	@development-tools ccache \
	python27-python nodejs010-nodejs nodejs010-npm \
	ruby ruby-devel rubygems rubygem-rack rubygem-rake perl git tar which \
	httpd httpd-devel httpd-tools zlib-devel sqlite-devel curl-devel \
	GeoIP gd libxslt
run gem install bundler -v 1.9.2 --no-rdoc --no-ri
run env BUNDLE_GEMFILE=/pra_build/Gemfile bundle install

header "Miscellaneous"
run mkdir /etc/container_environment
run mkdir /pra
run cp /pra_build/Gemfile* /pra/
run cp /pra_build/my_init_python /sbin/my_init_python
run cp /pra_build/activate_passenger_rpm_automation_test /etc/activate_passenger_rpm_automation_test

header "Cleaning up"
run yum clean all
run rm -rf /pra_build
