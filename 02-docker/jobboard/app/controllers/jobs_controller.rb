class JobsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_job,            only: [:show, :edit, :update, :destroy]

  def index
    skip_authorization
    @jobs = policy_scope(Job)
              .includes(:company)
              .recent
              .by_keyword(params[:q])
              .by_location(params[:location])
  end

  def show
    skip_authorization
  end

  def new
    authorize Job
    # Employers must have a company profile before posting a job
    redirect_to new_company_path, alert: "Create your company profile first." \
      unless current_user.company
    @job = current_user.company.jobs.build
  end

  def create
    authorize Job
    @job = current_user.company.jobs.build(job_params)
    if @job.save
      redirect_to @job, notice: "Job posted successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @job
  end

  def update
    authorize @job
    if @job.update(job_params)
      redirect_to @job, notice: "Job updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @job
    @job.destroy
    redirect_to jobs_path, notice: "Job removed."
  end

  private

  def set_job
    @job = Job.find(params[:id])
  end

  def job_params
    params.require(:job).permit(
      :title, :description, :location,
      :salary_min, :salary_max, :job_type
    )
  end
end
