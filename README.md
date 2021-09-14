# Phusion Passenger RPM packaging project

This repository contains RPM package definitions for [Phusion Passenger](https://www.phusionpassenger.com/), as well as tools for automatically building Passenger packages for multiple distributions and architectures.

The goal of this project is twofold:

 1. To allow Phusion to release RPM packages for multiple distributions and architectures, immediately after a Passenger source release, in a completely automated manner.
 2. To allow users to build their own RPM packages for Passenger, without having to wait for Phusion to do so.

> Are you a user who wants to build your own RPMs for a Passenger version that hasn't been released yet? Read [Tutorial: building your own packages](#tutorial-building-your-own-packages).

**Table of Contents**

 * [Overview](#overview)
 * [Development](#development)
 * [Package building process](#package-building-process)
   - [The build script](#the-build-script)
   - [The test script](#the-test-script)
   - [The publish script](#the-publish-script)
 * [Maintenance](#maintenance)
   - [Updating build and/or testboxes](#updating-build-andor-testboxes)
   - [Adding support for a new distribution](#adding-support-for-a-new-distribution)
   - [Building Nginx packages only](#building-nginx-packages-only)
   - [Updating SSL certificates](#updating-ssl-certificates)
   - [Dealing with broken packages: enabling/disabling CR](#dealing-with-broken-packages-enablingdisabling-cr)
 * [Jenkins integration](#jenkins-integration)
   - [Debugging a packaging test failure](#debugging-a-packaging-test-failure)
 * [Tutorial: building your own packages](#tutorial-building-your-own-packages)
 * [Related projects](#related-projects)

## Overview

This project consists of three major tools:

 * **build** -- Given a Passenger source directory, this script builds RPM packages for it.
 * **test** -- Given a directory with built RPM packages (as produced by the `build` script), this script runs tests against them.
 * **publish** -- Given a directory with built RPM packages, this script publishes them to repos.phusionpassenger.com.

RPM package definitions are located in the `specs` directory:

 * `specs/passenger` -- Package definitions for Passenger, both open source and [Enterprise](https://www.phusionpassenger.com/enterprise).
 * `specs/nginx` -- Package definitions for Nginx, with Passenger compiled in.

Other noteworthy tools:

 * `jenkins` -- Scripts to be run by our Jenkins continuous integration jobs, either after every commit or during release time.

This project utilizes Docker for isolation. Because of the usage of Docker, these tools can be run on any 64-bit Linux system, including non-Red Hat-based systems. Though in practice, we've only tested on CentOS 6.

## Development

This repository is included as a git submodule in the Passenger git repository, under the directory `packaging/rpm`. Instead of cloning the `passenger_rpm_automation` repository directly, you should clone the Passenger git repository, and work in the `packaging/rpm` directory instead. This scheme allows each Passenger version to lock down to a specific version of `passenger_rpm_automation`.

A Vagrantfile is provided so that you can develop this project in a VM. To get started, run:

    host$ vagrant up

The Passenger source directory (`../..`) will be automatically mounted inside the VM under `/passenger`.

## Package building process

The package build process is as follows. First, the `build` script is used to build RPM packages from a Passenger source code directory. Next, either the `test` script is run to test the built packages, or the `publish` script is run to publish the built packages to repos.phusionpassenger.com.

    build   ------------>   test
                 \
                  \----->   publish

### The build script

Everything begins with the `build` script and a copy of the Passenger source code. Here's an example invocation:

    ./build -p /passenger -w work -c cache -o output rpm:all

 * `-p` tells it where the Passenger source code is.
 * `-w` tells it where it's work directory is. This is a directory in which in stores temporary files while building packages. WARNING: everything inside this directory will be deleted before the build begins, so only specify a directory that doesn't contain anything important.
 * `-c` tells it where the cache directory is. The build script caches files into this directory so that subsequent runs will be faster.
 * `-o` tells it where to store the final built RPM packages (the output directory). WARNING: everything inside this directory will be deleted when the build finishes, so only specify a directory that doesn't contain anything important.
 * The final argument, `rpm:all`, is the task that the build script must run. The build script provides a number of tasks, such as tasks for building packages for specific distributions or architecture only, or tasks for building source packages only. The `rpm:all` task builds all source and binary RPMs for all supported distributions and architectures.

More command line options are available. Run `./build -h` to learn more. You can also run `./build -T` to learn which tasks are available.

When the build script is finished, the output directory (`-o`) will contain one subdirectory per distribution that was built for, with each subdirectory containing packages for that distribution (in all architectures that were built for). For example:

    output/
      |
      +-- el6/
      |      |
      |      +-- *.rpm
      |
      +-- el7/
      |      |
      |      +-- *.rpm
      |
     ...

#### Vagrant notes

When using Vagrant, the directories referred to by `-w` and `-c` must be native filesystem directories. That is, they may not be located inside /vagrant, because /vagrant is a remote filesystem. I typically use `-w ~/work -c ~/cache` when developing with Vagrant.

#### Troubleshooting

If anything goes wrong during a build, please take a look at the various log files in the work directory. Of interest are:

 * state.log -- Overview.
 * pkg.*.log -- Build logs for a specific package, distribution and architecture.

### The test script

Once packages have been built, you can test them with the test script. Here is an example invocation:

    ./test -p /passenger -x centos7 -d output/el7 -c cache

 * `-p` tells it where the Passenger source code is.
 * `-x` tells it which environment it should use for running the tests. To learn which environments are supported, run `./test -h`.
 * `-d` tells it where to find the packages that are to be tested. This must point to a subdirectory in the output directory produced by the build script, and the packages must match the test environment as specified by `-x`. For example, if you specified `-x centos7`, and if the build script stored packages in the directory `output`, then you should pass `-d output/el7`.
 * `-c` tells it where the cache directory is. The test script caches files into this directory so that subsequent runs will be faster.

#### Vagrant notes

When using Vagrant, the directory referred to by `-c` must be a native filesystem directory. That is, it may not be located inside /vagrant, because /vagrant is a remote filesystem. I typically use `-c ~/cache` when developing with Vagrant.

### The publish script

Once packages have been built, you can publish them to repos.phusionpassenger.com. The `publish` script publishes all packages inside a build script output directory. Example invocation:

    ./publish -d output -u phusion -c ~/token_file -r passenger-testing publish:all

 * `-d` tells it where the build script output directory is.
 * `-u` tells it the repo server API username.
 * `-c` tells it the path to the repo server API token file.
 * `-r` tells it the name of the package repository. For example `yum-repo-(oss|enterprise)(.staging)`.
 * The last argument is the task to run. The `publish:all` publishes all packages inside the build script output directory.

## Maintenance

### Updating build and/or testboxes

If you change the buildbox or testbox, you should create a new version:

1. Update the relevant part(s) in `internal/lib/docker_image_info.sh`.
2. Run `./internal/scripts/regen_distro_info_script.sh`.
3. Run `cd docker-images/ && make all`.
3. Run `make upload`.

### Adding support for a new distribution

In these instructions, we assume that the new distribution is Red Hat 7. Update the actual parameters accordingly.

 1. Bump the the buildbox version number's tiny component. Open `internal/lib/docker_image_info.sh` and change the number under `buildbox_version`.

 2. Add a definition for this new distribution to `internal/lib/distro_info.rb`.

     1. Add to the `REDHAT_ENTERPRISE_DISTRIBUTIONS` constant.
     2. Add to the `DISTRO_BUILD_PARAMS` constant.
     3. Add the new mock configs to the `docker-images/buildbox/install.sh` script.

 3. Run `internal/scripts/regen_distro_info_script.sh`.

 4. Rebuild the build box so that it has the latest distribution information:

        make -C docker-images buildbox

 5. Add `<% if %>` statements accordingly to output the appropriate content for the target distribution in `specs/passenger/passenger.spec.erb`.

 6. Build and publish packages for this distribution only. You can do that by running the build script with the `-d` option.

        ./build -p /passenger -w work -c cache -o output -d el7 rpm:all
        ./publish -d output -u phusion -c ~/token_file -r passenger-testing publish:all

 7. Create a test box for this new distribution.

     1. Create `docker-images/testbox-centos-7/` (copy of testbox of previous release)
     2. Set the correct From in `docker-images/testbox-centos-7/Dockerfile`
     3. Edit `docker-images/Makefile` and add entries for this new testbox.

        make -C docker-images testbox-centos-7

    When done, test Passenger under the new testbox:

        ./test -p /passenger -x el7 -d output/el7 -c cache

 8. Commit and push all changes, then publish the new packages and the updated Docker images by running:

        git add docker-images
        git commit -a -m "Add support for Red Hat 7"
        git push
        cd docker-images
        make upload

 9. Inside the [passenger](https://github.com/phusion/passenger) repository:

     1. Update the `packaging/rpm` submodule (which refers to the `passenger_rpm_automation` repository) to the latest commit, then commit the result. Assuming you want the submodule to update to the latest `master` branch commit:

        cd packaging/rpm
        git checkout master
        git pull
        cd ../..

     2. Edit `dev/ci/tests/rpm/Jenkinsfile` and add corresponding code for this new distribution and all its supported architectures.

     3. Commit and push the result:

            git commit -a -m "Add packaging support for CentOS 7"
            git push

 10. Inside the passenger-release repository, add this new distribution and all its supported architectures to its Jenkinsfile's `RPM_DISTROS` and `RPM_TARGETS` constants.

### Building Nginx packages only

Sometimes you want to build Nginx packages only, without building the Phusion Passenger packages. You can do this by invoking the build script with the `rpm:nginx:all` task. For example:

    ./build -p /passenger -w work -c cache -o output -d el7 rpm:nginx:all

After the build script finishes, you can publish these Nginx packages:

    ./publish -d output -u phusion -c ~/token_file -r passenger-testing publish:all

### Updating SSL certificates

The Jenkins publishing script posts to some HTTPS servers. For security reasons, we pin the certificates, but these certificates expire after a while. You can update them by running:

    ./internal/scripts/pin_certificates

### Dealing with broken packages: enabling/disabling CR

Once in a while, while building or while testing, YUM will abort with an error like this:

    --> Running transaction check
    ---> Package gperftools-libs.x86_64 0:2.4-5.el7 will be installed
    --> Processing Dependency: libunwind.so.8()(64bit) for package: gperftools-libs-2.4-5.el7.x86_64
    --> Finished Dependency Resolution
    Error: Package: gperftools-libs-2.4-5.el7.x86_64 (epel)
               Requires: libunwind.so.8()(64bit)
     You could try using --skip-broken to work around the problem
     You could try running: rpm -Va --nofiles --nodigest

This tends to happen after a new RHEL minor release. The problem is that the Passenger packages depend on EPEL. EPEL builds against the latest RHEL release. But CentOS lags behind RHEL, so right after a new RHEL minor release there will be packages in EPEL which do not work on the latest CentOS minor release.

To fix this problem, you need to enable the [CentOS Continuous Release](https://wiki.centos.org/AdditionalResources/Repositories/CR) (CR) repository in the build box and the test box. The CR repository contains prerelease packages for the next CentOS release. Note that if you enable CR, any RPMs you produce will end up depending on the package versions in CR. This means that those RPMs will work on RHEL (which has already released those versions of the dependency packages), but not on CentOS systems without CR. You must therefore instruct CentOS users to enable CR until the next CentOS minor release is published.

To enable or disable CR:

 * Edit `docker-images/buildbox/epel-7-x86_64.cfg`. Under the `[cr]` section, modify the `enabled` flag. Then run `make -C docker-images buildbox`
 * Edit `docker-images/testbox-centos-7/install.sh`. Either comment or uncomment the lines responsible for enabling CR. Then run `make -C docker-images testbox-centos-7`

When done, push these images and pull from them the CI server.

You should disable CR in the buildbox and the testbox as soon as the next CentOS minor release is published.

## Jenkins integration

The `jenkins` directory contains scripts which are invoked from jobs in the Phusion Jenkins CI server.

### Debugging a packaging test failure

If a packaging test job fails, here's what you should do.

 1. Checkout the Passenger source code, go to the commit for which the test failed, then cd into the packaging/rpm directory.

        git clone https://github.com/phusion/passenger.git
        git reset --hard <COMMIT FOR WHICH THE TEST FAILED>
        cd packaging/rpm

 2. If you're not on Linux, setup the Vagrant development environment and login to the VM:

        vagrant up
        vagrant ssh

 3. Build packages for the distribution for which the test failed.

        ./build -w ~/work -c ~/cache -o ~/output -p /passenger -d el7 -a x86_64 -j 2 -R rpm:all

    Be sure to customize the value passed to `-d` based on the distribution for which the test failed.
 4. Run the tests with the debugging console enabled:

        ./test -p /passenger -x centos7 -d ~/output/el7 -c ~/cache -D

    Be sure to customize the values passed to `-x` and `-d` based on the distribution for which the test failed.

If the test fails now, a shell will be opened inside the test container, in which you can do anything you want. Please note that this is a root shell, but the tests are run as the `app` user, so be sure to prefix test commands with `setuser app`. You can see in internal/test/test.sh which commands are invoked inside the container in order to run the tests.

Inside the test container, you will be dropped into the directory /tmp/passenger, which is a *copy* of the Passenger source directory. The original Passenger source directory is mounted under /passenger.

## Tutorial: building your own packages

Are you a user who wants to build RPMs for a Passenger version that hasn't been released yet? Maybe because you want to gain access to a bug fix that isn't part of a release yet? Then this tutorial is for you.

You can follow this tutorial on any OS you want. You do not necessarily have to follow this tutorial on the OS you wish to build packages for. For example, it is possible to build packages for Red Hat 7 while following this tutorial on OS X.

### Prerequisites

If you are following this tutorial on a Linux system, then you must [install Docker](https://www.docker.com/).

If you are following this tutorial on any other OS, then you must install [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/).

NOTE: If you are on OS X, installing boot2docker is NOT enough. You MUST use Vagrant+VirtualBox.

### Step 1: Checkout out the desired source code

First, clone the Passenger git repository and its submodules:

    git clone https://github.com/phusion/passenger.git
    cd passenger
    git submodule update --init --recursive

Checkout the branch you want. At the time of writing (2015 May 13), you will most likely be interested in the `stable-5.0` branch because that's the branch that is slated to become the next release version.

    git checkout stable-5.0

Then go to the directory `packaging/rpm`:

    cd packaging/rpm

### Step 2 (non-Linux): spin up Vagrant VM

If you are on a Linux system, then you can skip to step 3.

If you are not on a Linux system, then you must spin up the Vagrant VM. Type:

    vagrant up

Wait until the VM has booted, then run:

    vagrant ssh

You will now be dropped in an SSH session inside the VM. Any futher steps must be followed inside this SSH session.

### Step 3: build packages

Use the `./build` script to build RPMs. You must tell the build script which distribution and architecture it should build for. Run:

    ./build -p <PATH TO PASSENGER> -w ~/work -c ~/cache -o output -a <ARCHITECTURE> -d <DISTRIBUTION> rpm:all

Replace `<PATH TO PASSENGER>` with one of these:

 * If you are on a Linux system, it should be `../..`.
 * If you are on a non-Linux system (and using Vagrant), it should be `/passenger`.

Replace `<ARCHITECTURE>` with either `i386` or `x86_64`. Replace `<DISTRIBUTION>` with either `el6` or `el7`.

 * `el6` is for Red Hat Enterprise Linux 6.x and CentOS 6.x.
 * `el7` is for Red Hat Enterprise Linux 7.x and CentOS 7.x.

Here is an example invocation for building packages for Red Hat 7, x86_64:

```bash
# If you are on a Linux system:
./build -p ../.. -w ~/work -c ~/cache -o output -a x86_64 -d el7 rpm:all

# If you are on a non-Linux system (and using Vagrant):
./build -p /passenger -w ~/work -c ~/cache -o output -a x86_64 -d el7 rpm:all
```

### Step 4: get packages, clean up

When the build is finished, you can find the RPMs in the `output` directory.

If you are on a non-Linux OS (and thus using Vagrant), you should know that this `output` directory is accessible from your host OS too. It is a subdirectory inside `<PASSENGER REPO>/packaging/rpm`.

If you are not on a Linux system, then you should spin down the Vagrant VM. Run this on your host OS, inside the `packaging/rpm` subdirectory:

    vagrant halt

## Related projects

 * https://github.com/phusion/passenger_binary_build_automation
 * https://github.com/phusion/passenger_apt_automation
 * http://pkgs.fedoraproject.org/cgit/rpms/passenger.git/tree/
