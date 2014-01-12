FROM centos:6.4
MAINTAINER Phusion <info@phusion.nl>

RUN rpm -Uvh http://mirror.overthewire.com.au/pub/epel/6/i386/epel-release-6-8.noarch.rpm && \
	yum update -y && \
	yum install -y @development-tools fedora-packager git sudo gcc gcc-c++ ccache curl-devel openssl-devel && \
	yum install -y ruby ruby-devel rubygems rubygems-devel rubygem-rake httpd httpd-devel zlib-devel && \
	yum install -y libxml2-devel libxslt-devel sqlite-devel libev-devel pcre-devel rubygem-rack source-highlight && \
	yum install -y apr-devel apr-util-devel which GeoIP-devel gd-devel gperftools-devel perl-devel perl-ExtUtils-Embed && \
	gem install nokogiri --no-rdoc --no-ri -v 1.5.9 && \
	gem install bundler mizuho bluecloth drake --no-rdoc --no-ri && \
	groupadd --gid 2467 app && \
	adduser --uid 2467 --gid 2467 --password '#' app && \
	usermod -a -G mock app && \
	sed -i 's/Defaults    requiretty//' /etc/sudoers && \
	echo "%app ALL=NOPASSWD:ALL" >> /etc/sudoers.d/app && \
	chmod 440 /etc/sudoers.d/app && \
	sudo -u app -H rpmdev-setuptree && \
	yum clean all
