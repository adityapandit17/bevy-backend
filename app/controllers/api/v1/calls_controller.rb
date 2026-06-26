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
    turn_urls.each do |url|
      turn = { urls: url }
      turn[:username] = ENV["TURN_USERNAME"] if ENV["TURN_USERNAME"].present?
      turn[:credential] = ENV["TURN_CREDENTIAL"] if ENV["TURN_CREDENTIAL"].present?
      servers << turn
    end

    render json: { success: true, data: { ice_servers: servers } }
  end
end
