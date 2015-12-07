ROOT = File.expand_path(File.dirname(__FILE__) + "/..")

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "bento/centos-7.1"
  config.vm.hostname = "centos7"

  if File.exist?("../../bin/passenger")
    passenger_path = File.absolute_path("../../bin/passenger")
  elsif File.directory?("../passenger")
    passenger_path = File.absolute_path("../passenger")
  end
  if passenger_path
    config.vm.synced_folder passenger_path, "/passenger"
  end

  config.vm.provider :virtualbox do |vb, override|
    vb.cpus   = 2
    vb.memory = 1536
  end

  config.vm.provider :vmware_fusion do |vf, override|
    vf.vmx["numvcpus"] = 2
    vf.vmx["memsize"]  = 1536
  end

  config.vm.provision :shell, :path => "internal/scripts/setup-vagrant.sh"
end
