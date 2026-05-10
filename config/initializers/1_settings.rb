# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

require_relative '../settings'
require_relative '../object_store_settings'
# require_relative '../../lib/gitlab/temporarily_allow.rb'
# require_relative '../../lib/gitlab/gitaly_client/storage_settings'

# Default settings
Settings['shared'] ||= {}
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.shared['path'] = Settings.absolute(Settings.shared['path'] || 'shared')

Settings['encrypted_settings'] ||= {}
Settings.encrypted_settings['path'] ||= File.join(Settings.shared['path'], 'encrypted_settings')
Settings.encrypted_settings['path'] = Settings.absolute(Settings.encrypted_settings['path'])

#
# GitLab
#
Settings['gitlab'] ||= {}
Settings.gitlab['host'] ||= ENV['GISIA_HOST'] || 'localhost'
Settings.gitlab['https']        = false if Settings.gitlab['https'].nil?
Settings.gitlab['port']       ||= ENV['GISIA_PORT'] || (Settings.gitlab.https ? 443 : 80)
Settings.gitlab['relative_url_root'] ||= ENV['RAILS_RELATIVE_URL_ROOT'] || ''
# / is not a valid relative URL root
Settings.gitlab['relative_url_root']   = '' if Settings.gitlab['relative_url_root'] == '/'
Settings.gitlab['protocol'] ||= Settings.gitlab.https ? 'https' : 'http'
Settings.gitlab['cdn_host'] ||= ENV['GISIA_CDN_HOST'].presence
Settings.gitlab['ssh_host'] ||= Settings.gitlab.host
Settings.gitlab['base_url'] ||= Settings.__send__(:build_base_gitlab_url)
Settings.gitlab['url'] ||= Settings.__send__(:build_gitlab_url)
Settings.gitlab['user'] ||= 'git'
Settings.gitlab['ssh_user'] ||= Settings.gitlab.user
Settings.gitlab['max_request_duration_seconds'] ||= 57
Settings.gitlab['max_attachment_size'] ||= 100
Settings.gitlab['impersonation_enabled'] ||= false if Settings.gitlab['impersonation_enabled'].nil?
Settings.gitlab['signin_enabled'] ||= true if Settings.gitlab['signin_enabled'].nil?

Settings.gitlab['email_enabled'] ||= false if Settings.gitlab['email_enabled'].nil?
Settings.gitlab['email_from'] ||= ENV['GITLAB_EMAIL_FROM'] || "gisia@#{Settings.gitlab.host}"
Settings.gitlab['email_display_name'] ||= ENV['GITLAB_EMAIL_DISPLAY_NAME'] || 'Gisia'
Settings.gitlab['email_reply_to'] ||= ENV['GITLAB_EMAIL_REPLY_TO'] || "noreply@#{Settings.gitlab.host}"
Settings.gitlab['email_subject_prefix'] ||= ENV['GITLAB_EMAIL_SUBJECT_PREFIX'] || ""
Settings.gitlab['email_subject_suffix'] ||= ENV['GITLAB_EMAIL_SUBJECT_SUFFIX'] || ""

Settings.gitlab['smtp'] ||= {}
Settings.gitlab['smtp']['enabled']             ||= false
Settings.gitlab['smtp']['address']             ||= 'localhost'
Settings.gitlab['smtp']['port']                ||= 25
Settings.gitlab['smtp']['user_name']           ||= nil
Settings.gitlab['smtp']['password']            ||= nil
Settings.gitlab['smtp']['domain']              ||= nil
Settings.gitlab['smtp']['authentication']      ||= nil
Settings.gitlab['smtp']['tls']                 ||= false
Settings.gitlab['smtp']['enable_starttls_auto']  = true
Settings.gitlab['smtp']['openssl_verify_mode'] ||= 'peer'

Settings.gitlab['default_projects_features'] ||= {}
Settings.gitlab.default_projects_features['issues']             = true
Settings.gitlab.default_projects_features['merge_requests']     = true
Settings.gitlab.default_projects_features['builds']             = true
Settings.gitlab.default_projects_features['visibility_level']   = 0 # VisibilityLevel::PRIVATE

#
# GitLab Shell
#
Settings['gitlab_shell'] ||= {}
Settings.gitlab_shell['path'] =
  Settings.absolute(Settings.gitlab_shell['path'] || (Settings.gitlab['user_home'] + '/gitlab-shell/'))
Settings.gitlab_shell['hooks_path'] = :deprecated_use_gitlab_shell_path_instead
Settings.gitlab_shell['authorized_keys_file'] ||= File.join(Dir.home, '.ssh', 'authorized_keys')
Settings.gitlab_shell['secret_file'] ||= Rails.root.join('.gitlab_shell_secret')
Settings.gitlab_shell['receive_pack']   = true if Settings.gitlab_shell['receive_pack'].nil?
Settings.gitlab_shell['upload_pack']    = true if Settings.gitlab_shell['upload_pack'].nil?
Settings.gitlab_shell['ssh_host']     ||= Settings.gitlab.ssh_host
Settings.gitlab_shell['ssh_port']     ||= 22
Settings.gitlab_shell['ssh_user']       = Settings.gitlab.ssh_user
Settings.gitlab_shell['owner_group']  ||= Settings.gitlab.user
Settings.gitlab_shell['ssh_path_prefix'] ||= Settings.__send__(:build_gitlab_shell_ssh_path_prefix)
Settings.gitlab_shell['git_timeout'] ||= 10_800

#
# Error Reporting and Logging with Sentry
#
Settings['sentry'] ||= {}
Settings.sentry['enabled'] ||= false
Settings.sentry['dsn'] ||= nil
Settings.sentry['environment'] ||= nil
Settings.sentry['clientside_dsn'] ||= nil

#
# Git
#
Settings['git'] ||= {}
Settings.git['bin_path'] ||= '/usr/bin/git'

#
# Rack::Attack settings
#
Settings['rack_attack'] ||= {}
Settings.rack_attack['git_basic_auth'] ||= {}
Settings.rack_attack.git_basic_auth['enabled'] = false if Settings.rack_attack.git_basic_auth['enabled'].nil?
Settings.rack_attack.git_basic_auth['ip_whitelist'] ||= %w[127.0.0.1]
Settings.rack_attack.git_basic_auth['maxretry'] ||= 10
Settings.rack_attack.git_basic_auth['findtime'] ||= 1.minute
Settings.rack_attack.git_basic_auth['bantime'] ||= 1.hour


#
# Gitaly
#
Settings['gitaly'] ||= {}

#
# CI
#
Settings['gitlab_ci'] ||= {}
Settings.gitlab_ci['shared_runners_enabled'] = true if Settings.gitlab_ci['shared_runners_enabled'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.gitlab_ci['builds_path']           = Settings.absolute(Settings.gitlab_ci['builds_path'] || 'builds/')
Settings.gitlab_ci['url']                 ||= Settings.__send__(:build_gitlab_ci_url)
Settings.gitlab_ci['server_fqdn']         ||= Settings.__send__(:build_server_fqdn)

#
# CI Secure Files
#
Settings['ci_secure_files'] ||= {}
Settings.ci_secure_files['enabled']      = true if Settings.ci_secure_files['enabled'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.ci_secure_files['storage_path'] =
  Settings.absolute(Settings.ci_secure_files['storage_path'] || File.join(Settings.shared['path'], 'ci_secure_files'))
Settings.ci_secure_files['object_store'] =
  ObjectStoreSettings.legacy_parse(Settings.ci_secure_files['object_store'], 'secure_files')

#
# Pages
#
Settings['pages'] ||= {}
Settings.pages['enabled'] = false
Settings.pages['access_control'] = false

#
# Packages
#
Settings['packages'] ||= {}
Settings.packages['enabled'] = false


#
# Registry
#
Settings['registry'] ||= {}
Settings.registry['enabled'] ||= false
Settings.registry['host'] ||= "example.com"
Settings.registry['port'] ||= nil
Settings.registry['api_url'] ||= "http://localhost:5000/"
Settings.registry['key'] ||= nil
Settings.registry['issuer'] ||= nil
Settings.registry['host_port'] ||= [Settings.registry['host'], Settings.registry['port']].compact.join(':')
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.registry['path']            = Settings.absolute(Settings.registry['path'] || File.join(Settings.shared['path'], 'registry'))
Settings.registry['notifications'] ||= []

#
# Dependency Proxy
#
Settings['dependency_proxy'] ||= {}
Settings.dependency_proxy['enabled']      = true if Settings.dependency_proxy['enabled'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.dependency_proxy['storage_path'] = Settings.absolute(Settings.dependency_proxy['storage_path'] || File.join(Settings.shared['path'], "dependency_proxy"))
Settings.dependency_proxy['object_store'] = ObjectStoreSettings.legacy_parse(Settings.dependency_proxy['object_store'], 'dependency_proxy')

# For first iteration dependency proxy uses Rails server to download blobs.
# To ensure acceptable performance we only allow feature to be used with
# multithreaded web-server Puma. This will be removed once download logic is moved
# to GitLab workhorse
Settings.dependency_proxy['enabled'] = false unless Gitlab::Runtime.puma?

#
# Build Artifacts
#
Settings['artifacts'] ||= {}
Settings.artifacts['enabled']      = true if Settings.artifacts['enabled'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.artifacts['storage_path'] = Settings.absolute(Settings.artifacts.values_at('path', 'storage_path').compact.first || File.join(Settings.shared['path'], "artifacts"))
# Settings.artifact['path'] is deprecated, use `storage_path` instead
Settings.artifacts['path']         = Settings.artifacts['storage_path']
Settings.artifacts['max_size'] ||= 100 # in megabytes
Settings.artifacts['object_store'] = ObjectStoreSettings.legacy_parse(Settings.artifacts['object_store'], 'artifacts')


#
# External merge request diffs
#
Settings['external_diffs'] ||= {}
Settings.external_diffs['enabled']      = false if Settings.external_diffs['enabled'].nil?
Settings.external_diffs['when']         = 'always' if Settings.external_diffs['when'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.external_diffs['storage_path'] = Settings.absolute(Settings.external_diffs['storage_path'] || File.join(Settings.shared['path'], 'external-diffs'))
Settings.external_diffs['object_store'] = ObjectStoreSettings.legacy_parse(Settings.external_diffs['object_store'], 'external_diffs')


#
# Git LFS
#
Settings['lfs'] ||= {}
Settings.lfs['enabled']      = true if Settings.lfs['enabled'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.lfs['storage_path'] = Settings.absolute(Settings.lfs['storage_path'] || File.join(Settings.shared['path'], "lfs-objects"))
Settings.lfs['object_store'] = ObjectStoreSettings.legacy_parse(Settings.lfs['object_store'], 'lfs')

#
# Uploads
#
Settings['uploads'] ||= {}
Settings.uploads['storage_path'] = Settings.absolute(Settings.uploads['storage_path'] || 'public')
Settings.uploads['base_dir'] = Settings.uploads['base_dir'] || 'uploads/-/system'
Settings.uploads['object_store'] = ObjectStoreSettings.legacy_parse(Settings.uploads['object_store'], 'uploads')
Settings.uploads['object_store']['remote_directory'] ||= 'uploads'


#
# Workhorse
#
Settings['workhorse'] ||= {}
Settings.workhorse['secret_file'] ||= Rails.root.join('.gitlab_workhorse_secret')


#
# Cell
#
Settings['cell'] ||= {}
Settings.cell['enabled'] ||= false
Settings.cell['id'] ||= nil
Settings.cell['database'] ||= {}
Settings.cell.database['skip_sequence_alteration'] ||= false

#
# Extra customization
#
Settings['extra'] ||= {}
Settings.extra['maximum_text_highlight_size_kilobytes'] = Settings.extra.fetch('maximum_text_highlight_size_kilobytes', 512)
