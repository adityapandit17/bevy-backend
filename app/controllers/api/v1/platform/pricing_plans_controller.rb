# frozen_string_literal: true

module Api
  module V1
    module Platform
      class PricingPlansController < BaseController
        before_action :require_super_admin!, only: [ :create, :update, :destroy ]
        before_action :set_plan, only: [ :show, :update, :destroy ]

        def index
          render_success(PricingPlan.ordered.map(&:platform_json))
        end

        def show
          render_success(@plan.platform_json)
        end

        def create
          plan = PricingPlan.new(plan_params)
          if plan.save
            audit_action!(action: "pricing_plan.create", resource: plan, metadata: { slug: plan.slug, name: plan.name })
            render_success(plan.platform_json, :created)
          else
            render_error(plan.errors.full_messages.join(", "))
          end
        end

        def update
          if @plan.update(plan_params)
            audit_record_update!(action: "pricing_plan.update", record: @plan)
            render_success(@plan.platform_json)
          else
            render_error(@plan.errors.full_messages.join(", "))
          end
        end

        def destroy
          slug = @plan.slug
          name = @plan.name
          @plan.destroy!
          audit_action!(action: "pricing_plan.destroy", metadata: { slug: slug, name: name })
          render_success({ message: "Plan deleted" })
        end

        private

        def set_plan
          @plan = PricingPlan.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render_error("Pricing plan not found", :not_found)
        end

        def plan_params
          permitted = params.require(:pricing_plan).permit(
            :slug, :name, :description, :monthly_price, :annual_price, :max_employees,
            :published, :popular, :position, features: []
          )
          permitted[:features] ||= []
          permitted
        end
      end
    end
  end
end
