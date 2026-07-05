# frozen_string_literal: true

class Dashboard::GroupsController < Dashboard::ApplicationController
  include Groups::Authorizable
  include VerifiesParentNamespace

  before_action :set_group, only: %i[edit update destroy]
  before_action :set_available_namespaces, only: %i[new create edit update]
  before_action :verify_parent_namespace!, only: %i[create update]
  before_action -> { authorize_group!(:admin_namespace, @group.namespace) || redirect_unauthorized }, only: %i[edit update]
  before_action -> { authorize_group!(:remove_namespace, @group.namespace) || redirect_unauthorized }, only: %i[destroy]

  def index
    @groups = order_pinned_first(current_user.authorized_groups).page(params[:page]).per(20)
  end

  def new
    @group = Group.new
    @group.namespace_parent_id = new_params[:parent_id]
  end

  def create
    @group = Group.new(group_params)
    @group.build_namespace unless @group.namespace
    @group.namespace.creator_id = current_user.id
    if @group.save
      redirect_to namespace_show_path(@group.namespace.full_path), notice: _('Group was successfully created.')
    else
      render :new
    end
  end

  def edit
    @group.namespace_parent_id = @group.namespace.parent_id
  end

  def update
    if @group.update(group_params)
      redirect_to namespace_show_path(@group.namespace.full_path), notice: _('Group was successfully updated.')
    else
      render :edit
    end
  end

  def destroy
    @group.destroy!

    redirect_to dashboard_groups_path, status: :see_other, notice: _('Group was successfully destroyed.')
  end

  private

  def set_group
    @group = Group.find_by_full_path!(params[:id])
  end

  def group_params
    @group_params ||= params.require(:group).permit(:name, :path, :namespace_parent_id, :description,
      namespace_attributes: %i[id visibility_level])
  end

  def new_params
    @new_params ||= params.permit(:parent_id)
  end

  def set_available_namespaces
    @available_namespaces = current_user.namespaces_for_group_creation
  end

  def requested_parent_namespace_id
    group_params[:namespace_parent_id]
  end

  def creatable_parent_namespaces
    current_user.namespaces_for_group_creation
  end

  def reject_parent_namespace!
    redirect_to dashboard_groups_path, alert: _('You are not authorized to use this namespace.')
  end

  def redirect_unauthorized
    redirect_to dashboard_groups_path, alert: _('You are not authorized to perform this action.')
  end
end
