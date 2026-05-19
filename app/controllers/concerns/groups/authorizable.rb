# frozen_string_literal: true

module Groups::Authorizable
  extend ActiveSupport::Concern

  private

  def user_groups
    Namespace.where(id: current_user.authorized_groups.select(:namespace_id))
  end

  def authorize_group!(ability, namespace)
    Ability.allowed?(current_user, ability, namespace)
  end
end
