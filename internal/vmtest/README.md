This directory contains Vagrant VMs for testing RPMs under CentOS 8 and CentOS 7. The test script already tests RPMs in Docker containers, but we can't test SELinux and Systemd that way. With these VMs we can perform full end-to-end tests.

These VMs include a sample Ruby app under /app. Apache and Nginx config entries are already installed (though Apache and Nginx themselves are not installed), under the host name `foo.com`. A /etc/hosts entry is installed so that foo.com points to 127.0.0.1. If Apache/Nginx is installed and started, you can access the sample app with `curl http://foo.com`.

The passenger-testing repository is registered, but not enabled. If you want to enable it, edit /etc/yum.repos.d/passenger-testing.repo and set `enabled=1`.

These VMs mount the `passenger_rpm_automation` root directory under /vagrant. You can test locally built RPMs by copying them to some place under this directory, and installing them with `yum`.
