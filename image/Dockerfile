FROM centos:6.4
MAINTAINER Phusion <info@phusion.nl>

RUN rpm -Uvh http://mirror.overthewire.com.au/pub/epel/6/i386/epel-release-6-8.noarch.rpm && \
	yum update -y && \
	yum install -y @development-tools fedora-packager git sudo && \
	groupadd --gid 9999 app && \
	adduser --uid 9999 --gid 9999 --password '#' app && \
	usermod -a -G mock app && \
	su -c 'env HOME=/home/app rpmdev-setuptree' app
