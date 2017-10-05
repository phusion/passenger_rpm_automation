require 'fileutils'
require 'open-uri'
require File.expand_path(File.dirname(__FILE__) + '/misc/test_support')
require '/tmp/passenger/src/ruby_supportlib/phusion_passenger'
PhusionPassenger.locate_directories
PhusionPassenger.require_passenger_lib 'admin_tools/instance_registry'

include FileUtils

clear_bundler_env!

def create_app_dir(source, startup_file, dir_name)
  app_root = "/home/app/#{dir_name}"
  rm_rf(app_root)
  mkdir(app_root)
  cp("/system/internal/test/misc/#{source}", "#{app_root}/#{startup_file}")
  mkdir("#{app_root}/public")
  mkdir("#{app_root}/tmp")
  chown_R("app", "app", app_root)
  app_root
end

def create_app_dirs
  app_dirs = []
  app_dirs << create_app_dir("ruby_test_app.rb", "config.ru", "ruby_test_app")
  app_dirs << create_app_dir("python_test_app.py", "passenger_wsgi.py", "python_test_app")
  app_dirs << create_app_dir("nodejs_test_app.js", "app.js", "nodejs_test_app")
  app_dirs
end

def redhat_major_release
  File.read("/etc/redhat-release") =~ /release ([0-9]+)/
  $1.to_i
end

def start_stop_service(name, action)
  if redhat_major_release >= 7
    if name == "httpd"
      if action == "start"
        sh(". /etc/sysconfig/httpd && /usr/sbin/httpd $OPTIONS")
      elsif action == "stop"
        sh("kill `cat /run/httpd/httpd.pid`")
      else
        raise "Don't know how to #{action} #{name}"
      end
    elsif name == "nginx"
      if action == "start"
        sh("/usr/sbin/nginx")
      elsif action == "stop"
        sh("kill -s QUIT `cat /run/nginx.pid`")
      else
        raise "Don't know how to #{action} #{name}"
      end
    else
      raise "Don't know how to #{action} #{name}"
    end
  else
    sh("service #{name} #{action}")
  end
end

def passenger_root
  `passenger-config --root`.strip
end

shared_examples_for "Hello world Ruby application" do
  it "works" do
    open("http://passenger.test/", "rb") do |io|
      expect(io.read).to eql("Hello Ruby\n")
    end
  end
end

shared_examples_for "Hello world Python application" do
  it "works" do
    open("http://1.passenger.test/", "rb") do |io|
      expect(io.read).to eql("Hello Python\n")
    end
  end
end

shared_examples_for "Hello world Node.js application" do
  it "works" do
    open("http://2.passenger.test/", "rb") do |io|
      expect(io.read).to eql("Hello Node.js\n")
    end
  end
end

describe "The system's Apache with Passenger enabled" do
  before :all do
    @app_dirs = create_app_dirs
    cp("/system/internal/test/apache/vhost.conf", "/etc/httpd/conf.d/testapp.conf")
    chmod(0644, "/etc/httpd/conf.d/testapp.conf")
    start_stop_service("httpd", "start")
    eventually do
      ping_tcp_socket("127.0.0.1", 80)
    end

    # Shortly after starting Apache, there may be two Passenger instances
    # because Apache reloads the module immediately during startup. To
    # prevent `passenger-config restart-app` from thinking there are two
    # instances, we sleep a little bit here to allow the old instance to
    # go away.
    sleep 1
    eventually(5) do
      instances = PhusionPassenger::AdminTools::InstanceRegistry.new.list
      instances.size == 1
    end
  end

  after :all do
    start_stop_service("httpd", "stop")
    eventually do
      !ping_tcp_socket("127.0.0.1", 80)
    end
    @app_dirs.each do |path|
      rm_rf(path)
    end
    rm("/etc/httpd/conf.d/testapp.conf")
  end

  before :each do
    sh("passenger-config restart-app / --ignore-app-not-running")
  end

  describe "Ruby support" do
    include_examples "Hello world Ruby application"
  end

  describe "Python support" do
    include_examples "Hello world Python application"
  end

  describe "Node.js support" do
    include_examples "Hello world Node.js application"
  end
end

describe "The system's Nginx with Passenger enabled" do
  before :all do
    @app_dirs = create_app_dirs
    cp("/system/internal/test/nginx/vhost.conf", "/etc/nginx/conf.d/testapp.conf")
    chmod(0644, "/etc/nginx/conf.d/testapp.conf")
    sh("sed -i 's/#passenger_root/passenger_root/' /etc/nginx/conf.d/passenger.conf")
    sh("sed -i 's/#passenger_ruby/passenger_ruby/' /etc/nginx/conf.d/passenger.conf")
    start_stop_service("nginx", "start")
    eventually do
      ping_tcp_socket("127.0.0.1", 80)
    end
  end

  after :all do
    start_stop_service("nginx", "stop")
    eventually do
      !ping_tcp_socket("127.0.0.1", 80)
    end
    @app_dirs.each do |path|
      rm_rf(path)
    end
    rm("/etc/nginx/conf.d/testapp.conf")
    sh("sed -i 's/^passenger_root/#passenger_root/' /etc/nginx/conf.d/passenger.conf")
    sh("sed -i 's/^passenger_ruby/#passenger_ruby/' /etc/nginx/conf.d/passenger.conf")
  end

  describe "Ruby support" do
    include_examples "Hello world Ruby application"
  end

  describe "Python support" do
    include_examples "Hello world Python application"
  end

  describe "Node.js support" do
    include_examples "Hello world Node.js application"
  end
end
