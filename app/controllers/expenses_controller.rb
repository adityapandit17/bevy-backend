# frozen_string_literal: true

class ExpensesController < ApplicationController
  before_action :set_expense, only: [ :show, :update, :destroy ]

  def index
    expenses = Expense.includes(:employee).recent
    expenses = expenses.by_category(params[:category])
    expenses = expenses.where(employee_id: params[:employee_id]) if params[:employee_id].present?
    expenses = expenses.where(status: params[:status]) if params[:status].present?

    if params[:search].present?
      q = "%#{params[:search].downcase}%"
      expenses = expenses.where("LOWER(title) LIKE :q OR LOWER(description) LIKE :q", q: q)
    end

    render json: expenses.map { |e| format_expense(e) }
  end

  def show
    render json: format_expense(@expense)
  end

  def create
    expense = Expense.new(expense_params)
    expense.employee_id ||= current_user&.employee_id
    if expense.save
      render json: format_expense(expense), status: :created
    else
      render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @expense.update(expense_params)
      render json: format_expense(@expense)
    else
      render json: { errors: @expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    head :no_content
  end

  def stats
    expenses = Expense.all
    render json: {
      total_count: expenses.count,
      total_amount: expenses.sum(:amount),
      by_category: expenses.group(:category).sum(:amount),
      pending_approval: expenses.where(status: "submitted").count
    }
  end

  private

  def set_expense
    @expense = Expense.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Expense not found" }, status: :not_found
  end

  def expense_params
    params.require(:expense).permit(
      :employee_id, :title, :amount, :category, :expense_date,
      :description, :payment_method, :receipt_url, :status, tags: []
    )
  end

  def format_expense(expense)
    {
      id: expense.id,
      title: expense.title,
      amount: expense.amount.to_f,
      category: expense.category,
      date: expense.expense_date.iso8601,
      description: expense.description,
      paymentMethod: expense.payment_method,
      tags: expense.tags || [],
      receipt: expense.receipt_url,
      status: expense.status,
      employee_id: expense.employee_id,
      employee_name: expense.employee_name
    }
  end
end
