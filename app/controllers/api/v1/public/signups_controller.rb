# frozen_string_literal: true

module Api
  module V1
    module Public
      class SignupsController < ApplicationController
        skip_before_action :authenticate_user_from_token!
        skip_around_action :with_tenant_from_user, raise: false

        def create
          result = CompanyTrialSignupService.new(signup_params).call

          render json: {
            success: true,
            data: {
              token: result[:token],
              company: result[:company].as_json(only: %i[id name code status plan trial_ends_at careers_slug]),
              user: {
                id: result[:user].id,
                email: result[:user].email,
                name: result[:user].name,
                employee_id: result[:user].employee_id
              },
              message: "Your #{Company::TRIAL_DAYS}-day trial has started. Welcome to BevyHR!"
            }
          }, status: :created
        rescue CompanyTrialSignupService::SignupError => e
          render json: { success: false, error: e.message }, status: :unprocessable_entity
        end

        private

        def signup_params
          params.permit(
            :company_name, :company_code, :industry, :employee_count,
            :timezone, :currency, :country_code, :address, :plan,
            :admin_email, :admin_password, :admin_first_name, :admin_last_name, :admin_phone
          )
        end
      end
    end
  end
end
