class JobApplication < ApplicationRecord
  belongs_to :user
  belongs_to :job

  has_one_attached :resume

  enum :status, { pending: 0, reviewed: 1, rejected: 2, accepted: 3 }

  validates :cover_letter, presence: true
  validate  :resume_content_type

  # Prevent a candidate from applying to the same job twice
  validates :user_id, uniqueness: { scope: :job_id, message: "already applied to this job" }

  after_create :notify_employer

  private

  def resume_content_type
    return unless resume.attached?
    unless resume.content_type.in?(%w[application/pdf application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document])
      errors.add(:resume, "must be a PDF or Word document")
    end
  end

  def notify_employer
    ApplicationNotificationJob.perform_later(id)
  end
end
