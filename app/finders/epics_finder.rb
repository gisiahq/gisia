# frozen_string_literal: true

class EpicsFinder
  include Filterable

  private

  def base_scope
    project.namespace.work_items.where(type: 'Epic')
  end
end
