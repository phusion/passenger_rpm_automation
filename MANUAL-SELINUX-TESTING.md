# Manual SELinux testing

The Passenger RPM contains an SELinux policy. We currently have no automated tests for this because SELinux does not work inside Docker containers. So here is the procedure for manually testing SELinux. All commands must be run as a normal user unless otherwise indicated.

## Preparation

### 1. Enable SELinux and set it to enforcing mode

 1. Edit /etc/selinux/config. Make sure `SELINUX` is set to `enforcing`.
 2. Run `sestatus`. Check that SELinux is enabled and set to enforcing. If it isn't, reboot.
 3. If you rebooted, run `sestatus` again. Check that SELinux is enabled and set to enforcing.

### 2. Ensure that there is a normal user account

This account can have any name. It must have sudo access. Throughout this document we will refer to this user as '$USER'.

### 3. Create a test app

~~~bash
sudo mkdir -p /app /app/public
echo 'run lambda { |env| [200, {}, ["ok\n"]] }' | sudo tee /app/config.ru
sudo chown -R $USER: /app
sudo chcon -R -t httpd_sys_content_t /app
~~~

### 4. Create an /etc/hosts entry for rack.test

Edit /etc/hosts. Ensure that it contains:

    127.0.0.1 rack.test

### 5. Install Apache

Run:

    sudo yum install httpd

### 6. Create a virtual host

On CentOS/RHEL 6:

~~~bash
cat <<EOF | sudo tee /etc/httpd/conf.d/app.conf
<VirtualHost *:80>
  ServerName rack.test
  DocumentRoot /app/public
</VirtualHost>
EOF

cat <<EOF | sudo tee /etc/nginx/conf.d/app.conf
server {
  listen 80;
  server_name rack.test;
  root /app/public;
  passenger_enabled on;
}
EOF
~~~

On CentOS/RHEL 7:

~~~bash
cat <<EOF | sudo tee /etc/httpd/conf.d/app.conf
<VirtualHost *:80>
  ServerName rack.test
  DocumentRoot /app/public
  <Directory /app/public>
    Allow from all
    Options -MultiViews
    # Uncomment this if you're on Apache > 2.4:
    Require all granted
  </Directory>
</VirtualHost>
EOF

cat <<EOF | sudo tee /etc/nginx/conf.d/app.conf
server {
  listen 80;
  server_name rack.test;
  root /app/public;
  passenger_enabled on;
}
EOF
~~~

## Test 1: installing RPMs with SELinux turned on

 1. (Re)install the `passenger` RPM.
 2. Run `sudo semodule -l | grep passenger`. Check that the Passenger module appears in the list, and that its version equals the version specified in the `policy_module(.,.)` statement in `specs/passenger/passenger.te`.
 3. Run `ls -Z /usr/lib64/passenger/support-binaries/PassengerAgent`. Check that it has the `passenger_exec_t` type.

## Test 2: Apache + Passenger core

 1. Ensure the `mod_passenger` RPM is installed.
 2. Empty the Apache error log: `sudo sh -c 'echo -n > /var/log/httpd/error_log'`
 3. Ensure Nginx is stopped, e.g.: `sudo service nginx stop`
 4. Ensure Apache is started, e.g.: `sudo service httpd start`
 5. Run `ps auxwZ | grep 'Passenger core'`. Check that it has the `unconfined_t` domain.
 6. Run `sudo cat /var/log/httpd/error_log`. Check that there are no error messages.

## Test 3: Nginx + Passenger core

 1. Ensure that our `nginx` RPM is installed (and not the one by the distribution).
 2. Empty the Nginx error log: `sudo sh -c 'echo -n > /var/log/nginx/error_log'`
 3. Ensure Apache is stopped, e.g.: `sudo service httpd stop`
 4. Ensure Nginx is started, e.g.: `sudo service nginx start`
 5. Run `ps auxwZ | grep 'Passenger core'`. Check that it has the `unconfined_t` domain.
 6. Run `sudo cat /var/log/nginx/error_log`. Check that there are no error messages.

## Test 4: apps via Apache

 1. Ensure the `mod_passenger` RPM is installed.
 2. Ensure Nginx is stopped, e.g.: `sudo service nginx stop`
 3. Ensure Apache is started, e.g.: `sudo service httpd start`
 4. Access the test app: `curl http://rack.test`. Check that it prints `ok`.
 5. Run `ps auxwZ | grep RubyApp`. Check that all RubyApp processes have the `unconfined_t` domain.

## Test 5: apps via Nginx

 1. Ensure that our `nginx` RPM is installed (and not the one by the distribution).
 2. Ensure Apache is stopped, e.g.: `sudo service httpd stop`
 3. Ensure Nginx is started, e.g.: `sudo service nginx start`
 4. Access the test app: `curl http://rack.test`. Check that it prints `ok`.
 5. Run `ps auxwZ | grep RubyApp`. Check that all RubyApp processes have the `unconfined_t` domain.
