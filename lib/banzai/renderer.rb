# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Banzai
  module Renderer
    def self.render(text, context = {})
      return '' unless text.present?

      html = CommonMarker.render_html(text, :DEFAULT, [:table, :strikethrough, :autolink, :tagfilter, :tasklist])

      # Basic sanitization
      Sanitize.fragment(html, Sanitize::Config::RELAXED).html_safe
    end

    def self.post_process(html, context)
      # For now, just return the HTML as-is
      # In the future, this could handle project-specific links, mentions, etc.
      html.html_safe
    end

    def self.render_field(object, field, context = {})
      unless object.respond_to?(:cached_markdown_fields)
        return cacheless_render_field(object, field, context)
      end

      object.refresh_markdown_cache! unless object.cached_html_up_to_date?(field)
      object.cached_html_for(field)
    end

    def self.cacheless_render_field(object, field, context = {})
      text = object.__send__(field) # rubocop:disable GitlabSecurity/PublicSend
      context = context.reverse_merge(object.banzai_render_context(field)) if object.respond_to?(:banzai_render_context)

      cacheless_render(text, context)
    end

    def self.cacheless_render(text, context = {})
      render(text, context)
    end

    def self.render_result(text, context = {})
      { output: render(text, context) }
    end

    def self.cache_collection_render(texts_and_contexts)
      texts_and_contexts.map do |item|
        render(item[:text], item[:context])
      end
    end
  end
end