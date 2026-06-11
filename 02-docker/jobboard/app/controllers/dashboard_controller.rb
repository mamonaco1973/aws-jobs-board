class DashboardController < ApplicationController
  def index
    skip_authorization
    if current_user.employer?
      redirect_to employer_root_path
    else
      @applications = current_user.job_applications
                        .includes(:job)
                        .order(created_at: :desc)
    end
  end
end
