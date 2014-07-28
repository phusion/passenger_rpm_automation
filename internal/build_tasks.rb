require File.expand_path(File.dirname(__FILE__) + '/../lib/preprocessor')
require File.expand_path(File.dirname(__FILE__) + '/../lib/build_tasks_support')

DISTROS           = get_distros_option
ARCHS             = get_archs_option
PASSENGER_VERSION = detect_passenger_version
NGINX_VERSION     = detect_nginx_version

PASSENGER_RPM_NAME     = enterprise? ? "passenger-enterprise" : "passenger"
PASSENGER_RPM_VERSION  = string_option("FORCE_PASSENGER_VERSION", PASSENGER_VERSION)
PASSENGER_RPM_RELEASE  = enterprise? ? 2 : 1
PASSENGER_TARBALL_NAME = enterprise? ? "passenger-enterprise-server" : "passenger"
PASSENGER_APACHE_MODULE_RPM_NAME = enterprise? ? "mod_passenger_enterprise" : "mod_passenger"
NGINX_RPM_NAME         = "nginx"
NGINX_RPM_VERSION      = NGINX_VERSION
NGINX_RPM_RELEASE      = enterprise? ? "2.p#{PASSENGER_RPM_VERSION}" : "1.p#{PASSENGER_RPM_VERSION}"
SUPPORTED_DISTROS      = {
  "el6"    => { :mock_chroot_name => "epel-6", :name => "Enterprise Linux 6" },
  # We don't support RHEL 7 yet because EPEL 7 hasn't yet packaged rubygem-rack.
  #"el7"    => { :mock_chroot_name => "epel-7", :name => "Enterprise Linux 7" },
}

RPMBUILD_ROOT   = ENV['RPMBUILD_ROOT'] || File.expand_path("~/rpmbuild")
RPM_SOURCES_DIR = "#{RPMBUILD_ROOT}/SOURCES"
RPM_SPECS_DIR   = "#{RPMBUILD_ROOT}/SPECS"
RPM_SRPMS_DIR   = "#{RPMBUILD_ROOT}/SRPMS"
MOCK_FLAGS      = ""

initialize_tracking_database!
check_distros_supported!
check_archs_supported!
clean_bundler_env!
TrackingDatabase.instance   # Initialize singleton.
STDOUT.sync = STDERR.sync = true
ENV['CACHING'] = 'false'


##### Source tarballs and initialization #####

SOURCE_TASKS = ['source:passenger', 'source:nginx', 'source:packaging_additions']

register_tracking_category(:preparation, 'Preparation')

namespace :source do
  register_tracking_task(:preparation, 'passenger')
  desc "Create Passenger source tarball"
  task :passenger do
    track_task(:preparation, 'passenger') do |task|
      task.sh "cd /passenger && rake package:set_official package:tarball PKG_DIR='#{RPM_SOURCES_DIR}'"
    end
  end

  register_tracking_task(:preparation, 'nginx')
  desc "Create Nginx source tarball"
  task :nginx do
    track_task(:preparation, 'nginx') do |task|
      if File.exist?("/cache/nginx-#{NGINX_VERSION}.tar.gz")
        task.sh "cp /cache/nginx-#{NGINX_VERSION}.tar.gz #{RPM_SOURCES_DIR}/"
      else
        task.sh "curl --fail -L -o #{RPM_SOURCES_DIR}/nginx-#{NGINX_VERSION}.tar.gz " +
          "http://nginx.org/download/nginx-#{NGINX_VERSION}.tar.gz"
        task.sh "cp #{RPM_SOURCES_DIR}/nginx-#{NGINX_VERSION}.tar.gz /cache/"
      end
      if File.exist?("/cache/nginx-#{NGINX_VERSION}.tar.gz.asc")
        task.sh "cp /cache/nginx-#{NGINX_VERSION}.tar.gz.asc #{RPM_SOURCES_DIR}/"
      else
        task.sh "curl --fail -L -o #{RPM_SOURCES_DIR}/nginx-#{NGINX_VERSION}.tar.gz.asc " +
          "http://nginx.org/download/nginx-#{NGINX_VERSION}.tar.gz.asc"
        task.sh "cp #{RPM_SOURCES_DIR}/nginx-#{NGINX_VERSION}.tar.gz.asc /cache/"
      end
    end
  end

  register_tracking_task(:preparation, 'packaging_additions')
  desc "Copy over various packaging sources"
  task :packaging_additions do
    track_task(:preparation, 'packaging_additions') do |task|
      task.sh "cp -R /system/passenger_spec/* /system/nginx_spec/* #{RPM_SOURCES_DIR}/"
    end
  end
end


##### Source RPMs #####

register_tracking_category(:srpm, 'Building source RPMs')

namespace :srpm do
  ### Passenger ###

  desc "Build Passenger SRPMs for all distributions"
  task "passenger:all"

  DISTROS.each do |distro_id|
    distro = SUPPORTED_DISTROS[distro_id]

    task "passenger:all" => "passenger:#{distro_id}"

    register_tracking_task(:srpm, "passenger:#{distro_id}")
    desc "Build Passenger SRPM for #{distro[:name]}"
    task("passenger:#{distro_id}" => SOURCE_TASKS) do
      track_task(:srpm, "passenger:#{distro_id}") do |task|
        spec_target_dir  = "#{RPM_SPECS_DIR}/#{distro_id}"
        spec_target_file = "#{spec_target_dir}/#{PASSENGER_RPM_NAME}.spec"

        task.sh "mkdir -p #{spec_target_dir}"
        task.log "Preprocessing specfile"
        begin
          Preprocessor.new.start("/system/passenger_spec/passenger.spec.template",
            spec_target_file,
            :distribution => distro_id)
        rescue Exception => e
          task.log "Specfile preprocessing failed"
          raise e
        end

        task.sh "rpmbuild -bs #{spec_target_file}"
        ARCHS.each do |arch|
          task.sh "mkdir -p /output/#{distro_id}-#{arch}"
          task.sh "cp #{RPM_SRPMS_DIR}/#{passenger_srpm_name(distro_id)} /output/#{distro_id}-#{arch}/"
        end
      end
    end
  end

  ### Nginx ###

  desc "Build Nginx SRPMs for all distributions"
  task "nginx:all"

  DISTROS.each do |distro_id|
    distro = SUPPORTED_DISTROS[distro_id]

    task "nginx:all" => "nginx:#{distro_id}"

    register_tracking_task(:srpm, "nginx:#{distro_id}")
    desc "Build Nginx SRPM for #{distro[:name]}"
    task("nginx:#{distro_id}" => SOURCE_TASKS) do
      track_task(:srpm, "nginx:#{distro_id}") do |task|
        spec_target_dir  = "#{RPM_SPECS_DIR}/#{distro_id}"
        spec_target_file = "#{spec_target_dir}/#{NGINX_RPM_NAME}.spec"

        task.sh "mkdir -p #{spec_target_dir}"
        task.log "Preprocessing specfile"
        begin
          Preprocessor.new.start("/system/nginx_spec/nginx.spec.template",
            spec_target_file,
            :distribution => distro_id)
        rescue Exception => e
          task.log "Specfile preprocessing failed"
          raise e
        end

        task.sh "rpmbuild -bs #{spec_target_file}"
        ARCHS.each do |arch|
          task.sh "mkdir -p /output/#{distro_id}-#{arch}"
          task.sh "cp #{RPM_SRPMS_DIR}/#{nginx_srpm_name(distro_id)} /output/#{distro_id}-#{arch}/"
        end
      end
    end
  end
end


##### Binary RPMs #####

register_tracking_category(:rpm, 'Building binary RPMs')

namespace :rpm do
  desc "Build RPMs for all distributions and all architectures"
  task :all

  ### Passenger ###

  desc "Build Passenger RPMs for all distributions and all architectures"
  task "passenger:all"

  DISTROS.each do |distro_id|
    distro = SUPPORTED_DISTROS[distro_id]

    ARCHS.each do |arch|
      task "all" => "^rpm:passenger:#{distro_id}:#{arch}"
      task "passenger:all" => "^rpm:passenger:#{distro_id}:#{arch}"
      register_tracking_task(:rpm, "passenger:#{distro_id}:#{arch}")

      desc "Build Passenger RPM for #{distro[:name]}, #{arch}"
      task("passenger:#{distro_id}:#{arch}" => ["srpm:passenger:#{distro_id}"]) do
        track_task(:rpm, "passenger:#{distro_id}:#{arch}") do |task|
          mock_chroot_name = "#{distro[:mock_chroot_name]}-#{arch}"
          task.sh "/usr/bin/mock --verbose #{MOCK_FLAGS} " +
            "-r #{mock_chroot_name} " +
            "--resultdir '/output/#{distro_id}-#{arch}' " +
            "--uniqueext passenger-#{distro_id}-#{arch} " +
            "rebuild /output/#{distro_id}-#{arch}/#{passenger_srpm_name(distro_id)}"
        end
      end
    end
  end

  ### Nginx ###

  desc "Build Nginx RPMs for all distributions and all architectures"
  task "nginx:all"

  DISTROS.each do |distro_id|
    distro = SUPPORTED_DISTROS[distro_id]

    ARCHS.each do |arch|
      task "all" => "^rpm:nginx:#{distro_id}:#{arch}"
      task "nginx:all" => "^rpm:nginx:#{distro_id}:#{arch}"
      register_tracking_task(:rpm, "nginx:#{distro_id}:#{arch}")

      desc "Build Nginx RPM for #{distro[:name]}, #{arch}"
      task("nginx:#{distro_id}:#{arch}" => ["srpm:nginx:#{distro_id}"]) do
        track_task(:rpm, "nginx:#{distro_id}:#{arch}") do |task|
          mock_chroot_name = "#{distro[:mock_chroot_name]}-#{arch}"
          task.sh "/usr/bin/mock --verbose #{MOCK_FLAGS} " +
            "-r #{mock_chroot_name} " +
            "--resultdir '/output/#{distro_id}-#{arch}' " +
            "--uniqueext nginx-#{distro_id}-#{arch} " +
            "rebuild /output/#{distro_id}-#{arch}/#{nginx_srpm_name(distro_id)}"
        end
      end
    end
  end
end


##### Misc #####

task :finish do
  puts
  puts "Finished"
  MUTEX.synchronize do
    TrackingDatabase.instance.set_finished!
    dump_tracking_database
  end
end
