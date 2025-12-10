class PayrollsController < ApplicationController
  before_action :set_payroll, only: [ :show, :update, :destroy ]
  # before_action :authorize_payroll_access!

  def index
    # authorize!("payrolls", "index")
    @payrolls = Payroll.all
    render json: @payrolls
  end

  def show
    # authorize!("payrolls", "show")
    render json: @payroll
  end

  def create
    authorize!("payrolls", "create")
    @payroll = Payroll.new(payroll_params)
    if @payroll.save
      render json: @payroll, status: :created
    else
      render json: { errors: @payroll.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    authorize!("payrolls", "update")
    if @payroll.update(payroll_params)
      render json: @payroll
    else
      render json: { errors: @payroll.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize!("payrolls", "destroy")
    @payroll.destroy
    head :no_content
  end

  def process_month
    # Temporary: allow any authenticated user to process payroll (adjust with proper permissions later)
    # authorize!("payrolls", "create")
    month = params[:month] || Date.current
    preview = ActiveModel::Type::Boolean.new.cast(params[:preview])

    result = PayrollProcessor.new(month: month, preview: preview).call

    render json: {
      month: PayrollMonth.label(month),
      processed: result.processed,
      created: result.created,
      updated: result.updated,
      skipped: result.skipped,
      errors: result.errors,
      payrolls: result.payrolls
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity unless performed?
  end

  private

  def set_payroll
    @payroll = Payroll.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def authorize_payroll_access!
    case action_name
    when "index", "show"
      authorize!("payrolls", "index")
    when "create"
      authorize!("payrolls", "create")
    when "update"
      authorize!("payrolls", "update")
    when "destroy"
      authorize!("payrolls", "destroy")
    end
  end

  def payroll_params
    params.require(:payroll).permit(:employee_id, :month, :gross_salary, :net_salary, :status)
  end
end
