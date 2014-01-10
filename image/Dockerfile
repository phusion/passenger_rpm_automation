FROM centos:6.4
MAINTAINER Phusion <info@phusion.nl>

RUN rpm -Uvh http://mirror.overthewire.com.au/pub/epel/6/i386/epel-release-6-8.noarch.rpm && \
	yum update -y && \
	yum install -y @development-tools fedora-packager git sudo gcc gcc-c++ ccache curl-devel openssl-devel zlib-devel && \
	yum install -y ruby ruby-devel rubygems rubygems-devel rubygem-rake httpd httpd-devel apr-devel apr-util-devel && \
	yum install -y libxml2-devel libxslt-devel sqlite-devel libev-devel pcre-devel rubygem-rack source-highlight which && \
	gem install nokogiri --no-rdoc --no-ri -v 1.5.9 && \
	gem install mizuho bluecloth --no-rdoc --no-ri && \
	groupadd --gid 9870 app && \
	adduser --uid 9870 --gid 9870 --password '#' app && \
	usermod -a -G mock app && \
	sed -i 's/Defaults    requiretty//' /etc/sudoers && \
	echo "%app ALL=NOPASSWD:ALL" >> /etc/sudoers.d/app && \
	chmod 440 /etc/sudoers.d/app && \
	sudo -u app -H rpmdev-setuptree && \
	yum clean all
