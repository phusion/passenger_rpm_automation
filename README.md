# Phusion Passenger RPM packaging automation

This repository contains tools for automating the building of RPM packages for Phusion Passenger. These tools require Ubuntu 12.04 x86_64.

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

## Testing the latest git commit

Run this to fetch the latest git commit and to test its RPM packaging:

    ./invoke /srv/passenger_rpm_automation/passenger test

## Webhook

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
