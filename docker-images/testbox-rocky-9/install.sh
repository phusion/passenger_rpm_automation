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

run dnf install -y 'dnf-command(config-manager)'
run dnf config-manager --set-enabled crb
run dnf install -y epel-release yum-utils

run dnf groupinstall -y "Development Tools" --exclude asciidoc
run dnf install -y alternatives \
	ruby ruby-devel rubygems rubygem-rake \
	perl git tar which python3 \
	httpd httpd-devel httpd-tools zlib-devel sqlite-devel curl-devel \
	libxslt openssl-devel \
	rubygem-rack ccache
run gem install bundler --no-document
run gem install bundler -v 1.17.3 --no-document
run env BUNDLE_GEMFILE=/pra_build/Gemfile bundle install

header "Installing node related dependencies"
run dnf install -y nodejs

header "Miscellaneous"
run ln -s /usr/bin/python3.9 /sbin/my_init_python
run alternatives --install /usr/bin/python python /usr/bin/python3 1

run mkdir /etc/container_environment
run mkdir /pra
run cp /pra_build/Gemfile* /pra/

header "Cleaning up"
run dnf clean all
run rm -rf /pra_build
