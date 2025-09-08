module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    unless current_user
      render json: { error: 'Authentication required' }, status: :unauthorized
    end
  end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  rescue ActiveRecord::RecordNotFound
    session[:user_id] = nil
    nil
  end

  def user_signed_in?
    current_user.present?
  end

  def sign_in(user)
    session[:user_id] = user.id
    user.update_last_login!
  end

  def sign_out
    session[:user_id] = nil
    @current_user = nil
  end
end
