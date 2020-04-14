require 'open-uri'
require 'nokogiri'

REDHAT_ENTERPRISE_DISTRIBUTIONS = {
  "el6" => "el6.0",
  "el7" => "el7.0",
  "el8" => "el8.0",
}

DISTRO_BUILD_PARAMS = {
  "el6" => {
    :mock_chroot_name => "epel-6",
    :name => "Enterprise Linux 6"
  },
  "el7" => {
    :mock_chroot_name => "epel-7",
    :name => "Enterprise Linux 7"
  },
  "el8" => {
    :mock_chroot_name => "epel-8",
    :name => "Enterprise Linux 8"
  },
}

def distro_architecture_allowed?(distro_id, arch)
  # Red Hat does not support x86 after RHEL 6
  (distro_id.delete_prefix("el").to_i < 7) || arch == "x86_64"
end

def dynamic_module_supported?(distro)
  distro.delete_prefix("el").to_i > 6
end

def latest_nginx_available_parts(distro)
  cache_file = "/tmp/#{distro}_nginx_version.txt"
  if !File.exists?(cache_file) || ((Time.now - 60*60*24) > File.mtime(cache_file))
    if distro == "el7"
      url = "https://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/n/"
    elsif distro == "el8"
      url = "http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages/"
    else
      abort "Unknown distro: '#{distro.to_s}', add to latest_nginx_available method."
    end
    doc = open(url) do |io|
      Nokogiri.HTML(io)
    end
    version_parts = doc.at_css('a[href^="nginx-"]').text.lines.select{|s|!(s.include?("-mod-") || s.include?(".noarch."))}.first.strip
    File.write(cache_file,version_parts)
  else
    version_parts = File.read(cache_file)
  end
  version_parts.split('-')
end

def latest_nginx_version(distro)
  latest_nginx_available_parts(distro).select{|s|/^[\d\.]+$/.match?(s)}.first
end

def latest_nginx_release(distro)
  latest_nginx_available_parts(distro).last.split('.').first
end

def latest_nginx_epoch(distro)
  1
end
