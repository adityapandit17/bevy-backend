class TicketCommentsController < ApplicationController
  before_action :set_ticket
  before_action :set_comment, only: [ :update, :destroy ]

  def index
    @comments = @ticket.ticket_comments.includes(:user, :employee).oldest_first
    render json: @comments.as_json(
      include: {
        user: { only: [ :id, :email, :first_name, :last_name ] },
        employee: { only: [ :id, :first_name, :last_name, :email ] }
      },
      methods: [ :author_name, :author_email ]
    )
  end

  def create
    # current_user should be set by JwtAuthenticatable before_action
    # If it's nil, authentication already failed and rendered unauthorized
    # So we can proceed assuming current_user is set

    @comment = @ticket.ticket_comments.build(comment_params)

    # Set user_id or employee_id based on current_user
    # If user has an employee_id, link to employee, otherwise link to user
    if current_user.employee_id.present?
      @comment.employee_id = current_user.employee_id
    else
      @comment.user_id = current_user.id
    end

    if @comment.save
      render json: @comment.as_json(
        include: {
          user: { only: [ :id, :email, :first_name, :last_name ] },
          employee: { only: [ :id, :first_name, :last_name, :email ] }
        },
        methods: [ :author_name, :author_email ]
      ), status: :created
    else
      render json: {
        success: false,
        errors: @comment.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @comment.update(comment_params)
      render json: @comment.as_json(
        include: {
          user: { only: [ :id, :email, :first_name, :last_name ] },
          employee: { only: [ :id, :first_name, :last_name, :email ] }
        },
        methods: [ :author_name, :author_email ]
      )
    else
      render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    head :no_content
  end

  private

  def set_ticket
    @ticket = find_in_tenant(HelpdeskTicket, params[:helpdesk_ticket_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Ticket not found" }, status: :not_found
  end

  def set_comment
    @comment = @ticket.ticket_comments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Comment not found" }, status: :not_found
  end

  def comment_params
    params.require(:ticket_comment).permit(:content)
  end
end
