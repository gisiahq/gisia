json.id lfs_file_lock.id.to_s
json.path lfs_file_lock.path
json.locked_at lfs_file_lock.created_at.to_fs(:iso8601)
json.owner do
  json.name lfs_file_lock.user&.username
end
