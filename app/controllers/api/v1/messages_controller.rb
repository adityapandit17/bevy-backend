class Api::V1::MessagesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!
  before_action :set_channel
  before_action :set_message, only: [ :show, :update, :destroy ]

  # GET /api/v1/channels/:channel_id/messages
  def index
    unless @channel.member?(current_user)
      return render json: { success: false, error: "Not a member of this channel" }, status: :forbidden
    end

    messages = @channel.messages.includes(:user)
                      .order(created_at: :asc)

    # Pagination
    per_page = params[:per_page]&.to_i || 50
    page = params[:page]&.to_i || 1
    total = messages.count
    messages = messages.limit(per_page).offset((page - 1) * per_page)

    # Mark as read
    membership = @channel.channel_memberships.find_by(user: current_user)
    membership&.mark_as_read!

    render json: {
      success: true,
      messages: messages.map { |message| format_message(message) },
      pagination: {
        page: page,
        per_page: per_page,
        total: total,
        total_pages: (total.to_f / per_page).ceil
      }
    }
  end

  # GET /api/v1/channels/:channel_id/messages/:id
  def show
    render json: {
      success: true,
      message: format_message(@message)
    }
  end

  # POST /api/v1/channels/:channel_id/messages
  def create
    unless @channel.member?(current_user)
      return render json: { success: false, error: "Not a member of this channel" }, status: :forbidden
    end

    @message = @channel.messages.build(message_params)
    @message.user = current_user

    if @message.save
      render json: {
        success: true,
        message: format_message(@message)
      }, status: :created
    else
      render json: {
        success: false,
        errors: @message.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/channels/:channel_id/messages/:id
  def update
    unless @message.user == current_user
      return render json: { success: false, error: "Not authorized" }, status: :forbidden
    end

    if @message.update(message_params)
      @message.mark_as_edited!
      render json: {
        success: true,
        message: format_message(@message)
      }
    else
      render json: {
        success: false,
        errors: @message.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/channels/:channel_id/messages/:id
  def destroy
    unless @message.user == current_user || current_user.super_admin?
      return render json: { success: false, error: "Not authorized" }, status: :forbidden
    end

    @message.destroy
    render json: { success: true, message: "Message deleted" }
  end

  private

  def set_channel
    @channel = Channel.find(params[:channel_id])
  end

  def set_message
    @message = @channel.messages.find(params[:id])
  end

  def message_params
    params.require(:message).permit(:content)
  end

  def format_message(message)
    {
      id: message.id,
      channel_id: message.channel_id,
      user_id: message.user_id,
      user_name: message.user.name,
      user_email: message.user.email,
      content: message.content,
      edited_at: message.edited_at&.iso8601,
      created_at: message.created_at.iso8601,
      updated_at: message.updated_at.iso8601
    }
  end
end
