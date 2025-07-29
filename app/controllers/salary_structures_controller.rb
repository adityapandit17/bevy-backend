class SalaryStructuresController < ApplicationController
  def index
  end

  def show
  end

  def create
    @salary_structure = SalaryStructure.new(salary_structure_params)
    if @salary_structure.save
      render json: @salary_structure, status: :created
    else
      render json: { errors: @salary_structure.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @salary_structure.update(salary_structure_params)
      render json: @salary_structure
    else
      render json: { errors: @salary_structure.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
  end
end
