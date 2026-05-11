json.valid result.valid?
json.errors result.errors
json.warnings result.warnings
json.merged_yaml result.merged_yaml
json.includes result.includes do |inc|
  json.type inc[:type]
  json.location inc[:location]
  json.blob inc[:blob]
  json.raw inc[:raw]
  json.extra inc[:extra]
  json.context_project inc[:context_project]
  json.context_sha inc[:context_sha]
end
if params[:include_jobs]
  json.jobs result.jobs do |job|
    json.name job[:name]
    json.stage job[:stage]
    json.before_script job[:before_script]
    json.script job[:script]
    json.after_script job[:after_script]
    json.tag_list job[:tag_list]
    json.only job[:only]
    json.except job[:except]
    json.environment job[:environment]
    json.when job[:when]
    json.allow_failure job[:allow_failure]
    json.needs job[:needs]
  end
end
