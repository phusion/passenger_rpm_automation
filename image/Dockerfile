FROM centos:centos6
MAINTAINER Phusion <info@phusion.nl>

RUN rpm -Uvh http://mirror.overthewire.com.au/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm && \
	yum update -y && \
	yum install -y --skip-broken --enablerepo centosplus centos-release-SCL createrepo && \
	yum install -y --skip-broken --enablerepo centosplus @development-tools fedora-packager git sudo gcc gcc-c++ ccache && \
	yum install -y --skip-broken --enablerepo centosplus curl-devel openssl-devel python27-python && \
	yum install -y --skip-broken --enablerepo centosplus ruby ruby-devel rubygems rubygems-devel rubygem-rake && \
	yum install -y --skip-broken --enablerepo centosplus httpd httpd-devel zlib-devel && \
	yum install -y --skip-broken --enablerepo centosplus libxml2-devel libxslt-devel sqlite-devel && \
	yum install -y --skip-broken --enablerepo centosplus libev-devel pcre-devel rubygem-rack source-highlight && \
	yum install -y --skip-broken --enablerepo centosplus apr-devel apr-util-devel which GeoIP-devel && \
	yum install -y --skip-broken --enablerepo centosplus gd-devel gperftools-devel perl-devel perl-ExtUtils-Embed && \
	yum install -y --skip-broken --enablerepo centosplus nodejs010-nodejs nodejs010-npm && \
	gem install nokogiri --no-rdoc --no-ri -v 1.5.9 && \
	gem install bundler mizuho bluecloth drake --no-rdoc --no-ri && \
	git clone https://github.com/phusion/phusion-server-tools.git /tools && \
	groupadd --gid 2467 app && \
	adduser --uid 2467 --gid 2467 --password '#' app && \
	usermod -a -G mock app && \
	sed -i 's/Defaults    requiretty//' /etc/sudoers && \
	echo "%app ALL=NOPASSWD:ALL" >> /etc/sudoers.d/app && \
	chmod 440 /etc/sudoers.d/app && \
	sudo -u app -H rpmdev-setuptree && \
	yum clean all && \
	mkdir -p /etc/container_environment /etc/workaround-docker-2267 && \
	ln -s /etc/workaround-docker-2267 /cte
ADD amazon2014-i386.cfg /etc/mock/amazon2014-i386.cfg
ADD amazon2014-x86_64.cfg /etc/mock/amazon2014-x86_64.cfg
ADD RPM-GPG-KEY-amazon-ga /etc/pki/rpm-gpg/RPM-GPG-KEY-amazon-ga
ADD site-defaults.cfg /etc/mock/site-defaults.cfg
ADD Gemfile /home/app/
ADD Gemfile.lock /home/app/
RUN mkdir /bundle && \
	chown app: /bundle /home/app/Gemfile* && \
	sudo -u app -H bash -c 'cd /home/app && bundle install --path /bundle'
