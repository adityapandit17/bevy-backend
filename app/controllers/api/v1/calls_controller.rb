class Api::V1::CallsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user!

  # GET /api/v1/calls/ice_config
  def ice_config
    servers = [
      { urls: "stun:stun.l.google.com:19302" },
      { urls: "stun:stun1.l.google.com:19302" },
      { urls: "stun:stun2.l.google.com:19302" },
      { urls: "stun:stun3.l.google.com:19302" },
      { urls: "stun:stun4.l.google.com:19302" }
    ]

    turn_urls = ENV.fetch("TURN_URLS", ENV["TURN_URL"]).to_s.split(",").map(&:strip).reject(&:blank?)
    turn_username = ENV["TURN_USERNAME"].presence
    turn_credential = ENV["TURN_CREDENTIAL"].presence

    if turn_urls.any? && turn_username && turn_credential
      turn_urls.each do |url|
        servers << { urls: url, username: turn_username, credential: turn_credential }
      end
    elsif turn_urls.any?
      Rails.logger.warn(
        "[CallsController] TURN_URLS configured but TURN_USERNAME/TURN_CREDENTIAL missing; omitting TURN from ice_config"
      )
    end

    render json: { success: true, data: { ice_servers: servers } }
  end
end
