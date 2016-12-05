# Manual SELinux testing

The Passenger RPM contains an SELinux policy. We currently have no automated tests for this because SELinux does not work inside Docker containers. So here is the procedure for manually testing SELinux. All commands must be run as a normal user unless otherwise indicated.

## Preparation

### 1. Ensure that there is a normal user account

This account can have any name. It must have sudo access. Throughout this document we will refer to this user as '$USER'.

### 2. Create a test app

~~~bash
sudo mkdir -p /app /app/public
echo 'run lambda { |env| [200, {}, ["ok\n"]] }' | sudo tee /app/config.ru
sudo chown -R $USER: /app
sudo chcon -R -t httpd_sys_content_t /app
~~~

### 3. Create an /etc/hosts entry for rack.test

Edit /etc/hosts. Ensure that it contains:

    127.0.0.1 rack.test

### 3. Install Apache

Run:

    sudo yum install httpd

### 4. Create a virtual host

On CentOS/RHEL 6:

~~~bash
cat <<EOF | sudo tee /etc/httpd/conf.d/app.conf
<VirtualHost *:80>
  ServerName rack.test
  DocumentRoot /app/public
</VirtualHost>
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
~~~

## Test 1: installing RPMs with SELinux turned on

 1. Run `sestatus`. Check that SELinux is enabled and set to enforcing.
 2. (Re)install the `passenger` RPM.
 3. Run `sudo semodule -l | grep passenger`. Check that the Passenger module appears in the list, and that its version equals the version specified in the `policy_module(.,.)` statement in `specs/passenger/passenger.te`.
 4. Run `ls -Z /usr/lib64/passenger/support-binaries/PassengerAgent`. Check that it has the `passenger_exec_t` type.

## Test 2: Passenger core

 1. Run `sestatus`. Check that SELinux is enabled and set to enforcing.
 2. Ensure the `mod_passenger` RPM is installed.
 3. Ensure Apache is started, e.g.: `sudo service httpd start`
 4. Run `ps auxwZ | grep 'Passenger core'`. Check that it has the `unconfined_t` domain.

## Test 3: Ruby app

 1. Run `sestatus`. Check that SELinux is enabled and set to enforcing.
 2. Ensure the `mod_passenger` RPM is installed.
 3. Ensure Apache is started, e.g.: `sudo service httpd start`
 4. Access the test app: `curl http://rack.test`. Check that it prints `ok`.
 5. Run `ps auxwZ | grep RubyApp`. Check that all RubyApp processes have the `unconfined_t` domain.
