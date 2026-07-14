json.id note.id
json.type note.type
json.body note.note

json.author do
  json.partial! 'api/v4/issues/user', user: note.author
end

json.created_at note.created_at
json.updated_at note.updated_at
json.system note.system?
json.noteable_id note.noteable_id
json.noteable_type note.noteable_type
json.noteable_iid note.noteable.iid
json.project_id note.project&.id
json.discussion_id note.discussion_id

if note.is_a?(DiffNote)
  json.commit_id note.commit_id
  json.position note.position.to_h
end

json.resolvable note.resolvable?
if note.resolvable?
  json.resolved note.resolved?
  if note.resolved_by
    json.resolved_by do
      json.partial! 'api/v4/issues/user', user: note.resolved_by
    end
  else
    json.resolved_by nil
  end
  json.resolved_at note.resolved_at
end

json.internal note.internal?
json.confidential note.internal?
