# frozen_string_literal: true

module Projects
  module HasLfs
    extend ActiveSupport::Concern

    included do
      extend Gitlab::Cache::RequestCache

      has_many :lfs_objects_projects, dependent: :destroy
      has_many :lfs_objects, through: :lfs_objects_projects
      has_many :lfs_file_locks, dependent: :destroy

      request_cache(:any_lfs_file_locks?) { self.id }
    end

    # todo: read from project/namespace settings
    def lfs_enabled?
      true
    end

    alias_method :lfs_enabled, :lfs_enabled?

    def any_lfs_file_locks?
      lfs_file_locks.any?
    end

    def lfs_objects_oids(oids: [])
      oids_for(lfs_objects, oids: oids)
    end

    def lfs_objects_oids_from_fork_source(oids: [])
      return [] unless forked?

      oids_for(fork_source.lfs_objects, oids: oids)
    end

    def lfs_objects_for_repository_types(*types)
      LfsObject
        .joins(:lfs_objects_projects)
        .where(lfs_objects_projects: { project: self, repository_type: types })
    end

    private

    def oids_for(objects, oids: [])
      objects = objects.where(oid: oids) if oids.any?

      [].tap do |out|
        objects.each_batch { |relation| out.concat(relation.pluck(:oid)) }
      end
    end
  end
end
