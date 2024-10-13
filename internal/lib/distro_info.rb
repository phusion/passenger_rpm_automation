require 'open-uri'
require 'nokogiri'

REDHAT_ENTERPRISE_DISTRIBUTIONS = {
  "el8" => "el8.0",
  "el9" => "el9.0",
}

DISTRO_BUILD_PARAMS = {
  "el8" => {
    :mock_chroot_name => "rocky+epel-8",
    :name => "Enterprise Linux 8"
  },
  "el9" => {
    :mock_chroot_name => "rocky+epel-9",
    :name => "Enterprise Linux 9"
  },
}

def dynamic_module_supported?(distro)
  distro.delete_prefix("el").to_i > 6
end

def latest_nginx_available_parts(distro)
  cache_file = "/tmp/#{distro}_nginx_version.txt"
  if !File.exist?(cache_file) || ((Time.now - 60*60*24) > File.mtime(cache_file))
    if distro == "el8"
      url = "https://dl.rockylinux.org/pub/rocky/8/AppStream/x86_64/os/Packages/n/"
    elsif distro == "el9"
      url = "https://dl.rockylinux.org/pub/rocky/9/AppStream/x86_64/os/Packages/n/"
    else
      abort "Unknown distro: '#{distro.to_s}', add to latest_nginx_available method in #{__FILE__}."
    end
    if RUBY_VERSION >= '2.5'
      doc = URI.open(url) do |io|
        Nokogiri.HTML(io)
      end
    else
	    doc = open(url) do |io|
        Nokogiri.HTML(io)
      end
    end
    version_parts = doc
                      .css('a[href^="nginx-"]')
                      .map { |el| el['href'] }
                      .reject { |s| ["-mod-",".noarch.","-core-"].any?{ |p| s.include?(p) } }
                      .max_by { |v| Gem::Version.new(v.split('-').find{ |s| is_version? s}) }
                      .strip
    File.write(cache_file,version_parts)
  else
    version_parts = File.read(cache_file)
  end
  version_parts.split('-')
end

def is_version?(s)
  /^[\d\.]+$/.match?(s)
end

def latest_nginx_version(distro)
  latest_nginx_available_parts(distro).find{ |s| is_version? s }
end

def latest_nginx_release(distro)
  latest_nginx_available_parts(distro).last.split('.').first
end

def latest_nginx_epoch(distro)
  1
end
