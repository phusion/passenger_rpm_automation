FROM centos:6.4
MAINTAINER Phusion <info@phusion.nl>

RUN rpm -Uvh http://mirror.overthewire.com.au/pub/epel/6/i386/epel-release-6-8.noarch.rpm && \
	yum update -y && \
	yum install -y @development-tools fedora-packager git sudo gcc gcc-c++ curl-devel openssl-devel zlib-devel && \
	yum install -y ruby ruby-devel rubygems rubygem-rake httpd httpd-devel apr-devel apr-util-devel && \
	groupadd --gid 9999 app && \
	adduser --uid 9999 --gid 9999 --password '#' app && \
	usermod -a -G mock app && \
	sed -i 's/Defaults    requiretty//' /etc/sudoers && \
	sudo -u app -H rpmdev-setuptree && \
	yum clean all
