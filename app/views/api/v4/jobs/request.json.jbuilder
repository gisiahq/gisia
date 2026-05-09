json.id              @job.id
json.token           @job.token
json.allow_git_fetch @job.allow_git_fetch
json.job_info do
  json.partial! 'job_info'
end
json.git_info do
  json.partial! 'git_info'
end
json.runner_info do
  json.partial! 'runner_info'
end

json.variables @job.runner_variables

unless @job.execution_config&.run_steps.present?
  json.steps @job.steps do |step|
    json.partial! 'step', step: step
  end
end

json.hooks @job.runtime_hooks do |hook|
  json.partial! 'hook', hook: hook
end

json.image do
  if @job.image
    json.partial! 'image', image: @job.image
  else
    json.nil!
  end
end


json.services @job.services do |service|
  json.partial! 'service', service: service
end

json.artifacts(@job.artifacts || []) do |artifact|
  json.partial! 'artifacts', artifacts: artifact
end

json.cache @job.cache do |single_cache|
  json.partial! 'cache', cache: single_cache
end

json.credentials @job.credentials do |credential|
  json.partial! 'credential', credential: credential
end

json.features @job.features

json.dependencies @job.all_dependencies do |dependency|
  json.partial! 'dependency', dependency: dependency, running_job: @job
end

if @job.execution_config&.run_steps.present?
  json.run @job.execution_config.run_steps
end


