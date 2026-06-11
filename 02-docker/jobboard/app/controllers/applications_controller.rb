class ApplicationsController < ApplicationController
  before_action :set_job

  def new
    @application = @job.job_applications.build
    authorize @application, policy_class: JobApplicationPolicy
  end

  def create
    @application = @job.job_applications.build(application_params)
    @application.user = current_user
    authorize @application, policy_class: JobApplicationPolicy

    if @application.save
      redirect_to @job, notice: "Application submitted successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_job
    @job = Job.find(params[:job_id])
  end

  def application_params
    params.require(:job_application).permit(:cover_letter, :resume)
  end
end
