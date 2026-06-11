class JobApplicationPolicy < ApplicationPolicy
  # Candidates create; employers view applications to their own jobs
  def new?    = user.candidate?
  def create? = user.candidate?

  def show?
    user.candidate? && record.user == user ||
      user.employer? && record.job.company.user == user
  end

  def update_status? = user.employer? && record.job.company.user == user

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.employer?
        scope.joins(job: :company).where(companies: { user: user })
      else
        scope.where(user: user)
      end
    end
  end
end
