source 'https://rubygems.org'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 8.0.4.1'
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem 'propshaft'
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.6.1'
# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 7.2'
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'
gem 'kaminari', '~> 1.2.2'
gem 'ransack', '~> 4.3'
# fix ambiguous warning
gem 'stringio', '3.1.7'
# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem 'bcrypt', '~> 3.1.7'
gem 'lexxy', '~> 0.8.0.beta'

# Markdown
gem 'gitlab-markup', '~> 2.0.0', require: 'github/markup'
gem 'commonmarker', '~> 0.23.10'
gem 'kramdown', '~> 2.5.0'
gem 'sanitize', '~> 6.0.2'
gem 'gitlab-glfm-markdown', '~> 0.0.41'
gem 'html-pipeline', '~> 2.14.3'
gem 'rouge', '~> 4.7.0'


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem 'mission_control-jobs', '~> 1.0', '>= 1.0.2'
gem 'solid_cable', '~> 3.0', '>= 3.0.7'
gem 'solid_cache', '~> 1.0', '>= 1.0.7'
gem 'solid_queue', '~> 1.1', '>= 1.1.3'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem 'kamal', require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem 'thruster', require: false

# Files attachments
gem 'carrierwave', '~> 1.3'
gem 'mini_magick', '~> 4.12'
gem 'marcel', '~> 1.0.4'
gem 'ruby-magic', '~> 0.6.0'

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

gem 'sentry-rails', '~> 5.23.0'
gem 'sentry-ruby', '~> 5.23.0'
gem 'sentry-sidekiq', '~> 5.23.0'

gem 'devise', '~> 4.9', '>= 4.9.4'
gem 'doorkeeper', '~> 5.8', '>= 5.8.1'

gem 'haml-rails', '~> 2.0'
gem 'jwt', '~> 2.10', '>= 2.10.1'
gem 'rails_icons', '~> 1.2'
gem 'tailwindcss-rails', '~> 4.4'
gem 'tailwindcss-ruby', '~> 4.1', '>= 4.1.16'

gem 'attr_encrypted', '~> 4.2'
## Local Gems
gem 'gitlab-safe_request_store', path: 'gems/gitlab-safe_request_store'
gem 'gitlab-utils', path: 'gems/gitlab-utils'

gem 'gitaly', '~> 18.10.0'
gem 'gitlab-labkit', '~> 1.5.0'
gem 'gitlab-net-dns', '~> 0.15.0'

# Parse time & duration
gem 'gitlab-chronic', '~> 0.10.5'
gem 'gitlab_chronic_duration', '~> 0.12'

gem 'google-protobuf', '~> 4.34', '>= 4.34.1'
gem 'grpc', '= 1.80.0'

gem 'charlock_holmes', '~> 0.7.9'
gem 'licensee', '~> 9.16'
gem 're2', '~> 2.15'
gem 'ssh_data', '~> 2.0'

gem 'connection_pool', '~> 2.5.3'
gem 'redis', '~> 5.4.1'
gem 'redis-actionpack', '~> 5.5.0'
gem 'redis-client', '~> 0.25'
gem 'redis-cluster-client', '~> 0.13'
gem 'redis-clustering', '~> 5.4.0'

gem 'sidekiq', '~> 7.3', '>= 7.3.9'

gem 'declarative_policy', '~> 2.1.0'
gem 'rugged', '~> 1.9'
gem 'state_machines-activerecord', '~> 0.100.0'

# todo, config for sidekiq
gem 'batch-loader', '~> 2.0.5'

# Snowplow events trackin
gem 'snowplow-tracker', '~> 0.8.0'

# json
gem 'jsonb_accessor', '~> 1.4'
gem 'json_schemer', '~> 2.4'
gem 'oj', '~> 3.16', '>= 3.16.10'

# HAML
gem 'diff_match_patch', '~> 0.1.0', path: 'vendor/gems/diff_match_patch'
gem 'diffy', '~> 3.4', '>= 3.4.3'
gem 'hamlit', '~> 3.0.0'

# Feature toggles
# gem 'flipper', '~> 1.3', '>= 1.3.3'
# gem 'flipper-active_record', '~> 1.3', '>= 1.3.3'
# gem 'flipper-active_support_cache_store', '~> 1.3', '>= 1.3.3'
# gem 'unleash', '~> 6.1', '>= 6.1.2'
gem 'gitlab-experiment', '~> 1.3.0'

# for backups
gem 'fog-aws', '~> 3.26'
# Locked until fog-google resolves https://github.com/fog/fog-google/issues/421.
# Also see config/initializers/fog_core_patch.rb.
gem 'fog-core', '~> 2.5'
gem 'fog-google', '~> 1.29.0', require: 'fog/google'
gem 'fog-local', '~> 0.8'
# NOTE:
# the fog-aliyun gem since v0.4 pulls in aliyun-sdk transitively, which monkey-patches
# the rest-client gem to drop the Content-Length header field for chunked transfers,
# which may have knock-on effects on other features using `RestClient`.
# We may want to update this dependency if this is ever addressed upstream, e.g. via
# https://github.com/aliyun/aliyun-oss-ruby-sdk/pull/93
gem 'fog-aliyun', '~> 0.4'
gem 'gitlab-fog-azure-rm', '~> 2.4.0', require: 'fog/azurerm'

gem 'rubyzip', '~> 2.4.0', require: 'zip'

gem 'apollo_upload_server', '~> 2.1.6'

# dummy
gem "gvltools", "~> 0.4.0"
gem 'circuitbox', '2.0.0'

# Events
gem 'wisper', '~> 3.0'

# I18n
gem 'rails-i18n', '~> 8.0', '>= 8.0.2'
gem 'gettext_i18n_rails', '~> 2.0'

group :development, :test do
  gem 'gettext', '~> 3.5', '>= 3.5.1', require: false
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails', '~> 8.0', '>= 8.0.2'
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'byebug', '~> 11.1', '>= 11.1.3'
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem 'rack-mini-profiler', '~> 4.0', '>= 4.0.1', require: false
  gem 'rubocop-rails-omakase', require: false
  gem 'licensed', '~> 5.0', '>= 5.0.4', require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'foreman', '~> 0.88.1'
  gem 'html2haml', '~> 2.3'
  gem 'rubocop', '~> 1.72', '>= 1.72.2'
  gem 'web-console'
  gem 'jsbundling-rails', '~> 1.3', '>= 1.3.1'
end

group :test do
  gem 'retest', '2.4.0'
  gem 'shoulda-matchers', '~> 6.5'
  gem 'test-prof', '~> 1.6'
  gem 'capybara', '~> 3.40'
  gem 'cuprite', '~> 0.17'
end
