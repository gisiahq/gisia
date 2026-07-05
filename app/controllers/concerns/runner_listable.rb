# frozen_string_literal: true

# Loads a paginated list of runners available at a given scope (own + inherited +
# instance) and computes, without any cross-database join:
#   @runners               - the paginated relation
#   @runner_source         - { runner => { name:, path: } } for the owning namespace
#                            (nil for instance runners, which have no source)
#   @manageable_runner_ids - ids of runners owned by `owner_namespace_id` (editable here)
module RunnerListable
  extend ActiveSupport::Concern

  RUNNERS_PER_PAGE = 25

  private

  def filter_runner_list(relation, owner_namespace_id:)
    @runners = relation.order(id: :desc).page(params[:page]).per(RUNNERS_PER_PAGE).preload(:tags)

    namespace_id_by_runner = ::Ci::Runner.runners_namespace_ids(@runners)
    namespaces = owning_namespaces(namespace_id_by_runner.values)

    @runner_source = @runners.index_with do |runner|
      runner_source_for(namespaces[namespace_id_by_runner[runner.id]])
    end
    @manageable_runner_ids = @runners
      .select { |runner| namespace_id_by_runner[runner.id] == owner_namespace_id }
      .map(&:id)
      .to_set
  end

  def owning_namespaces(namespace_ids)
    Namespace.where(id: namespace_ids.uniq).index_by(&:id)
  end

  def runner_source_for(namespace)
    return unless namespace

    { name: namespace.name, path: namespace_web_path(namespace) }
  end

  def namespace_web_path(namespace)
    if namespace.is_a?(Namespaces::ProjectNamespace)
      namespace_project_path(namespace.parent.full_path, namespace.path)
    else
      namespace_show_path(namespace.full_path)
    end
  end
end
