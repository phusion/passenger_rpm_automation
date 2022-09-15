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

header "deleting conflicting user & group"
run userdel systemd-coredump
run groupdel render

header "Creating users"
run groupadd --gid 2467 app
run adduser --uid 2467 --gid 2467 --password '#' app

header "Installing dependencies"
run dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
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
	nodejs npm createrepo mock rpmdevtools
run dnf --disablerepo=\* --enablerepo=baseos groupinstall -y "Development Tools"

KEYSERVERS=(
	hkp://keyserver.pgp.com
	hkp://keys.gnupg.net
	ha.pool.sks-keyservers.net
	hkp://p80.pool.sks-keyservers.net:80
	hkp://ipv4.pool.sks-keyservers.net
	keyserver.ubuntu.com
	hkp://keyserver.ubuntu.com:80
	hkp://pgp.mit.edu
	pgp.mit.edu
	-end-
)

KEYS=(
	409B6B1796C275462A1703113804BB82D39DC0E3
	7D2BAF1CF37B13E2069D6956105BD0E739499BDB
)

# We've had too many problems with keyservers. No matter which one we pick,
# it will fail some of the time for some people. So just try a whole bunch
# of them.
for KEY in "${KEYS[@]}"; do
	for KEYSERVER in "${KEYSERVERS[@]}"; do
		if [[ "$KEYSERVER" = -end- ]]; then
			echo 'ERROR: exhausted list of keyservers' >&2
			exit 1
		else
			echo "+ gpg --keyserver $KEYSERVER --recv-keys ${KEY}"
			gpg --keyserver "$KEYSERVER" --recv-keys "${KEY}" && break || echo 'Trying another keyserver...'
		fi
	done
done

run curl --fail -sSLo /tmp/rvm.sh https://get.rvm.io
run bash /tmp/rvm.sh stable
source /usr/local/rvm/scripts/rvm
RUBY=3.1.2
run rvm install ruby-$RUBY || cat /usr/local/rvm/log/*_ruby-$RUBY/make.log
rvm use ruby-$RUBY
rvm --default ruby-$RUBY
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
run dnf clean all
run rm -rf /pra_build
