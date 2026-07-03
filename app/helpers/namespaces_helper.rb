# frozen_string_literal: true

module NamespacesHelper
  def can_access_namespace_settings?(namespace, user)
    return false unless user
    return true if user.admin?

    user.max_member_access_for_namespace(namespace) >= Accessible::MAINTAINER
  end
end
