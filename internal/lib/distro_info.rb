require 'open-uri'
require 'nokogiri'

# After editing this file, regenerate distro_info.sh by running:
# internal/scripts/regen_distro_info_script.sh

def numeric(distro)
  distro.delete_prefix('el').to_i
end

REDHAT_ENTERPRISE_DISTRIBUTIONS = {
  "el8" => "el8.0",
  "el9" => "el9.0",
  "el10" => "el10.0",
}

DISTRO_BUILD_PARAMS = REDHAT_ENTERPRISE_DISTRIBUTIONS.transform_values do |v| {
       mock_chroot_name: "rocky+epel-#{numeric(v)}",
       name: "Enterprise Linux #{numeric(v)}"
}
end

def dynamic_module_supported?(distro)
  numeric(distro) > 6
end

def latest_nginx_available_parts(distro)
  cache_file = "/tmp/#{distro}_nginx_version.txt"
  if !File.exist?(cache_file) || ((Time.now - 60*60*24) > File.mtime(cache_file))
    url = "https://dl.rockylinux.org/pub/rocky/#{numeric(distro)}/AppStream/x86_64/os/Packages/n/"
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
  if numeric(distro) > 8
    2
  else
    1
  end
end
