class CompanyPolicy < ApplicationPolicy
  # Only employers can create/edit a company profile
  def new?    = user.employer?
  def create? = user.employer? && user.company.nil?
  def edit?   = user.employer? && record == user.company
  def update? = edit?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
