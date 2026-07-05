json.id member.user_id
json.username member.user.username
json.name member.user.name
json.state member.user.state
json.access_level member.access_level
json.expires_at member.expires_at
json.expired member.expired?
json.web_url "#{Gitlab.config.gitlab.url}/#{member.user.username}"
