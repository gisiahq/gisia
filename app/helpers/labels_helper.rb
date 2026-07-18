module LabelsHelper
  SUGGESTED_COLORS = %w[
    #EF4444 #F97316 #F59E0B #EAB308 #22C55E #10B981 #06B6D4 #0EA5E9
    #3B82F6 #6366F1 #8B5CF6 #D946EF #EC4899 #F43F5E #64748B #6B7280
  ].freeze

  def suggested_colors
    SUGGESTED_COLORS
  end

  def label_form_url(ins, label)
    if label.new_record?
      labels_path(ins)
    else
      namespace_project_settings_label_path(ins.namespace.parent.full_path, ins.namespace.path, label)
    end
  end

  def namespace_label_form_url(namespace, label)
    if label.new_record?
      namespace_settings_labels_path(namespace.full_path)
    else
      namespace_settings_label_path(namespace.full_path, label)
    end
  end

  def labels_path(ins)
    namespace_project_settings_labels_path(ins.namespace.parent.full_path, ins.namespace.path)
  end

  def new_label_path(ins)
    new_form_namespace_project_settings_labels_path(ins.namespace.parent.full_path, ins.namespace.path)
  end

  def edit_label_path(ins, label)
    edit_form_namespace_project_settings_label_path(ins.namespace.parent.full_path, ins.namespace.path, label)
  end

  def delete_label_path(ins, label)
    namespace_project_settings_label_path(ins.namespace.parent.full_path, ins.namespace.path, label)
  end
end
