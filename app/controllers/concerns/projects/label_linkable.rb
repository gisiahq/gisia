# frozen_string_literal: true

module Projects
  module LabelLinkable
    extend ActiveSupport::Concern

    private

    def available_label_ids
      return [] if label_params.empty?

      project.available_labels.where(id: label_params).pluck(:id)
    end
  end
end
