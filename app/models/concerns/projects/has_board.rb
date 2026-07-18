# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Projects
  module HasBoard
    extend ActiveSupport::Concern

    included do
      after_create :initial_default_board
    end

    private

    def initial_default_board
      initial_workflow_labels
      board = initial_board
      initial_stages(board) if board
    end

    def initial_workflow_labels
      find_or_create_workflow_label('workflow::todo', '#66b5d5')
      find_or_create_workflow_label('workflow::working_on', '#ff7700')
    end

    def find_or_create_workflow_label(title, color)
      available_labels.find_by(title: title) ||
        namespace.labels.create(title: title, color: color)
    end

    def initial_board
      return namespace.board if namespace.board.present?

      create_welcome_issue

      Board.create!(
        namespace: namespace,
        updated_by_id: namespace.creator_id
      )
    end

    def initial_stages(board)
      todo_label = available_labels.find_by(title: 'workflow::todo')
      working_on_label = available_labels.find_by(title: 'workflow::working_on')

      board.stages.find_or_create_by(title: 'Todo') do |stage|
        stage.label_ids = [todo_label.id]
        stage.rank = 0
      end

      board.stages.find_or_create_by(title: 'Working On') do |stage|
        stage.label_ids = [working_on_label.id]
        stage.rank = 1
      end

      board.stages.find_or_create_by(title: 'Closed') do |stage|
        stage.kind = :closed
        stage.label_ids = []
        stage.rank = 20
      end
    end

    def create_welcome_issue
      template = load_default_issue_template
      return unless template

      todo_label = available_labels.find_by(title: 'workflow::todo')
      return unless todo_label

      namespace.issues.find_or_create_by(title: template['title']) do |issue|
        issue.description = template['description']
        issue.author_id = namespace.creator_id
        issue.labels << todo_label
      end
    end

    def load_default_issue_template
      template_path = Rails.root.join('config/fixtures/default_issues.yml')
      return nil unless File.exist?(template_path)

      data = YAML.load_file(template_path)
      data&.dig('default_issue')
    end
  end
end

