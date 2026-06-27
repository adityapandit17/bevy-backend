# frozen_string_literal: true

module Api
  module V1
    module Platform
      class CompaniesController < BaseController
        before_action :require_billing_or_super!, only: [ :create, :update, :end_trial, :extend_trial, :restart_trial, :activate ]
        before_action :set_company, only: [ :show, :update, :end_trial, :extend_trial, :restart_trial, :activate, :feature_flags, :audits ]

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
          render_success(@company.platform_json)
        end

        def create
          company = CompanyPlatformCreateService.new(create_params).call
          audit_action!(action: "company.create", company: company, resource: company, metadata: { name: company.name, code: company.code, plan: company.plan, status: company.status })
          render_success(company.platform_json, :created)
        rescue CompanyPlatformCreateService::CreateError => e
          render_error(e.message)
        end

        def update
          if @company.update(company_params)
            audit_record_update!(action: "company.update", record: @company)
            render_success(@company.platform_json)
          else
            render_error(@company.errors.full_messages.join(", "))
          end
        end

        def end_trial
          previous_status = @company.status
          @company.end_trial!
          audit_action!(action: "company.end_trial", company: @company, resource: @company, metadata: { previous_status: previous_status, new_status: @company.status })
          render_success(@company.platform_json)
        end

        def extend_trial
          days = params[:days].to_i
          days = PlatformSetting.get("default_trial_days").to_i if days <= 0
          previous_trial_ends_at = @company.trial_ends_at
          @company.extend_trial!(days)
          audit_action!(action: "company.extend_trial", company: @company, resource: @company, metadata: { days: days, previous_trial_ends_at: previous_trial_ends_at, trial_ends_at: @company.trial_ends_at })
          render_success(@company.platform_json)
        end

        def restart_trial
          days = params[:days].to_i
          days = PlatformSetting.get("default_trial_days").to_i if days <= 0
          previous_status = @company.status
          @company.restart_trial!(days: days)
          audit_action!(action: "company.restart_trial", company: @company, resource: @company, metadata: { days: days, previous_status: previous_status, trial_ends_at: @company.trial_ends_at })
          render_success(@company.platform_json)
        end

        def activate
          previous_status = @company.status
          @company.activate_subscription!(
            plan: params[:plan].presence || @company.plan,
            billing_cycle: params[:billing_cycle].presence || @company.billing_cycle
          )
          audit_action!(action: "company.activate", company: @company, resource: @company, metadata: { previous_status: previous_status, plan: @company.plan, billing_cycle: @company.billing_cycle })
          render_success(@company.platform_json)
        end

        def feature_flags
          if request.patch? || request.put?
            previous = CompanyFeatureFlag.for_company(@company)
            CompanyFeatureFlag.update_for_company!(@company, feature_flag_params)
            audit_action!(action: "company.feature_flags.update", company: @company, resource: @company, metadata: { previous: previous, current: CompanyFeatureFlag.for_company(@company) })
          end
          render_success(CompanyFeatureFlag.for_company(@company))
        end

        def audits
          scope = PlatformAuditLog.includes(:platform_admin_user).for_company(@company)
          limit = params[:limit].to_i
          limit = 50 if limit <= 0
          limit = [ limit, 100 ].min

          render_success({
            total: scope.count,
            entries: scope.recent.limit(limit).map(&:platform_json)
          })
        end

        def stats
          overdue_follow_ups = PlatformFollowUp.overdue.count
          open_inquiries = PlatformInquiry.open.count
          pending_subscriptions = SubscriptionRequest.pending.count

          render_success({
            total_companies: Company.count,
            active_companies: Company.where(status: "active").count,
            trial_companies: Company.where(status: "trial").count,
            pending_companies: Company.where(status: "pending").count,
            past_due_companies: Company.where(status: "past_due").count,
            estimated_mrr: Company.where(status: %w[active trial]).sum(&:estimated_mrr),
            open_inquiries: open_inquiries,
            pending_subscriptions: pending_subscriptions,
            overdue_follow_ups: overdue_follow_ups,
            revenue_chart: revenue_chart_data
          })
        end

        private

        def set_company
          @company = Company.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render_error("Company not found", :not_found)
        end

        def company_params
          params.require(:company).permit(
            :status, :plan, :max_employees, :trial_ends_at, :billing_cycle, :renews_at,
            :name, :contact_email, :contact_name
          )
        end

        def create_params
          params.require(:company).permit(
            :name, :code, :industry, :employee_count, :timezone, :currency, :country_code,
            :address, :status, :plan, :trial_days, :max_employees, :contact_email, :contact_name,
            :admin_email, :admin_password, :admin_first_name, :admin_last_name, :admin_phone,
            :billing_cycle, :create_admin
          )
        end

        def feature_flag_params
          params.require(:feature_flags).permit(:chat, :mobile_app, :ai_assistant)
        end

        def revenue_chart_data
          6.times.map do |i|
            month_start = i.months.ago.beginning_of_month
            {
              month: month_start.strftime("%b"),
              mrr: Company.where(status: %w[active trial])
                          .where("created_at <= ?", month_start.end_of_month)
                          .sum(&:estimated_mrr)
            }
          end.reverse
        end
      end
    end
  end
end
