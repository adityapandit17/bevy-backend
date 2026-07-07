class Api::V1::ChannelsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!
  before_action :set_channel, only: [ :show, :update, :destroy, :add_members, :remove_member, :messages ]

  # GET /api/v1/channels
  def index
    channels = current_user.channels.includes(:created_by, :messages, :users)
                          .order(updated_at: :desc)

    # Filter by type if provided
    channels = channels.where(channel_type: params[:type]) if params[:type].present?

    render json: {
      success: true,
      channels: channels.map { |channel| format_channel(channel) }
    }
  end

  # GET /api/v1/channels/:id
  def show
    unless @channel.member?(current_user)
      return render json: { success: false, error: "Not a member of this channel" }, status: :forbidden
    end

    render json: {
      success: true,
      channel: format_channel(@channel)
    }
  end

  # POST /api/v1/channels
  def create
    @channel = Channel.new(channel_params)
    @channel.created_by = current_user

    if @channel.save
      # Add creator as admin member
      @channel.channel_memberships.create!(user: current_user, role: "admin")

      # Add other members if provided
      if params[:user_ids].present?
        params[:user_ids].each do |user_id|
          @channel.channel_memberships.create!(user_id: user_id, role: "member")
        end
      end

      render json: {
        success: true,
        channel: format_channel(@channel.reload)
      }, status: :created
    else
      render json: {
        success: false,
        errors: @channel.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/channels/:id
  def update
    unless @channel.member?(current_user)
      return render json: { success: false, error: "Not a member of this channel" }, status: :forbidden
    end

    if channel_settings_change? && !can_manage_channel?
      return render json: { success: false, error: "Not authorized to update this channel" }, status: :forbidden
    end

    if @channel.channel_type == "direct"
      return render json: { success: false, error: "Direct messages cannot be updated" }, status: :unprocessable_entity
    end

    if @channel.update(channel_update_params)
      render json: {
        success: true,
        channel: format_channel(@channel)
      }
    else
      render json: {
        success: false,
        errors: @channel.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/channels/:id
  def destroy
    unless @channel.created_by == current_user || current_user.super_admin?
      return render json: { success: false, error: "Not authorized" }, status: :forbidden
    end

    @channel.destroy
    render json: { success: true, message: "Channel deleted" }
  end

  # POST /api/v1/channels/:id/add_members
  def add_members
    unless @channel.member?(current_user)
      return render json: { success: false, error: "Not a member of this channel" }, status: :forbidden
    end

    if params[:user_ids].present?
      added_users = []
      params[:user_ids].each do |user_id|
        user = User.find_by(id: user_id)
        next unless user

        membership = @channel.channel_memberships.find_or_create_by!(user: user) do |cm|
          cm.role = "member"
        end
        added_users << user unless membership.previously_new_record?
      end

      render json: {
        success: true,
        message: "Members added",
        channel: format_channel(@channel.reload)
      }
    else
      render json: { success: false, error: "user_ids required" }, status: :bad_request
    end
  end

  # DELETE /api/v1/channels/:id/remove_member/:user_id
  def remove_member
    unless @channel.member?(current_user)
      return render json: { success: false, error: "Not a member of this channel" }, status: :forbidden
    end

    user = User.find(params[:user_id])
    membership = @channel.channel_memberships.find_by(user: user)

    if membership
      membership.destroy
      render json: { success: true, message: "Member removed" }
    else
      render json: { success: false, error: "User is not a member" }, status: :not_found
    end
  end

  # GET /api/v1/channels/:id/messages
  def messages
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

  # POST /api/v1/channels/create_direct
  def create_direct
    other_user = User.find_by(id: params[:user_id])
    return render json: { success: false, error: "User not found" }, status: :not_found unless other_user

    # Check if direct message channel already exists
    existing_channel = Channel.direct_messages
                              .joins(:channel_memberships)
                              .where(channel_memberships: { user_id: [ current_user.id, other_user.id ] })
                              .group("channels.id")
                              .having("COUNT(channel_memberships.id) = 2")
                              .first

    if existing_channel
      return render json: {
        success: true,
        channel: format_channel(existing_channel)
      }
    end

    # Create new direct message channel
    @channel = Channel.create!(
      name: "#{current_user.name} & #{other_user.name}",
      channel_type: "direct",
      is_private: true,
      created_by: current_user
    )

    @channel.channel_memberships.create!(user: current_user, role: "member")
    @channel.channel_memberships.create!(user: other_user, role: "member")

    render json: {
      success: true,
      channel: format_channel(@channel)
    }, status: :created
  end

  private

  def set_channel
    @channel = Channel.find(params[:id])
  end

  def channel_params
    params.require(:channel).permit(:name, :channel_type, :is_private, :description)
  end

  def channel_update_params
    permitted = [ :name, :description ]
    permitted << :is_private if @channel.channel_type == "channel"
    params.require(:channel).permit(*permitted)
  end

  def channel_settings_change?
    channel_data = params[:channel]
    return false unless channel_data.present?

    channel_data.key?(:name) || channel_data.key?(:is_private) || channel_data.key?(:description)
  end

  def can_manage_channel?
    @channel.created_by == current_user || current_user.super_admin?
  end

  def format_channel(channel)
    {
      id: channel.id,
      name: channel.name,
      channel_type: channel.channel_type,
      is_private: channel.is_private,
      description: channel.description,
      created_by: {
        id: channel.created_by.id,
        name: channel.created_by.name,
        email: channel.created_by.email
      },
      unread_count: channel.unread_count_for(current_user),
      last_message: channel.last_message ? format_message(channel.last_message) : nil,
      members_count: channel.users.count,
      members: channel.users.limit(10).map { |user|
        {
          id: user.id,
          name: user.name,
          email: user.email
        }
      },
      created_at: channel.created_at.iso8601,
      updated_at: channel.updated_at.iso8601
    }
  end

  def format_message(message)
    {
      id: message.id,
      channel_id: message.channel_id,
      user_id: message.user_id,
      user_name: message.user.name,
      user_email: message.user.email,
      content: message.content,
      attachment_path: message.attachment_path,
      attachment_filename: message.attachment_filename,
      attachment_content_type: message.attachment_content_type,
      edited_at: message.edited_at&.iso8601,
      created_at: message.created_at.iso8601,
      updated_at: message.updated_at.iso8601
    }
  end
end
