module Employer
  class ApplicationsController < BaseController
    before_action :set_application

    def show
      authorize @application, policy_class: JobApplicationPolicy
    end

    def update_status
      authorize @application, :update_status?, policy_class: JobApplicationPolicy
      if @application.update(status: params[:status])
        redirect_to employer_job_application_path(@application.job, @application),
                    notice: "Application status updated."
      else
        redirect_back fallback_location: root_path, alert: "Could not update status."
      end
    end

    private

    def set_application
      job         = current_user.company.jobs.find(params[:job_id])
      @application = job.job_applications.find(params[:id])
    end
  end
end
