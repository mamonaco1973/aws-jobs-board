class CompaniesController < ApplicationController
  before_action :set_company, only: [:show, :edit, :update]

  def show
    skip_authorization
    @jobs = @company.jobs.recent
  end

  def new
    authorize Company
    @company = current_user.build_company
  end

  def create
    authorize Company
    @company = current_user.build_company(company_params)
    if @company.save
      redirect_to employer_root_path, notice: "Company profile created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @company
  end

  def update
    authorize @company
    if @company.update(company_params)
      redirect_to @company, notice: "Company updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name, :location, :description, :website)
  end
end
