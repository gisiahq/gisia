# frozen_string_literal: true

class Admin::JobsController < Admin::ApplicationController
  before_action :set_job, only: [:cancel]

  def index
    @jobs = Ci::Build.order(created_at: :desc)
    @jobs = @jobs.where(status: params[:status]) if params[:status].present?
    @jobs = @jobs.joins(:runner).where(ci_runners: { id: params[:runner_id] }) if params[:runner_id].present?
    @jobs = @jobs.joins(:project).where(projects: { name: params[:project] }) if params[:project].present?

    @jobs_count = @jobs.count
    @jobs = @jobs.page(params[:page]).per(25)
    @running_count = Ci::Build.running.count
    @pending_count = Ci::Build.pending.count
    @failed_count = Ci::Build.failed.count
    if params[:project_search].present?
      @projects_for_filter = Project.where("name ILIKE ?", "%#{params[:project_search]}%").limit(10)
    else
      @projects_for_filter = Project.limit(5)
    end
    
  end

  def cancel
    if @job.cancelable?
      @job.cancel!
      redirect_to admin_jobs_path, notice: 'Job was successfully canceled.'
    else
      redirect_to admin_jobs_path, alert: 'Job cannot be canceled.'
    end
  end

  def cancel_all
    canceled_count = 0
    Ci::Build.where(status: ['pending', 'running']).find_each do |job|
      if job.cancelable?
        job.cancel!
        canceled_count += 1
      end
    end
    
    redirect_to admin_jobs_path, notice: "#{canceled_count} jobs were canceled."
  end

  def search_projects
    query = params[:q].to_s.strip
    projects = if query.present?
                 Project.where("name ILIKE ?", "%#{query}%").limit(10)
               else
                 Project.limit(5)
               end
    
    render json: projects.pluck(:name)
  end

  private

  def set_job
    @job = Ci::Build.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_jobs_path, alert: 'Job not found.'
  end
end
