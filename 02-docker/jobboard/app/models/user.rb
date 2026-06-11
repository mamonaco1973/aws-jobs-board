class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { candidate: 0, employer: 1 }

  has_one  :company, dependent: :destroy
  has_many :job_applications, dependent: :destroy

  # Employer must have a company before posting jobs
  def setup_complete?
    candidate? || (employer? && company.present?)
  end
end
