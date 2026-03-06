class NotificationsController < ApplicationController
  # This controller is used as a JSON API from the Next.js frontend.
  # Disable CSRF / origin checks completely here – we rely on JWT auth instead.
  skip_before_action :verify_authenticity_token

  before_action :set_notification, only: [ :update, :destroy ]

  # GET /notifications
  # Returns the most recent notifications for the current user
  def index
    notifications = current_user.notifications.order(created_at: :desc).limit(100)

    render json: notifications.map { |n| format_notification(n) }
  rescue => e
    Rails.logger.error "Error in notifications#index: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Failed to fetch notifications", message: e.message }, status: :internal_server_error
  end

  # PATCH /notifications/:id
  # Used mainly to mark a notification as read
  def update
    if @notification.update(notification_params)
      render json: format_notification(@notification)
    else
      error_messages = @notification.errors.full_messages
      render json: { error: error_messages.join(", "), errors: error_messages }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Error in notifications#update: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Failed to update notification", message: e.message }, status: :internal_server_error
  end

  # DELETE /notifications/:id
  def destroy
    @notification.destroy
    head :no_content
  end

  # PATCH /notifications/mark_all_read
  def mark_all_read
    current_user.notifications.unread.update_all(read: true, updated_at: Time.current)
    head :no_content
  end

  # DELETE /notifications/destroy_all
  def destroy_all
    current_user.notifications.delete_all
    head :no_content
  end

  private

  def set_notification
    unless current_user
      render json: { error: "Authentication required" }, status: :unauthorized
      return
    end

    @notification = current_user.notifications.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Notification not found" }, status: :not_found
  rescue => e
    Rails.logger.error "Error in set_notification: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Failed to find notification", message: e.message }, status: :internal_server_error
  end

  def notification_params
    params.require(:notification).permit(:read)
  end

  def format_notification(notification)
    {
      id: notification.id.to_s,
      type: notification.notification_type,
      title: notification.title,
      message: notification.message,
      read: notification.read,
      createdAt: notification.created_at.iso8601,
      actionUrl: notification.action_url
    }
  rescue => e
    Rails.logger.error "Error formatting notification #{notification.id}: #{e.message}"
    {
      id: notification.id.to_s,
      type: notification.notification_type || "system",
      title: notification.title || "Notification",
      message: notification.message || "",
      read: notification.read || false,
      createdAt: notification.created_at ? notification.created_at.iso8601 : Time.current.iso8601,
      actionUrl: notification.action_url
    }
  end
end
