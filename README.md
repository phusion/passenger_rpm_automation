# Phusion Passenger RPM packaging automation

This repository contains tools for automating the building of RPM packages for Phusion Passenger. These tools require Ubuntu 12.04 x86_64, Docker and Jenkins. The main build environment is a CentOS 6 Docker container.

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

Any arguments you pass are passed to `docker run`.

### Building RPMs

To build RPMs for all supported distributions and all supported architectures, run:

    ./build -p PROJECT_DIR

The RPMs will be saved to `PROJECT_DIR/build`.

You can also build RPMs for just a single distribution/architecture. Use the `-d` and `-a` parameters to do that. Pass `-h` for help.
