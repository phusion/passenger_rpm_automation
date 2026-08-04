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
       name: "Enterprise Linux #{numeric(v)}",
}
end

def latest_nginx_available_parts(release, distro)
  arch = "x86_64"
  url = case distro
    when :rocky then "https://dl.rockylinux.org/pub/rocky/#{numeric(release)}"
    when :alma  then "https://repo.almalinux.org/almalinux/#{numeric(release)}"
    when :rhel  then "https://cdn-ubi.redhat.com/content/public/ubi/dist/ubi#{numeric(release)}/#{numeric(release)}"
  end

  if release < 10
  url += case distro
         when :rocky then "/AppStream/#{arch}/os/Packages/n/"
         when :alma  then "/AppStream/#{arch}/os/Packages/"
         when :rhel  then "/#{arch}/appstream/os/Packages/n/"
         end
  else
    url += case distro
           when :rocky then "/devel/#{arch}/os/Packages/n/"
           when :alma  then "/CRB/#{arch}/os/Packages/"
           when :rhel  then "/#{arch}/appstream/os/Packages/n/" # path for nginx-mod-stream because nginx-mod-devel not in ubi10
           end
  end

  cache_file = "/tmp/#{distro}_#{release}_nginx_version.txt"
  if !File.exist?(cache_file) || ((Time.now - 60*60*24) > File.mtime(cache_file))
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
                      .css('a[href^="nginx-mod-"]') # cannot use full nginx-mod-devel name because ubi10 doesn't include that package for some reason
                      .map { |el| el['href'] }
                      .reject { |s| [ "-mod-", ".noarch.", "-core-" ].any? { |p| s.include?(p) } }
                      .map { |url| URI.decode_uri_component(url).delete_suffix(".#{arch}.rpm").split('-').slice(1..) }
                      .group_by(&:first)
                      .max_by { |v| Gem::Version.new(v.first) }
                      .last
                      .max_by { |e| e.last.split('+').last.split('.').at(1).to_i }
    File.write(cache_file, version_parts.join('-'))
  else
    version_parts = File.read(cache_file).split('-')
  end
  version_parts
end

def latest_nginx_version(release, distro)
  latest_nginx_available_parts(release, distro).first
end

def latest_nginx_module(release, distro)
  latest_nginx_version(release, distro).split('.').first(2).join('.')
end

def latest_nginx_release(release, distro)
  latest_nginx_available_parts(release, distro).last
end

def latest_nginx_epoch(distro)
  if numeric(distro) > 8
    2
  else
    1
  end
end
