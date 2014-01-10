require 'json'
require 'yaml'
require 'logger'

LOGGER = Logger.new(STDOUT)
DIR = File.expand_path(File.dirname(__FILE__))

def is_master_commit_push?(payload)
  payload["ref"] == "refs/heads/master"
end

def find_project(payload)
  repo_name = payload["repository"]["name"]
  projects = YAML.load_file("projects.yml")
  projects[repo_name]
end

def schedule_build(project_dir)
  command = "/tools/silence-unless-failed chpst -l /var/cache/passenger_ci/lock " +
    "./invoke #{project_dir} test"
  log "Executing command: #{command}"
  IO.popen("at now", "w") do |f|
    f.puts("cd #{DIR}/..")
    f.puts(command)
  end
  true
end

def process_request(request, payload)
  if is_master_commit_push?(payload)
    if project_dir = find_project(payload)
      schedule_build(project_dir)
    else
      log "Cannot find project"
      false
    end
  else
    log "Unrecognized request"
    false
  end
end

def log(message)
  LOGGER.info "[passenger_rpm_automation webhook] #{message}"
end

app = lambda do |env|
  request = Rack::Request.new(env)
  if !(payload = request.params["payload"])
    payload = env['rack.input'].read
  end
  if process_request(request, JSON.parse(payload))
    [200, { "Content-Type" => "text/plain" }, ["ok"]]
  else
    [500, { "Content-Type" => "text/plain" }, ["Internal server error"]]
  end
end

run app
