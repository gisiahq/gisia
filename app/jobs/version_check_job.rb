# frozen_string_literal: true

class VersionCheckJob < ApplicationJob
  queue_as :default

  def perform
    return unless Rails.env.production?
    return unless ApplicationSetting.current.version_check_enabled

    encoded = Base64.urlsafe_encode64({ version: Gitlab::VERSION }.to_json)
    uri = URI("https://version.gisia.dev/check?encoded_version=#{encoded}")
    Net::HTTP.get(uri)
  end
end
