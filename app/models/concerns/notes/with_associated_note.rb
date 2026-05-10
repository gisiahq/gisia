# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

# `#note_namespace_id`: This method needs to be defined in the model
module Notes
  module WithAssociatedNote
    extend ActiveSupport::Concern

    included do
      validates :namespace_id, presence: true, on: :create, unless: -> { skip_namespace_validation? }

      before_validation :ensure_namespace_id, on: :create, unless: -> { skip_namespace_validation? }

      private

      def skip_namespace_validation?
        false
      end

      def ensure_namespace_id
        self.namespace_id ||= note_namespace_id
      end

      def note_namespace_id
        raise NoMethodError, 'must implement `note_namespace_id` method'
      end
    end
  end
end
