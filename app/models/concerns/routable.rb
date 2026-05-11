# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

# Store object full path in separate table for easy lookup and uniq validation
# Object must have name and path db fields and respond to parent and parent_changed? methods.
module Routable
  extend ActiveSupport::Concern
  include CaseSensitivity

  included do
  end

  # Finds a Routable object by its full path, without knowing the class.
  #
  # Usage:
  #
  #     Routable.find_by_full_path('groupname')             # -> Group
  #     Routable.find_by_full_path('groupname/projectname') # -> Project
  #
  # Returns a single object, or nil.

  def self.find_by_full_path(path, follow_redirects: false, route_scope: nil)
    return unless path.present?

    route = Route.find_by(path: path.to_s)

    return unless route

    source = route.source
    return source unless route_scope

    source if source.is_a?(route_scope.klass)
  end

  class_methods do
    # Finds a single object by full path match in routes table.
    #
    # Usage:
    #
    #     Klass.find_by_full_path('gitlab-org/gitlab-foss')
    #
    # Returns a single object, or nil.
    def find_by_full_path(path, follow_redirects: false)
      route_scope = all

      Routable.find_by_full_path(
        path,
        follow_redirects: follow_redirects,
        route_scope: route_scope
      )
    end

    def find_by_full_path!(path, follow_redirects: false)
      find_by_full_path(path, follow_redirects: follow_redirects) || raise(ActiveRecord::RecordNotFound)
    end

    # Builds a relation to find multiple objects by their full paths.
    #
    # Usage:
    #
    #     Klass.where_full_path_in(%w{gitlab-org/gitlab-foss gitlab-org/gitlab})
    #
    # Returns an ActiveRecord::Relation.
    def where_full_path_in(paths, preload_routes: true)
      return none if paths.empty?

      path_condition = paths.map do |path|
        "(LOWER(routes.path) = LOWER(#{connection.quote(path)}))"
      end.join(' OR ')

      route_scope = all

      routes_matching_condition = Route.where(path_condition)

      namespace_ids = routes_matching_condition.select(:namespace_id)
      result = route_scope.where(namespace_id: namespace_ids)

      if preload_routes
        result.preload(:route)
      else
        result
      end
    end
  end

  def full_name
    full_attribute(:name)
  end

  def full_path
    full_attribute(:path)
  end

  # Overriden in the Project model
  # parent_id condition prevents issues with parent reassignment
  def parent_loaded?
    association(:parent).loaded?
  end

  def route_loaded?
    association(:route).loaded?
  end

  def full_path_components
    full_path.split('/')
  end

  def build_full_path
    if parent && path
      parent.full_path + '/' + path
    else
      path
    end
  end

  # Group would override this to check from association
  def owned_by?(user)
    owner == user
  end

  def rebuild_route
    route || build_route
    route.path = build_full_path
    route.name = build_full_name
  end

  private

  def full_attribute(attribute)
    attribute_from_route_or_self = lambda do |attribute|
      route&.public_send(attribute) || send("build_full_#{attribute}")
    end

    unless persisted? && ::Feature.enabled?(:cached_route_lookups, self)
      return attribute_from_route_or_self.call(attribute)
    end

    # Return the attribute as-is if the parent is missing
    return public_send(attribute) if route.nil? && parent.nil? && public_send(attribute).present?

    # If the route is already preloaded, return directly, preventing an extra load
    return route.public_send(attribute) if route_loaded? && route.present? && route.public_send(attribute)

    # Similarly, we can allow the build if the parent is loaded
    return send("build_full_#{attribute}") if parent_loaded?

    Gitlab::Cache.fetch_once([cache_key, :"full_#{attribute}"]) do
      attribute_from_route_or_self.call(attribute)
    end
  end

  def set_path_errors
    route_path_errors = errors.delete(:'route.path')
    route_path_errors&.each do |msg|
      errors.add(:path, msg)
    end
  end

  def full_name_changed?
    name_changed? || parent_changed?
  end

  def full_path_changed?
    path_changed? || parent_changed?
  end

  def build_full_name
    if parent && name
      parent.full_name + ' / ' + name
    else
      name
    end
  end

  def prepare_route
    return unless full_path_changed? || full_name_changed?

    rebuild_route
  end
end
