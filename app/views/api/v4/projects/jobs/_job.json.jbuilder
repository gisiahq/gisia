json.id job.id
json.name job.name
json.status job.status
json.stage job.stage
json.ref job.ref
json.sha job.pipeline.sha
json.allow_failure job.allow_failure
json.created_at job.created_at
json.started_at job.started_at
json.finished_at job.finished_at
json.duration job.duration
json.queued_duration job.queued_at ? (job.started_at || Time.current) - job.queued_at : nil
json.artifacts_expire_at job.artifacts_expire_at
json.web_url "#{Gitlab.config.gitlab.url}/#{job.project.full_path}/-/jobs/#{job.id}"

json.pipeline do
  json.id job.pipeline.id
  json.iid job.pipeline.iid
  json.ref job.pipeline.ref
  json.sha job.pipeline.sha
  json.status job.pipeline.status
end

json.user do
  if job.user
    json.id job.user.id
    json.name job.user.name
    json.username job.user.username
  end
end
