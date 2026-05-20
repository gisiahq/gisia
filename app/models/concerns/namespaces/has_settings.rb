# frozen_string_literal: true

module Namespaces
  module HasSettings
    extend ActiveSupport::Concern

    included do
      after_create :ensure_namespace_settings
    end

    def ensure_namespace_settings
      create_namespace_settings! unless namespace_settings
    end
  end
end
