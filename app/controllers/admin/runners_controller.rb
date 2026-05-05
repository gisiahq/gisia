# frozen_string_literal: true

class Admin::RunnersController < Admin::ApplicationController
  include RunnerSetupScripts

  before_action :set_runner, only: [:show, :edit, :update, :destroy, :register, :resume, :pause]

  def index
    @runners = Ci::Runner.order(id: :desc)

    if params[:status].present?
      case params[:status]
      when 'active'
        @runners = @runners.where(active: true)
      when 'paused'
        @runners = @runners.where(active: false)
      when 'online'
        @runners = @runners.online
      when 'offline'
        @runners = @runners.offline
      end
    end

    @runners_count = @runners.count
    @runners = @runners.page(params[:page]).per(25)
  end

  def create
    @runner = Ci::Runner.new(runner_type: :instance_type, registration_type: :authenticated_user)
    @runner.assign_attributes(runner_params)

    if @runner.save
      redirect_to register_admin_runner_path(@runner), notice: 'Runner created. Please register it.'
    else
      render :create, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @runner.update(runner_params)
      redirect_to admin_runner_path(@runner), notice: 'Runner was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @runner.destroy
    redirect_to admin_runners_path, notice: 'Runner was successfully deleted.'
  end

  def resume
    @runner.update(active: true)
    redirect_to admin_runner_path(@runner), notice: 'Runner resumed.'
  end

  def pause
    @runner.update(active: false)
    redirect_to admin_runner_path(@runner), notice: 'Runner paused.'
  end

  def new
    @runner = Ci::Runner.new
  end

  def register
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false unless @runner.registration_available?
  end

  private

  def set_runner
    @runner = Ci::Runner.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = 'Runner not found'
    redirect_to admin_runners_path
  end

  def runner_params
    params.require(:runner).permit(:description, :run_untagged, :maximum_timeout).merge(
      tag_list: params.dig(:runner, :tags).to_s.split(',').map(&:strip),
      active: params.dig(:runner, :paused) != "1"
    )
  end
end
