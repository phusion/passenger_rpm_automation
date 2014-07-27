require 'fileutils'
require 'thread'
require 'stringio'
require 'singleton'
require File.expand_path(File.dirname(__FILE__) + '/preprocessor')

MUTEX = Mutex.new
SUPPORTED_ARCHS = ['i386', 'x86_64']

class TrackingDatabase
  include Singleton

  attr_accessor :thread
  attr_accessor :category_list
  attr_reader :start_time

  def initialize
    @category_list = []
    @categories = {}
    @start_time = Time.now
    @finished = false
  end

  def register_category(name, description)
    category = TrackingCategory.new(name, description)
    @category_list << category
    @categories[name] = category
  end

  def [](name)
    @categories[name]
  end

  def each_category
    @category_list.each do |category|
      yield category
    end
  end

  def set_finished!
    @finished = true
  end

  def finished?
    @finished
  end

  def has_errors?
    each_category do |category|
      category.each_task do |task|
        if task.state == :error
          return true
        end
      end
    end
    false
  end

  #### Thread-safe methods ####

  def duration_description
    distance_of_time_in_hours_and_minutes(@start_time, Time.now)
  end
end

class TrackingCategory
  attr_reader :name, :description

  def initialize(name, description)
    @name = name
    @description = description
    @task_list = []
    @tasks = {}
  end

  def register_task(name)
    task = TrackingTask.new(name, self)
    @task_list << task
    @tasks[name] = task
  end

  def [](name)
    @tasks[name]
  end

  def each_task
    @task_list.each do |task|
      yield task
    end
  end
end

class TrackingTask
  attr_accessor :state
  attr_accessor :start_time

  def initialize(name, category)
    @name = name
    @category = category
    @state = :not_started
  end

  def set_running!
    @state = :running
    @start_time = Time.now
  end

  def set_done!
    @state = :done
    @end_time = Time.now
  end

  def set_error!
    @state = :error
    @end_time = Time.now
  end

  def state_name
    state.to_s.gsub('_', ' ')
  end

  def elapsed
    if @start_time
      (@end_time || Time.now) - @start_time
    else
      nil
    end
  end

  def duration_description
    if @start_time
      distance_of_time_in_hours_and_minutes(@start_time, @end_time || Time.now)
    else
      nil
    end
  end

  #### Thread-safe methods ####

  attr_reader :name, :category

  def display_name
    name.to_s.gsub(/[:\.]/, ' ')
  end

  def sh(command)
    sh_with_tracking("#{category.name}:#{name}", command)
  end

  def log(message)
    track_log("#{category.name}:#{name}", message)
  end
end

def recursive_copy_files(files, destination_dir, preprocess = false, variables = {})
  if !STDOUT.tty?
    puts "Copying files..."
  end
  files.each_with_index do |filename, i|
    dir = File.dirname(filename)
    if !File.exist?("#{destination_dir}/#{dir}")
      FileUtils.mkdir_p("#{destination_dir}/#{dir}")
    end
    if !File.directory?(filename)
      if preprocess && filename =~ /\.template$/
        real_filename = filename.sub(/\.template$/, '')
        FileUtils.install(filename, "#{destination_dir}/#{real_filename}", :preserve => true)
        Preprocessor.new.start(filename, "#{destination_dir}/#{real_filename}",
          variables)
      else
        FileUtils.install(filename, "#{destination_dir}/#{filename}", :preserve => true)
      end
    end
    if STDOUT.tty?
      printf "\r[%5d/%5d] [%3.0f%%] Copying files...", i + 1, files.size, i * 100.0 / files.size
      STDOUT.flush
    end
  end
  if STDOUT.tty?
    printf "\r[%5d/%5d] [%3.0f%%] Copying files...\n", files.size, files.size, 100
  end
end

def string_option(name, default_value = nil)
  value = ENV[name]
  if value.nil? || value.empty?
    default_value
  else
    value
  end
end

def boolean_option(name, default_value = false)
  value = ENV[name]
  if value.nil? || value.empty?
    default_value
  else
    value == "yes" || value == "on" || value == "true" || value == "1"
  end
end

def get_distros_option
  if distros = string_option('DISTROS')
    distros.split(/[, ]/)
  else
    abort("Please set the DISTROS option.")
  end
end

def get_archs_option
  if archs = string_option('ARCHS')
    archs.split(/[, ]/)
  else
    abort("Please set the ARCHS option.")
  end
end

def load_passenger
  if !defined?(PhusionPassenger)
    require "/passenger/lib/phusion_passenger"
    PhusionPassenger.locate_directories
    PhusionPassenger.require_passenger_lib "constants"
  end
end

def detect_passenger_version
  load_passenger
  PhusionPassenger::VERSION_STRING
end

def detect_nginx_version
  load_passenger
  PhusionPassenger::PREFERRED_NGINX_VERSION
end

def enterprise?
  load_passenger
  defined?(PhusionPassenger::PASSENGER_IS_ENTERPRISE) &&
    PhusionPassenger::PASSENGER_IS_ENTERPRISE
end

def initialize_tracking_database!
  TrackingDatabase.instance
  TrackingDatabase.instance.thread = Thread.new do
    Thread.current.abort_on_exception = true
    while true
      sleep 5
      MUTEX.synchronize do
        dump_tracking_database(false)
      end
    end
  end
end

def check_distros_supported!
  DISTROS.each do |distro_id|
    if !SUPPORTED_DISTROS[distro_id]
      abort("Unsupported distribution: #{distro_id}. Supported distributions are: #{SUPPORTED_DISTROS.keys.join(' ')}")
    end
  end
end

def check_archs_supported!
  ARCHS.each do |arch|
    if !SUPPORTED_ARCHS.include?(arch)
      abort("Unsupported architecture: #{arch}. Supported architectures are: #{SUPPORTED_ARCHS.keys.join(' ')}")
    end
  end
end

def clean_bundler_env!
  clean_env = nil
  Bundler.with_clean_env do
    clean_env = ENV.to_hash
  end
  ENV.replace(clean_env)
end

def register_tracking_category(name, description)
  TrackingDatabase.instance.register_category(name, description)
end

def register_tracking_task(category_name, task_name)
  TrackingDatabase.instance[category_name].register_task(task_name)
end

def track_task(category_name, task_name)
  succeeded = false
  task = nil
  MUTEX.synchronize do
    category = TrackingDatabase.instance[category_name]
    task = category[task_name]
    task.set_running!
    puts "----- Task started: #{category.description} -> #{task_name} -----"
    dump_tracking_database
  end
  begin
    yield(task)
    succeeded = true
    puts
  ensure
    if succeeded
      task.set_done!
      puts "----- Task done: #{task.category.description} -> #{task_name} -----"
    else
      task.set_error!
      puts "----- Task errored: #{task.category.description} -> #{task_name} -----"
    end
    dump_tracking_database
  end
end

def dump_tracking_database(print_to_stdout = true)
  io = StringIO.new
  io.puts "Current time: #{format_time(Time.now)}"
  io.puts "Start time  : #{format_time(TrackingDatabase.instance.start_time)}"
  io.puts "Duration    : #{TrackingDatabase.instance.duration_description}"
  if TrackingDatabase.instance.finished?
    io.puts "*** FINISHED ***"
  end
  if TrackingDatabase.instance.has_errors?
    io.puts "*** THERE WERE ERRORS ***"
  end

  io.puts
  TrackingDatabase.instance.each_category do |category|
    io.puts "#{category.description}:"
    category.each_task do |task|
      io.printf "  * %-25s: %-12s\n",
        task.display_name,
        task.state_name
      if task.start_time
        io.printf "    %25s  started %s\n", nil, format_time(task.start_time)
      end
      if desc = task.duration_description
        io.printf "    %25s  duration %s\n", nil, desc
      end
    end
    io.puts
  end

  if print_to_stdout
    puts "---------------------------------------------"
    puts io.string
    puts "---------------------------------------------"
  end

  File.open("/output/log/state.log", "w") do |f|
    f.write(io.string)
  end
end

def distance_of_time_in_hours_and_minutes(from_time, to_time)
  from_time = from_time.to_time if from_time.respond_to?(:to_time)
  to_time = to_time.to_time if to_time.respond_to?(:to_time)
  dist = (to_time - from_time).to_i
  minutes = (dist.abs / 60).round
  hours = minutes / 60
  minutes = minutes - (hours * 60)
  seconds = dist - (hours * 3600) - (minutes * 60)

  words = ''
  words << "#{hours} #{hours > 1 ? 'hours' : 'hour' } " if hours > 0
  words << "#{minutes} min " if minutes > 0
  words << "#{seconds} sec"
  words
end

def passenger_srpm_name(distro_id)
  "#{PASSENGER_RPM_NAME}-#{PASSENGER_RPM_VERSION}-#{PASSENGER_RPM_RELEASE}.#{distro_id}.src.rpm"
end

def nginx_srpm_name(distro_id)
  "#{NGINX_RPM_NAME}-#{NGINX_RPM_VERSION}-#{NGINX_RPM_RELEASE}.#{distro_id}.src.rpm"
end

def format_time(time)
  time.strftime("%Y-%m-%d %H:%M:%S")
end

def logfile_path_for_tracking_name(name)
  name = name.gsub(/[: ]/, '.')
  "/output/log/#{name}.log"
end

def sh_with_tracking(name, command)
  logfile = logfile_path_for_tracking_name(name)
  time = format_time(Time.now)
  puts "#{name}: #{time} -- #{command}"
  if !system("/system/internal/tracking_helper", name, logfile, "/bin/bash", "-c", command)
    abort "*** Command failed: #{command}"
  end
end

def track_log(name, message)
  time = format_time(Time.now)
  message = "#{name}: #{time} -- #{message}"
  puts message
  File.open(logfile_path_for_tracking_name(name), "a") do |f|
    f.puts(message)
  end
end
