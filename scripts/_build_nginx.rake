PASSENGER_DIR = (ENV['PASSENGER_DIR'] || abort("Please set PASSENGER_DIR"))
$LOAD_PATH.unshift(PASSENGER_DIR)
$LOAD_PATH.unshift("#{PASSENGER_DIR}/lib")
def verbose(val); end
require "build/basics"
require "build/preprocessor"

RPM_NAME = "nginx"
RPM_VERSION = PREFERRED_NGINX_VERSION

MOCK_OFFLINE = boolean_option('MOCK_OFFLINE', false)
ALL_RPM_DISTROS = begin
	result = {}
	specs = string_option('ALL_RPM_DISTROS', 'el6,epel-6,Enterprise Linux 6:amazon,epel-6,Amazon Linux')
	specs = specs.split(':')
	specs.each do |spec|
		distro_id, mock_chroot_name, distro_name = spec.split(',')
		result[distro_id] = { :mock_chroot_name => mock_chroot_name, :distro_name => distro_name }
	end
	result
end
ALL_RPM_ARCHS = string_option('ALL_RPM_ARCHS', 'i386 x86_64').split(' ')

desc "Build RPMs for all distributions"
task "rpm:all"

task "rpm:sources" do
	sh "cp /rpm-nginx/* #{rpmbuild_root}/SOURCES/"
	if !File.exist?("#{rpmbuild_root}/SOURCES/nginx-#{PREFERRED_NGINX_VERSION}.tar.gz.asc")
		sh "cd #{rpmbuild_root}/SOURCES && wget http://nginx.org/download/nginx-#{PREFERRED_NGINX_VERSION}.tar.gz.asc"
	end
end

def rpmbuild_root
	@rpmbuild_root ||= File.expand_path("~/rpmbuild")
end

def create_rpm_build_tasks(distro_id, mock_chroot_name, distro_name, arch)
	rpm_spec_dir = "#{rpmbuild_root}/SPECS"
	spec_target_dir = "#{rpm_spec_dir}/#{distro_id}"
	spec_target_file = "#{spec_target_dir}/#{RPM_NAME}.spec"
	maybe_offline = MOCK_OFFLINE ? "--offline" : nil

	desc "Build RPM for #{distro_name} (SRPM)"
	task "rpm:#{distro_id}:srpm" => "rpm:sources" do
		sh "mkdir -p #{spec_target_dir}"
		puts "Generating #{spec_target_file}"
		Preprocessor.new.start("/rpm-nginx/#{RPM_NAME}.spec.template",
			spec_target_file,
			:distribution => distro_id)
		sh "rpmbuild -bs #{spec_target_file}"
	end
	task "rpm:all" => "rpm:#{distro_id}:srpm"

	desc "Build RPM for #{distro_name} (#{arch})"
	task "rpm:#{distro_id}:#{arch}" => "rpm:#{distro_id}:srpm" do
		sh "/usr/bin/mock --verbose #{maybe_offline} " +
			"-r #{mock_chroot_name}-#{arch} " +
			"--resultdir '#{PKG_DIR}/#{distro_id}' " +
			"rebuild #{rpmbuild_root}/SRPMS/#{RPM_NAME}-#{RPM_VERSION}-1.#{distro_id}.src.rpm"
	end
	task "rpm:all" => "rpm:#{distro_id}:#{arch}"
end

ALL_RPM_DISTROS.each_pair do |distro_id, info|
	ALL_RPM_ARCHS.each do |arch|
		create_rpm_build_tasks(distro_id, info[:mock_chroot_name], info[:distro_name], arch)
	end
end
