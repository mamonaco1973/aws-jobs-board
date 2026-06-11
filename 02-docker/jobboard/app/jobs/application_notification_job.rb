class ApplicationNotificationJob < ApplicationJob
  queue_as :default

  # Enqueued by JobApplication after_create — sends email to employer via Sidekiq.
  def perform(application_id)
    application = JobApplication.find_by(id: application_id)
    return unless application

    EmployerMailer.new_application(application).deliver_now
  end
end
