# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Notify < ApplicationMailer
  include ActionDispatch::Routing::PolymorphicRoutes

  include Emails::WorkItems
  include Emails::MergeRequests
  include Emails::Notes
  include Emails::Reviews
  include Emails::Members

  helper EmailsHelper
  helper MembersHelper
  helper GitlabRoutingHelper

  def message_id(model)
    model_name = model.class.model_name.singular_route_key
    "<#{model_name}_#{model.id}@#{Gitlab.config.gitlab.host}>"
  end

  private

  def sender(sender_id)
    return unless User.exists?(sender_id)

    default_sender_address.format
  end

  def mail_thread(model, headers = {})
    add_project_headers
    add_model_headers(model)

    @reason = headers['X-Gisia-NotificationReason']

    mail_with_locale(headers)
  end

  def mail_new_thread(model, headers = {})
    headers['Message-ID'] = message_id(model)
    mail_thread(model, headers)
  end

  def mail_answer_thread(model, headers = {})
    headers['Message-ID'] = "<#{SecureRandom.hex}@#{Gitlab.config.gitlab.host}>"
    headers['In-Reply-To'] = message_id(model)
    headers['References'] = [message_id(model)]

    headers[:subject] = "Re: #{headers[:subject]}" if headers[:subject]

    mail_thread(model, headers)
  end

  def mail_answer_note_thread(model, note, headers = {})
    headers['Message-ID'] = message_id(note)
    headers['In-Reply-To'] = message_id(model)
    headers['References'] = [message_id(model), message_id(note)].uniq

    headers[:subject] = "Re: #{headers[:subject]}" if headers[:subject]

    mail_thread(model, headers)
  end

  def add_project_headers
    return unless @project

    headers['X-Gisia-Project'] = @project.name
    headers['X-Gisia-Project-Id'] = @project.id
    headers['X-Gisia-Project-Path'] = @project.full_path
  end

  def add_model_headers(object)
    prefix = "X-Gisia-#{object.class.name.gsub(/::/, '-')}"
    headers["#{prefix}-ID"] = object.id
    headers["#{prefix}-IID"] = object.iid if object.respond_to?(:iid)
  end

  def email_with_layout(to:, subject:)
    mail_with_locale(to: to, subject: subject) do |format|
      format.html { render layout: 'mailer' }
      format.text { render layout: 'mailer' }
    end
  end
end
