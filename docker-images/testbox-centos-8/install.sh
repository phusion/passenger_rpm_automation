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
run yum install -y --enablerepo centosplus epel-release centos-release-scl \
	yum-utils deltarpm
run yum groupinstall -y "Development Tools"
run yum install -y --enablerepo centosplus \
	ruby ruby-devel rubygems rubygem-rack rubygem-rake nodejs npm \
	ccache perl git tar which \
	httpd httpd-devel httpd-tools zlib-devel sqlite-devel curl-devel \
	GeoIP gd libxslt openssl-devel
run gem install bundler -v 1.10.6 --no-rdoc --no-ri
run env BUNDLE_GEMFILE=/pra_build/Gemfile bundle install

# Enable CentOS CR: https://wiki.centos.org/AdditionalResources/Repositories/CR
# Comment out the following two lines if you see any broken packages
# For more information, see README.md section
# "Dealing with broken packages: enabling/disabling CR".
#run yum update -y
#run yum-config-manager --enable cr

header "Installing more dependencies"
run curl https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo
run yum install -y nodejs yarn

header "Miscellaneous"
run ln -s /usr/bin/python2.7 /sbin/my_init_python
run mkdir /etc/container_environment
run mkdir /pra
run cp /pra_build/Gemfile* /pra/

header "Cleaning up"
run yum clean all
run rm -rf /pra_build
