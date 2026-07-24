require 'etc'
require_relative '../lib/utils'
require_relative '../lib/distro_info'

DISTROS = ENV['DISTRIBUTIONS'].split(/ +/)
RPM_ARCH = ENV['RPM_ARCH']
SHOW_TASKS = !!ENV['SHOW_TASKS']
SHOW_OVERVIEW_PERIODICALLY = ENV['SHOW_OVERVIEW_PERIODICALLY'] == 'true'
FETCH_PASSENGER_TARBALL_FROM_CACHE = ENV['FETCH_PASSENGER_TARBALL_FROM_CACHE'] == 'true'

RPMBUILD_ROOT   = File.expand_path("~/rpmbuild")
RPM_SOURCES_DIR = "#{RPMBUILD_ROOT}/SOURCES"
RPM_SPECS_DIR   = "#{RPMBUILD_ROOT}/SPECS"
RPM_SRPMS_DIR   = "#{RPMBUILD_ROOT}/SRPMS"
MOCK_FLAGS      = ""

include Utils

def initialize_rakefile!
  STDOUT.sync = true
  STDERR.sync = true
  DISTROS.each do |distro|
    if !valid_distro_name?(distro)
      abort "'#{distro}' is not a valid Red Hat distribution name. " +
        "If this is a new distribution that passenger_rpm_automation doesn't " +
        "know about, please edit internal/lib/distro_info.rb."
    end
  end
  if SHOW_TASKS
    create_fake_directories
  else
    Dir.chdir("/system/internal/build")
    load_passenger
    set_constants_and_envvars
  end
end

def valid_distro_name?(name)
  REDHAT_ENTERPRISE_DISTRIBUTIONS.has_key?(name)
end

def create_fake_directories
  Dir.mkdir("/passenger")
  Dir.mkdir("/work")
  Dir.mkdir("/cache")
  Dir.mkdir("/output")
end

def load_passenger
  require "/passenger/src/ruby_supportlib/phusion_passenger"
  PhusionPassenger.locate_directories
  PhusionPassenger.require_passenger_lib 'constants'
end

def set_constants_and_envvars
  ENV["PASSENGER_DIR"] = "/passenger"
  ENV["WORK_DIR"]      = "/work"
  ENV["CACHE_DIR"]     = "/cache"
  ENV["OUTPUT_DIR"]    = "/output"

  if passenger_enterprise?
    set_constant_and_envvar :PASSENGER_RPM_NAME, "passenger-enterprise"
    set_constant_and_envvar :PASSENGER_RPM_RELEASE, 2
    set_constant_and_envvar :PASSENGER_TARBALL_NAME, "passenger-enterprise-server"
    set_constant_and_envvar :PASSENGER_APACHE_MODULE_RPM_NAME, "mod_passenger_enterprise"
    set_constant_and_envvar :PASSENGER_NGINX_MODULE_RPM_NAME, "nginx-mod-http-passenger-enterprise"
  else
    set_constant_and_envvar :PASSENGER_RPM_NAME, "passenger"
    set_constant_and_envvar :PASSENGER_RPM_RELEASE, 1
    set_constant_and_envvar :PASSENGER_TARBALL_NAME, "passenger"
    set_constant_and_envvar :PASSENGER_APACHE_MODULE_RPM_NAME, "mod_passenger"
    set_constant_and_envvar :PASSENGER_NGINX_MODULE_RPM_NAME, "nginx-mod-http-passenger"
  end
  set_constant_and_envvar :PASSENGER_ENTERPRISE, passenger_enterprise?
  set_constant_and_envvar :PASSENGER_VERSION, PhusionPassenger::VERSION_STRING
  set_constant_and_envvar :PASSENGER_TARBALL, "#{PASSENGER_TARBALL_NAME}-#{PASSENGER_VERSION}.tar.gz"

  if passenger_enterprise?
    set_constant_and_envvar :NGINX_RPM_RELEASE, "2.p#{PASSENGER_VERSION}"
  else
    set_constant_and_envvar :NGINX_RPM_RELEASE, "1.p#{PASSENGER_VERSION}"
  end
  set_constant_and_envvar :NGINX_RPM_NAME, "nginx"
  set_constant_and_envvar :NGINX_VERSION, PhusionPassenger::PREFERRED_NGINX_VERSION
  set_constant_and_envvar :NGINX_TARBALL_NAME, "nginx"
  set_constant_and_envvar :NGINX_TARBALL, "nginx-#{NGINX_VERSION}.tar.gz"
end

def set_constant_and_envvar(name, value)
  Kernel.const_set(name.to_sym, value)
  ENV[name.to_s] = value.to_s
end

def passenger_enterprise?
  defined?(PhusionPassenger::PASSENGER_IS_ENTERPRISE)
end

def passenger_srpm_name(distro_id)
  "#{PASSENGER_RPM_NAME}-#{PASSENGER_VERSION}-#{PASSENGER_RPM_RELEASE}.#{distro_id}.src.rpm"
end

def nginx_srpm_name(distro_id)
  "#{NGINX_RPM_NAME}-#{NGINX_VERSION}-#{NGINX_RPM_RELEASE}.#{distro_id}.src.rpm"
end
