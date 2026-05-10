# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_mailbox/engine'
require 'action_text/engine'
require 'action_view/railtie'
require 'action_cable/engine'
# require "rails/test_unit/railtie"
require 'gitlab/utils/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Gitlab
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    config.autoload_lib(ignore: %w[assets tasks])

    require_dependency Rails.root.join('lib/gitlab')
    require_dependency Rails.root.join('lib/gitlab/action_cable/config')
    require_dependency Rails.root.join('lib/gitlab/redis/wrapper')
    require_dependency Rails.root.join('lib/gitlab/redis/cache')
    require_dependency Rails.root.join('lib/gitlab/runtime')
    require_dependency Rails.root.join('lib/gitlab/middleware/request_context')

    # Add custom autoload/eager load paths
    additional_paths = %W[
      #{config.root}/app/models/members
      #{config.root}/app/coders
      #{config.root}/app/models/hooks
      #{config.root}/app/facades
    ]
    config.eager_load_paths.push(*additional_paths)
    config.autoload_paths.push(*additional_paths)
    # Don't generate system test files.
    config.generators.system_tests = nil

    # This empty initializer forces the :setup_main_autoloader initializer to run before we load
    # initializers in config/initializers. This is done because autoloading before Zeitwerk takes
    # over is deprecated but our initializers do a lot of autoloading.
    # See https://gitlab.com/gitlab-org/gitlab/issues/197346 for more details
    initializer :move_initializers, before: :load_config_initializers, after: :setup_main_autoloader do
    end

    # We need this for initializers that need to be run before Zeitwerk is loaded
    initializer :before_zeitwerk, before: :setup_main_autoloader, after: :prepend_helpers_path do
      Dir[Rails.root.join('config/initializers_before_autoloader/*.rb')].each do |initializer|
        load_config_initializer(initializer)
      end
    end

    # Cache store
    config.cache_store = :redis_cache_store, Gitlab::Redis::Cache.active_support_config

    MissionControl::Jobs.base_controller_class = 'Admin::ApplicationController'
    MissionControl::Jobs.http_basic_auth_enabled = false

    config.hosts << 'localhost'
    config.hosts << 'unix'
    config.hosts << ENV.fetch('GISIA_HOST', nil)

    # Replace the default in-process and non-durable queuing backend for Active Job.
    config.active_job.queue_adapter = :solid_queue
    config.solid_queue.connects_to = { database: { writing: :queue } }

    # Todo, https://github.com/rails/rails/pull/54872
    config.active_record.schema_format = :sql

    config.active_record.default_column_serializer = Psych

    config.to_prepare do
      Rails.application.config.active_record.yaml_column_permitted_classes = [
        Symbol, Date, Time,
        BigDecimal,
        Gitlab::Diff::Position,
        ActiveSupport::HashWithIndifferentAccess,
        ActiveSupport::TimeWithZone,
        ActiveSupport::TimeZone,
        ActiveSupport::SafeBuffer
      ]

      ActiveRecord.yaml_column_permitted_classes = Rails.application.config.active_record.yaml_column_permitted_classes
    end

    # locale

    config.i18n.enforce_available_locales = false
    config.i18n.fallbacks = [:en]
  end
end
