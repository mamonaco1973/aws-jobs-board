module Employer
  class JobsController < BaseController
    def index
      skip_authorization
      @company = current_user.company
      @jobs    = @company ? @company.jobs.recent.includes(:job_applications) : []
    end

    def show
      skip_authorization
      @job          = current_user.company.jobs.find(params[:id])
      @applications = @job.job_applications
                        .includes(:user)
                        .order(created_at: :desc)
    end
  end
end
