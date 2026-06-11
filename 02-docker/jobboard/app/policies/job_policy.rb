class JobPolicy < ApplicationPolicy
  # Anyone can browse and read jobs
  def index?  = true
  def show?   = true

  # Only employers can create/edit/delete their own jobs
  def create?  = user.employer?
  def new?     = create?
  def update?  = user.employer? && record.company.user == user
  def edit?    = update?
  def destroy? = update?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
