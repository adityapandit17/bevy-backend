# frozen_string_literal: true

module Api
  module V1
    class PublicPricingController < ApplicationController
      skip_before_action :authenticate_user_from_token!, raise: false
      skip_around_action :with_tenant_from_user, raise: false

      def index
        render json: {
          success: true,
          data: PricingPlan.published.ordered.map(&:platform_json)
        }
      end
    end
  end
end
