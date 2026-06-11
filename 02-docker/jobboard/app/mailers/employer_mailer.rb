class EmployerMailer < ApplicationMailer
  # Notify employer when a new application arrives for one of their jobs.
  def new_application(application)
    @application = application
    @job         = application.job
    @employer    = @job.company.user
    @candidate   = application.user

    mail(
      to:      @employer.email,
      subject: "New application for #{@job.title}"
    )
  end
end
