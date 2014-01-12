# Phusion Passenger RPM packaging automation

This repository contains tools for automating the building of RPM packages for Phusion Passenger. These tools require Ubuntu 12.04 x86_64 and Docker. The main build environment is a CentOS 6.4 Docker container.

## Installation

First, install Docker: http://www.docker.io/

Then install `passenger_rpm_automation`:

    git clone https://github.com/phusion/passenger_rpm_automation.git /tmp/passenger_rpm_automation
    /tmp/passenger_rpm_automation/setup-system
    sudo mv /tmp/passenger_rpm_automation /srv/passenger_rpm_automation
    sudo chown -R psg_rpm_automation: /srv/passenger_rpm_automation

Next, create a project for Phusion Passenger:

    cd /srv/passenger_rpm_automation
    sudo ./create_project passenger https://github.com/phusion/passenger.git

## Usage

`passenger_rpm_automation` usage commands are supposed to be run as the `psg_rpm_automation` user, and from the `/srv/passenger_rpm_automation` directory.

### Logging into the build environment

Run this to login to the build environment container. This allows you to inspect things. Any changes you make will not be saved.

    ./shell

You can also mount a specific project under the /project directory inside a container. Pass the project directory to `./shell`, like this:

    ./shell /srv/passenger_rpm_automation/passenger

### Testing the latest git commit

Run this to fetch the latest git commit and to test its RPM packaging:

    ./invoke /srv/passenger_rpm_automation/passenger test

### Building RPMs

    ./invoke /srv/passenger_rpm_automation/passenger build

### Webhook

The webhook allows the RPM packaging to be tested every time a developer pushes to Github. To setup the webhook, deploy the web app in the `webhook` directory, and make it run under the user `psg_rpm_automation`.

    server {
        listen 80;
        server_name webhook.somewhere.com;
        root /srv/passenger_rpm_automation/webhook;
        passenger_enabled on;
        passenger_spawn_method direct;
        passenger_min_instances 0;
        passenger_user psg_rpm_automation;
    }

The webhook uses `at` to invoke the tests, so make sure `at` is installed. If the test fails then `at` will send an email to the `psg_rpm_automation` user, so make sure such emails are redirected to the email address you want. For example, you can put this in /etc/aliases:

    psg_rpm_automation: your-email-address@server.com

After editing the file, run `sudo newaliases`.
