# frozen_string_literal: true

module Api
  module V1
    module Platform
      class CompaniesController < BaseController
        def index
          companies = Company.order(created_at: :desc)
          companies = companies.where(status: params[:status]) if params[:status].present?

          if params[:search].present?
            term = "%#{params[:search].to_s.downcase}%"
            companies = companies.where("LOWER(name) LIKE ? OR LOWER(code) LIKE ?", term, term)
          end

          render_success(companies.map(&:platform_json))
        end

        def show
          company = Company.find(params[:id])
          render_success(company.platform_json)
        rescue ActiveRecord::RecordNotFound
          render_error("Company not found", :not_found)
        end

        def update
          company = Company.find(params[:id])

          if company.update(company_params)
            render_success(company.platform_json)
          else
            render_error(company.errors.full_messages.join(", "))
          end
        rescue ActiveRecord::RecordNotFound
          render_error("Company not found", :not_found)
        end

        def stats
          render_success({
            total_companies: Company.count,
            active_companies: Company.where(status: "active").count,
            trial_companies: Company.where(status: "trial").count,
            pending_companies: Company.where(status: "pending").count,
            estimated_mrr: Company.where(status: %w[active trial]).sum { |c| c.estimated_mrr }
          })
        end

        private

        def company_params
          params.require(:company).permit(:status, :plan, :max_employees, :trial_ends_at)
        end
      end
    end
  end
end
