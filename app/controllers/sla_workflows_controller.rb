class SLAWorkflowsController < ApplicationController
  before_action :set_workflow, only: [ :show, :update, :destroy ]

  def index
    @workflows = SlaWorkflow.all

    # Apply filters
    @workflows = @workflows.by_category(params[:category]) if params[:category].present?
    @workflows = @workflows.by_priority(params[:priority]) if params[:priority].present?
    @workflows = @workflows.where(status: params[:status]) if params[:status].present?

    render json: @workflows.as_json(
      methods: [ :escalation_levels_list, :sla_display, :avg_resolution_display ]
    )
  end

  def show
    render json: @workflow.as_json(
      methods: [ :escalation_levels_list, :sla_display, :avg_resolution_display ]
    )
  end

  def create
    @workflow = SlaWorkflow.new(workflow_params)
    @workflow.escalation_levels_list = params[:sla_workflow][:escalation_levels] if params[:sla_workflow][:escalation_levels].present?
    if @workflow.save
      render json: @workflow.as_json(
        methods: [ :escalation_levels_list, :sla_display, :avg_resolution_display ]
      ), status: :created
    else
      render json: { errors: @workflow.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @workflow.update(workflow_params)
      render json: @workflow.as_json(
        methods: [ :escalation_levels_list, :sla_display, :avg_resolution_display ]
      )
    else
      render json: { errors: @workflow.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @workflow.destroy
    head :no_content
  end

  private

  def set_workflow
    @workflow = SlaWorkflow.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Workflow not found" }, status: :not_found
  end

  def workflow_params
    params.require(:sla_workflow).permit(:name, :category, :priority, :sla_hours, :status,
                                         :tickets_handled, :avg_resolution_hours)
  end
end
