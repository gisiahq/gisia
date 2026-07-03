# frozen_string_literal: true

module VerifiesParentNamespace
  extend ActiveSupport::Concern

  private

  def verify_parent_namespace!
    parent_id = requested_parent_namespace_id
    return if parent_id.blank?
    return if creatable_parent_namespaces.exists?(id: parent_id.to_i)

    reject_parent_namespace!
  end

  def creatable_parent_namespaces
    current_user.namespaces_for_project_creation
  end

  def reject_parent_namespace!
    head :forbidden
  end
end
