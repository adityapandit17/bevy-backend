class InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_invitations_access!

  # GET /invitations
  def index
    @invited_users = User.invitation_not_accepted.includes(:roles, :invited_by)
    
    render json: {
      invitations: @invited_users.map { |user| format_invitation(user) },
      total_count: @invited_users.count
    }
  end

  # POST /invitations
  def create
    email = params[:email]&.downcase
    role_ids = params[:role_ids] || []
    
    if email.blank?
      render json: { error: "Email is required" }, status: :bad_request
      return
    end

    # Check if user already exists
    existing_user = User.find_by(email: email)
    if existing_user
      if existing_user.invited_to_sign_up?
        render json: { error: "User has already been invited" }, status: :unprocessable_entity
      else
        render json: { error: "User already exists" }, status: :unprocessable_entity
      end
      return
    end

    # Create invited user
    @user = User.invite!(
      { 
        email: email,
        first_name: params[:first_name] || "Invited",
        last_name: params[:last_name] || "User",
        status: "active"
      },
      current_user
    )

    if @user.persisted?
      # Assign roles if provided
      if role_ids.any?
        @user.role_ids = role_ids
      end

      render json: {
        message: "Invitation sent successfully",
        user: format_invitation(@user)
      }, status: :created
    else
      render json: {
        message: "Failed to send invitation",
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH /invitations/:id/resend
  def resend
    @user = User.find(params[:id])
    
    unless @user.invited_to_sign_up?
      render json: { error: "User has not been invited yet" }, status: :unprocessable_entity
      return
    end

    if @user.invite!(current_user)
      render json: {
        message: "Invitation resent successfully",
        user: format_invitation(@user)
      }
    else
      render json: {
        message: "Failed to resend invitation",
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /invitations/:id
  def destroy
    @user = User.find(params[:id])
    
    unless @user.invited_to_sign_up?
      render json: { error: "User has not been invited yet" }, status: :unprocessable_entity
      return
    end

    @user.destroy
    render json: { message: "Invitation cancelled successfully" }
  end

  private

  def authorize_invitations_access!
    authorize!("users", "create")
  end

  def format_invitation(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      name: user.name,
      status: user.status,
      invitation_sent_at: user.invitation_sent_at,
      invitation_accepted_at: user.invitation_accepted_at,
      invited_by: user.invited_by ? {
        id: user.invited_by.id,
        name: user.invited_by.name,
        email: user.invited_by.email
      } : nil,
      roles: user.roles.map { |role| { id: role.id, name: role.name, description: role.description } },
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
