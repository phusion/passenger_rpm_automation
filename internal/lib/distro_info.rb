REDHAT_ENTERPRISE_DISTRIBUTIONS = {
  "el6" => "el6.0",
  "el7" => "el7.0"
}

DISTRO_BUILD_PARAMS = {
  "el6" => {
    :mock_chroot_name => "epel-6",
    :name => "Enterprise Linux 6"
  },
  "el7" => {
    :mock_chroot_name => "epel-7",
    :name => "Enterprise Linux 7"
  }
}
