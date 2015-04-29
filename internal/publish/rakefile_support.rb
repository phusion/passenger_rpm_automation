require_relative '../lib/distro_info'

REPOSITORY = ENV['REPOSITORY']
YANK       = ENV['YANK'] == 'true'
SHOW_TASKS = ENV['SHOW_TASKS'] == 'true'
SHOW_OVERVIEW_PERIODICALLY = ENV['SHOW_OVERVIEW_PERIODICALLY'] == 'true'

def initialize_rakefile!
  STDOUT.sync = true
  STDERR.sync = true
  Dir.chdir("/system/internal/publish")
  Kernel.const_set(:DISTROS, infer_distros_info)
end

def infer_distros_info
  result = []
  Dir["/output/*"].each do |path|
    dir = File.basename(path)
    dir =~ /^el(.+)/
    distro_version = $1
    result << [dir, distro_version]
  end
  result
end

def retry_at_most(task, max)
  tries = 0
  begin
    tries += 1
    yield
  rescue TrackingTask::CommandError => e
    if tries < max
      task.log(Paint["*** Retrying command: #{tries + 1} of #{max}", :yellow])
      sleep 0.5 + rand(0.5)
      retry
    else
      raise e
    end
  end
end
