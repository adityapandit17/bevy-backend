class Api::V1::HuddlesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!
  before_action :set_channel
  before_action :set_huddle, only: [:show, :destroy, :join, :leave]

  # GET /api/v1/channels/:channel_id/huddles
  def index
    unless @channel.member?(current_user)
      return render json: { success: false, error: "Not a member of this channel" }, status: :forbidden
    end

    huddles = @channel.huddles.active.includes(:started_by, :participants)
    
    render json: {
      success: true,
      huddles: huddles.map { |huddle| format_huddle(huddle) }
    }
  end

  # GET /api/v1/channels/:channel_id/huddles/:id
  def show
    unless @channel.member?(current_user)
      return render json: { success: false, error: "Not a member of this channel" }, status: :forbidden
    end

    render json: {
      success: true,
      huddle: format_huddle(@huddle)
    }
  end

  # POST /api/v1/channels/:channel_id/huddles
  def create
    unless @channel.member?(current_user)
      return render json: { success: false, error: "Not a member of this channel" }, status: :forbidden
    end

    # Check if there's already an active huddle
    existing_huddle = @channel.huddles.active.first
    if existing_huddle
      # Join existing huddle
      existing_huddle.add_participant(current_user)
      render json: {
        success: true,
        huddle: format_huddle(existing_huddle),
        message: "Joined existing huddle"
      }, status: :ok
      return
    end

    # Create new huddle
    @huddle = @channel.huddles.build(
      started_by: current_user,
      status: "active",
      started_at: Time.current
    )

    if @huddle.save
      @huddle.add_participant(current_user)
      
      # Broadcast huddle started event to all channel members
      ActionCable.server.broadcast(
        "chat_channel_#{@channel.id}",
        {
          type: "huddle_started",
          huddle: format_huddle(@huddle)
        }
      )
      
      # Also notify via user channels
      @channel.users.each do |member|
        ActionCable.server.broadcast(
          "user_#{member.id}_channels",
          {
            type: "huddle_started",
            huddle: format_huddle(@huddle)
          }
        )
      end

      render json: {
        success: true,
        huddle: format_huddle(@huddle)
      }, status: :created
    else
      render json: {
        success: false,
        errors: @huddle.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/channels/:channel_id/huddles/:id/join
  def join
    unless @channel.member?(current_user)
      return render json: { success: false, error: "Not a member of this channel" }, status: :forbidden
    end

    unless @huddle.active?
      return render json: { success: false, error: "Huddle has ended" }, status: :bad_request
    end

    @huddle.add_participant(current_user)

    # Broadcast participant joined
    ActionCable.server.broadcast(
      "chat_channel_#{@channel.id}",
      {
        type: "huddle_updated",
        huddle: format_huddle(@huddle.reload)
      }
    )

    render json: {
      success: true,
      huddle: format_huddle(@huddle)
    }
  end

  # POST /api/v1/channels/:channel_id/huddles/:id/leave
  def leave
    unless @channel.member?(current_user)
      return render json: { success: false, error: "Not a member of this channel" }, status: :forbidden
    end

    @huddle.remove_participant(current_user)

    # Broadcast participant left
    ActionCable.server.broadcast(
      "chat_channel_#{@channel.id}",
      {
        type: "huddle_updated",
        huddle: format_huddle(@huddle.reload)
      }
    )

    render json: {
      success: true,
      message: "Left huddle"
    }
  end

  # DELETE /api/v1/channels/:channel_id/huddles/:id
  def destroy
    unless @huddle.started_by == current_user || current_user.super_admin?
      return render json: { success: false, error: "Not authorized" }, status: :forbidden
    end

    @huddle.end!

    render json: {
      success: true,
      message: "Huddle ended"
    }
  end

  private

  def set_channel
    @channel = Channel.find(params[:channel_id])
  end

  def set_huddle
    @huddle = @channel.huddles.find(params[:id])
  end

  def format_huddle(huddle)
    {
      id: huddle.id,
      channel_id: huddle.channel_id,
      started_by: {
        id: huddle.started_by.id,
        name: huddle.started_by.name,
        email: huddle.started_by.email
      },
      status: huddle.status,
      started_at: huddle.started_at.iso8601,
      ended_at: huddle.ended_at&.iso8601,
      participants: huddle.active_participants.map do |participant|
        {
          id: participant.user.id,
          name: participant.user.name,
          email: participant.user.email,
          joined_at: participant.joined_at&.iso8601
        }
      end,
      participants_count: huddle.active_participants.count
    }
  end
end
