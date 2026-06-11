module Employer
  class BaseController < ApplicationController
    before_action :require_employer

    private

    def require_employer
      redirect_to root_path, alert: "Access denied." unless current_user.employer?
    end
  end
end
