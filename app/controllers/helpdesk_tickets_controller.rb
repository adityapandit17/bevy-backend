class HelpdeskTicketsController < ApplicationController
  before_action :set_ticket, only: [ :show, :update, :destroy ]

  def index
    @tickets = HelpdeskTicket.includes(:assigned_to, :requester).all

    # Apply filters
    @tickets = @tickets.by_priority(params[:priority]) if params[:priority].present?
    @tickets = @tickets.by_status(params[:status]) if params[:status].present?
    @tickets = @tickets.by_category(params[:category]) if params[:category].present?

    # Search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @tickets = @tickets.where("title ILIKE ? OR description ILIKE ?", search_term, search_term)
    end

    render json: @tickets.as_json(
      include: {
        assigned_to: { only: [ :id, :first_name, :last_name, :email ] },
        requester: { only: [ :id, :first_name, :last_name, :email ] }
      },
      methods: [ :tags_list, :sla_display, :assigned_to_name, :requester_name ]
    )
  end

  def show
    render json: @ticket.as_json(
      include: {
        assigned_to: { only: [ :id, :first_name, :last_name, :email ] },
        requester: { only: [ :id, :first_name, :last_name, :email ] }
      },
      methods: [ :tags_list, :sla_display, :assigned_to_name, :requester_name ]
    )
  end

  def create
    @ticket = HelpdeskTicket.new(ticket_params)
    @ticket.tags_list = params[:helpdesk_ticket][:tags] if params[:helpdesk_ticket][:tags].present?
    if @ticket.save
      render json: @ticket.as_json(
        include: {
          assigned_to: { only: [ :id, :first_name, :last_name, :email ] },
          requester: { only: [ :id, :first_name, :last_name, :email ] }
        },
        methods: [ :tags_list, :sla_display, :assigned_to_name, :requester_name ]
      ), status: :created
    else
      render json: { errors: @ticket.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @ticket.tags_list = params[:helpdesk_ticket][:tags] if params[:helpdesk_ticket][:tags].present?
    if @ticket.update(ticket_params)
      render json: @ticket.as_json(
        include: {
          assigned_to: { only: [ :id, :first_name, :last_name, :email ] },
          requester: { only: [ :id, :first_name, :last_name, :email ] }
        },
        methods: [ :tags_list, :sla_display, :assigned_to_name, :requester_name ]
      )
    else
      render json: { errors: @ticket.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @ticket.destroy
    head :no_content
  end

  def stats
    stats = {
      open_tickets: HelpdeskTicket.open.count,
      in_progress_tickets: HelpdeskTicket.in_progress.count,
      resolved_tickets: HelpdeskTicket.resolved.count,
      avg_response_time: calculate_avg_response_time,
      sla_compliance: calculate_sla_compliance,
      knowledge_articles: KnowledgeArticle.published.count
    }
    render json: stats
  end

  private

  def set_ticket
    @ticket = HelpdeskTicket.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Ticket not found" }, status: :not_found
  end

  def ticket_params
    params.require(:helpdesk_ticket).permit(:title, :description, :category, :priority, :status,
                                            :assigned_to_id, :requester_id, :sla_hours, :sla_status,
                                            :channel, tags: [])
  end

  def calculate_avg_response_time
    # Placeholder - implement actual calculation based on ticket history
    "2.4h"
  end

  def calculate_sla_compliance
    total = HelpdeskTicket.count
    return 0 if total.zero?
    on_track = HelpdeskTicket.where(sla_status: "on-track").count
    ((on_track.to_f / total) * 100).round(1)
  end
end
