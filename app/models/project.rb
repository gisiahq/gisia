# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Project < ApplicationRecord
  extend Gitlab::ConfigHelper
  include Gitlab::VisibilityLevel
  include AfterCommitQueue
  include Gitlab::ConfigHelper
  include HasRepository
  include Routable
  include Ci::PredefinedVariables
  include TokenAuthenticatable
  include Projects::HasCiCdSettings
  include Projects::Destroyable
  include Importable
  include Projects::MergeRequests
  include Projects::HasProtectedRefs
  include Projects::HasBoard
  include Projects::HasIssues
  include WithUploads

  belongs_to :namespace, autosave: true, class_name: 'Namespaces::ProjectNamespace',
    foreign_key: 'namespace_id', inverse_of: :project, dependent: :destroy
  has_one :route, through: :namespace
  has_one :project_feature, inverse_of: :project, dependent: :destroy
  has_one :pipeline_settings, class_name: 'ProjectPipelineSetting', inverse_of: :project, dependent: :destroy
  has_many :all_pipelines, class_name: 'Ci::Pipeline', inverse_of: :project, dependent: :destroy
  has_many :variables, class_name: 'Ci::Variable', foreign_key: :namespace_id, primary_key: :namespace_id
  has_many :builds, class_name: 'Ci::Build', inverse_of: :project
  has_many :pipeline_metadata, class_name: 'Ci::PipelineMetadata', inverse_of: :project
  has_many :ci_refs, class_name: 'Ci::Ref', inverse_of: :project, dependent: :destroy
  has_many :merge_requests, dependent: :destroy
  has_many :reviews, dependent: :destroy, inverse_of: :project
  has_many :merge_request_reviewers, dependent: :destroy, inverse_of: :project
  has_many :members, through: :namespace
  has_many :users, through: :namespace
  has_many :protected_branches, through: :namespace, class_name: 'ProtectedBranch'
  has_many :protected_tags, through: :namespace, class_name: 'ProtectedTag'
  has_many :all_protected_branches, through: :namespace, source: :protected_branches, class_name: 'ProtectedBranch'
  has_many :sourced_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :source_project_id
  has_many :source_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :project_id
  has_many :work_items, through: :namespace
  has_many :issues, -> { includes(:namespace) }, through: :namespace
  has_many :epics, -> { where(type: 'Epic').includes(:namespace) }, through: :namespace, source: :work_items, class_name: 'WorkItem'
  has_many :labels, through: :namespace
  has_many :hooks, class_name: 'ProjectHook', through: :namespace, source: :web_hooks
  has_one :board, through: :namespace
  has_many :notification_settings, as: :source, dependent: :delete_all


  accepts_nested_attributes_for :namespace
  accepts_nested_attributes_for :pipeline_settings
  accepts_nested_attributes_for :ci_cd_settings

  LATEST_STORAGE_VERSION = 2
  HASHED_STORAGE_FEATURES = {
    repository: 1,
    attachments: 2
  }.freeze

  INSTANCE_RUNNER_RUNNING_JOBS_MAX_BUCKET = 5

  PROJECT_FEATURES_DEFAULTS = {
    issues: gitlab_config_features.issues,
    merge_requests: gitlab_config_features.merge_requests,
    builds: gitlab_config_features.builds
  }.freeze
  MAX_BUILD_TIMEOUT = 1.month

  attribute :namespace_parent_id
  attribute :repository_storage, default: -> { Repository.pick_storage_shard }
  attr_accessor :creator_id
  alias parent namespace
  alias_attribute :title, :name
  # Todo, remove this if the project policy updated
  alias_attribute :public_builds, :public_jobs

  with_options to: :namespace do
    delegate :root_ancestor
    delegate :has_parent?
    delegate :team
    delegate :owner
    delegate :visibility_level
    delegate :actual_limits, :actual_plan_name, :actual_plan, :root_ancestor, allow_nil: true
    delegate :to_reference_base
  end

  with_options to: :pipeline_settings, allow_nil: true do
    delegate :auto_cancel_pending_pipelines?
    delegate :ci_config_path
    delegate :build_allow_git_fetch
    delegate :build_timeout
  end

  after_initialize :use_hashed_storage
  before_validation :ensure_namespace
  validate :parent_namespace_present
  validates :workflows, workflows: true
  after_commit :create_repository, on: :create
  after_create -> { create_or_load_association(:project_feature) }
  after_create -> { create_or_load_association(:ci_cd_settings) }
  after_create -> { create_or_load_association(:pipeline_settings) }
  after_create :add_creator_as_owner
  after_create :create_default_protected_branch

  add_authentication_token_field :runners_token,
    encrypted: :required,
    format_with_prefix: :runners_token_prefix,
    require_prefix_for_validation: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[name]
  end

  scope :search, ->(query) { where("projects.name ILIKE ?", "%#{query}%") }

  def group
    @group ||= begin
      parent = namespace.parent
      if parent.nil? || parent.type != Group.sti_name
        nil
      else
        parent.group
      end
    end
  end

  def emails_disabled?
    false
  end

  def actual_plan_name
    'default'
  end

  def resolve_outdated_diff_discussions?
    false
  end

  def pending_delete?
    false
  end

  def organization
    nil
  end

  def pages_enabled?
    false
  end

  def root_namespace
    if has_parent?
      namespace.root_ancestor
    else
      namespace
    end
  end

  def repository
    @repository ||= Gitlab::GlRepository::PROJECT.repository_for(self)
  end

  # Check if Hashed Storage is enabled for the project with at least informed feature rolled out
  #
  # @param [Symbol] feature that needs to be rolled out for the project (:repository, :attachments)
  def hashed_storage?(feature)
    raise ArgumentError, _('Invalid feature') unless HASHED_STORAGE_FEATURES.include?(feature)

    storage_version && storage_version >= HASHED_STORAGE_FEATURES[feature]
  end

  def uploads_sharding_key
    { project_id: id }
  end

  def storage
    @storage ||=
      if hashed_storage?(:repository)
        Storage::Hashed.new(self)
      else
        Storage::LegacyProject.new(self)
      end
  end

  def use_hashed_storage
    return unless new_record? && Gitlab::CurrentSettings.hashed_storage_enabled

    self.storage_version = LATEST_STORAGE_VERSION
  end

  def repository_object_format
    # Todo,
    'sha1'
  end

  def repository_read_only?
    false
  end

  def archived?
    false
  end

  def lfs_enabled?
    false
  end

  def beyond_identity_integration; end

  def merge_base_commit(first_commit_id, second_commit_id)
    sha = repository.merge_base(first_commit_id, second_commit_id)
    commit_by(oid: sha) if sha
  end

  # todo
  def ci_config_path_or_default
    Ci::Pipeline::DEFAULT_CONFIG_PATH
  end

  def auto_devops_enabled?
    false
  end

  def licensed_features
    # Todo,
    %w[audit_events
       blocked_issues
       blocked_work_items
       board_iteration_lists
       code_owners
       code_review_analytics
       full_codequality_report
       group_activity_analytics
       group_bulk_edit
       issuable_default_templates
       issue_weights
       iterations
       ldap_group_sync
       merge_request_approvers
       milestone_charts
       multiple_issue_assignees
       multiple_ldap_servers
       multiple_merge_request_assignees
       multiple_merge_request_reviewers
       project_merge_request_analytics
       protected_refs_for_users
       push_rules
       resource_access_token
       seat_link
       seat_usage_quotas
       pipelines_usage_quotas
       transfer_usage_quotas
       product_analytics_usage_quotas
       wip_limits
       zoekt_code_search
       seat_control
       description_diffs
       send_emails_from_admin_area
       repository_size_limit
       maintenance_mode
       scoped_issue_board
       contribution_analytics
       group_webhooks
       member_lock
       elastic_search
       repository_mirrors
       ai_chat
       adjourned_deletion_for_projects_and_groups
       admin_audit_log
       agent_managed_resources
       auditor_user
       blocking_merge_requests
       board_assignee_lists
       board_milestone_lists
       ci_secrets_management
       ci_pipeline_cancellation_restrictions
       cluster_agents_ci_impersonation
       cluster_agents_user_impersonation
       cluster_deployments
       code_owner_approval_required
       code_suggestions
       commit_committer_check
       commit_committer_name_check
       compliance_framework
       custom_compliance_frameworks
       custom_fields
       custom_file_templates
       custom_project_templates
       cycle_analytics_for_groups
       cycle_analytics_for_projects
       db_load_balancing
       default_branch_protection_restriction_in_groups
       default_project_deletion_protection
       delete_unconfirmed_users
       dependency_proxy_for_packages
       disable_extensions_marketplace_for_enterprise_users
       disable_name_update_for_users
       disable_personal_access_tokens
       domain_verification
       epic_colors
       epics
       extended_audit_events
       external_authorization_service_api_management
       feature_flags_code_references
       file_locks
       geo
       generic_alert_fingerprinting
       git_two_factor_enforcement
       group_allowed_email_domains
       group_coverage_reports
       group_forking_protection
       group_level_compliance_dashboard
       group_milestone_project_releases
       group_project_templates
       group_repository_analytics
       group_saml
       group_scoped_ci_variables
       ide_schema_config
       incident_metric_upload
       instance_level_scim
       jira_issues_integration
       ldap_group_sync_filter
       linked_items_epics
       merge_request_performance_metrics
       admin_merge_request_approvers_rules
       merge_trains
       metrics_reports
       multiple_alert_http_integrations
       multiple_approval_rules
       multiple_group_issue_boards
       object_storage
       microsoft_group_sync
       operations_dashboard
       package_forwarding
       packages_virtual_registry
       pages_size_limit
       pages_multiple_versions
       productivity_analytics
       project_aliases
       protected_environments
       reject_non_dco_commits
       reject_unsigned_commits
       related_epics
       remote_development
       saml_group_sync
       service_accounts
       scoped_labels
       smartcard_auth
       ssh_certificates
       swimlanes
       target_branch_rules
       troubleshoot_job
       type_of_work_analytics
       minimal_access_role
       unprotection_restrictions
       ci_project_subscriptions
       incident_timeline_view
       oncall_schedules
       escalation_policies
       zentao_issues_integration
       coverage_check_approval_rule
       issuable_resource_links
       group_protected_branches
       group_level_merge_checks_setting
       oidc_client_groups_claim
       disable_deleting_account_for_users
       disable_private_profiles
       group_saved_replies
       requested_changes_block_merge_request
       project_saved_replies
       default_roles_assignees
       ci_component_usages_in_projects
       branch_rule_squash_options
       work_item_status
       glab_ask_git_command
       generate_commit_message
       summarize_new_merge_request
       summarize_review
       generate_description
       summarize_comments
       review_merge_request
       board_status_lists
       group_ip_restriction
       issues_analytics
       password_complexity
       group_wikis
       email_additional_text
       custom_file_templates_for_namespace
       incident_sla
       export_user_permissions
       cross_project_pipelines
       feature_flags_related_issues
       merge_pipelines
       ci_cd_projects
       github_integration
       ai_agents
       ai_config_chat
       ai_features
       ai_review_mr
       ai_workflows
       amazon_q
       api_discovery
       api_fuzzing
       auto_rollback
       cluster_receptive_agents
       cluster_image_scanning
       external_status_checks
       combined_project_analytics_dashboards
       compliance_pipeline_configuration
       container_scanning
       credentials_inventory
       custom_roles
       dast
       dependency_scanning
       dora4_analytics
       description_composer
       enterprise_templates
       environment_alerts
       evaluate_group_level_compliance_pipeline
       explain_code
       external_audit_events
       experimental_features
       generate_test_file
       ai_generate_cube_query
       git_abuse_rate_limit
       group_ci_cd_analytics
       group_level_compliance_adherence_report
       group_level_compliance_violations_report
       project_level_compliance_dashboard
       project_level_compliance_adherence_report
       project_level_compliance_violations_report
       group_level_analytics_dashboard
       incident_management
       inline_codequality
       insights
       integrations_allow_list
       issuable_health_status
       issues_completed_analytics
       jira_vulnerabilities_integration
       jira_issue_association_enforcement
       kubernetes_cluster_vulnerabilities
       license_scanning
       okrs
       personal_access_token_expiration_policy
       secret_push_protection
       product_analytics
       project_quality_summary
       project_level_analytics_dashboard
       quality_management
       release_evidence_test_artifacts
       report_approver_rules
       required_ci_templates
       requirements
       runner_maintenance_note
       runner_performance_insights
       runner_performance_insights_for_namespace
       runner_upgrade_management
       runner_upgrade_management_for_namespace
       sast
       sast_advanced
       sast_iac
       sast_custom_rulesets
       sast_fp_reduction
       secret_detection
       security_configuration_in_ui
       security_dashboard
       security_inventory
       security_on_demand_scans
       security_orchestration_policies
       security_training
       ssh_key_expiration_policy
       summarize_mr_changes
       stale_runner_cleanup_for_namespace
       status_page
       suggested_reviewers
       subepics
       observability
       unique_project_download_limit
       vulnerability_finding_signatures
       container_scanning_for_registry
       security_exclusions
       security_scans_api
       observability_alerts
       measure_comment_temperature
       coverage_fuzzing
       devops_adoption
       group_level_devops_adoption
       instance_level_devops_adoption]
  end

  def hook_attrs
    {
      id: id,
      name: name,
      description: description,
      web_url: web_url,
      # avatar_url: avatar_url(only_path: false),
      git_ssh_url: ssh_url_to_repo,
      git_http_url: http_url_to_repo,
      namespace: namespace.name,
      visibility_level: visibility_level,
      path_with_namespace: full_path,
      default_branch: default_branch,
      ci_config_path: ci_config_path_or_default,
      homepage: web_url,
      url: url_to_repo,
      ssh_url: ssh_url_to_repo,
      http_url: http_url_to_repo
    }
  end

  def full_path_slug
    Gitlab::Utils.slugify(full_path.to_s)
  end

  def protected_for?(ref)
    raise Repository::AmbiguousRefError if repository.ambiguous_ref?(ref)

    resolved_ref = repository.expand_ref(ref) || ref
    return false unless Gitlab::Git.tag_ref?(resolved_ref) || Gitlab::Git.branch_ref?(resolved_ref)

    ref_name = if resolved_ref == ref
                 Gitlab::Git.ref_name(resolved_ref)
               else
                 ref
               end

    if Gitlab::Git.branch_ref?(resolved_ref)
      ProtectedBranch.protected?(self, ref_name)
    elsif Gitlab::Git.tag_ref?(resolved_ref)
      ProtectedTag.protected?(self, ref_name)
    end
  end

  def builds_enabled?
    !!project_feature&.builds_enabled?
  end

  def import_in_progress?
    false
  end

  def build_allow_git_fetch
    true
  end

  def instance_runner_running_jobs_count
    # excluding currently started job
    ::Ci::RunningBuild.instance_type.where(project_id: id)
                      .limit(INSTANCE_RUNNER_RUNNING_JOBS_MAX_BUCKET + 1).count - 1
  end

  def shared_runners_enabled?
    # Todo, move to database
    true
  end

  def project_features_defaults
    PROJECT_FEATURES_DEFAULTS
  end

  def group_runners_enabled?
    return false unless ci_cd_settings

    ci_cd_settings.group_runners_enabled?
  end

  def visibility_level_field
    :visibility_level
  end

  def external_authorization_classification_label; end

  # Todo,
  def releases
    @null_releases ||= Object.new.tap { |o| o.define_singleton_method(:find_by_tag) { |_| nil } }
  end

  # Todo, mv to settings
  def enforce_auth_checks_on_uploads?
    true
  end

  def self_or_ancestors_archived?
    # We can remove `archived?` once we move the project archival to the `namespaces.archived` column
    archived? || namespace.self_or_ancestors_archived?
  end

  def shared_runners_enabled?
    true
  end

  def shared_runners_available?
    shared_runners_enabled?
  end

  def shared_runners
    @shared_runners ||= shared_runners_enabled? ? Ci::Runner.instance_type : Ci::Runner.none
  end

  def available_shared_runners
    @available_shared_runners ||= shared_runners_available? ? shared_runners : Ci::Runner.none
  end


  def all_runners
    Ci::Runner.from_union([shared_runners])
  end

  def all_available_runners
    Ci::Runner.from_union([available_shared_runners])
  end

  def any_online_runners?(&block)
    online_runners_with_tags.any?(&block)
  end

  def online_runners_with_tags
    @online_runners_with_tags ||= active_runners.online
  end

  def active_runners
    strong_memoize(:active_runners) do
      all_available_runners.active
    end
  end

  private

  def runners_token_prefix
    RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX
  end

  def create_repository
    repository.create_repository(default_branch, object_format: repository_object_format)
  rescue StandardError => e
    Gitlab::ErrorTracking.track_exception(e, project: { id: id, full_path: full_path, disk_path: disk_path })
    errors.add(:base, 'Failed to create repository')
    false
  end

  def ensure_namespace
    self.namespace ||= Namespaces::ProjectNamespace.new(creator_id: creator_id)
    self.namespace.name = name
    self.namespace.path = path
    self.namespace.parent_id = namespace_parent_id if namespace_parent_id.present?
  end

  def add_creator_as_owner
    ProjectMember.create!(
      user: namespace.owner,
      access_level: Gitlab::Access::OWNER,
      namespace: namespace
    )
  end

  def parent_namespace_present
    return unless namespace.parent.blank?

    errors.add(:namespace, 'must have a parent namespace')
  end

end
