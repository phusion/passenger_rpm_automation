# Phusion Passenger RPM packaging automation

This repository contains tools for automating the building of RPM packages for Phusion Passenger.

## Getting started

First, install Docker: http://www.docker.io/

Then install `passenger_rpm_automation`:

    git clone https://github.com/phusion/passenger_rpm_automation.git /tmp/psg_rpm_automation
    /tmp/psg_rpm_automation/setup-system
    sudo mv /tmp/psg_rpm_automation /srv/psg_rpm_automation
    chown -R psg_rpm_automation: /srv/psg_rpm_automation

Next, create a project for Phusion Passenger:

    cd /srv/psg_rpm_automation
    sudo ./create_project passenger https://github.com/phusion/passenger.git

## 