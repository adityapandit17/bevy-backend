# frozen_string_literal: true

module Api
  module V1
    module Platform
      class InvoicesController < BaseController
        before_action :require_billing_or_super!
        before_action :set_invoice, only: [ :show, :update, :destroy ]

        def index
          invoices = PlatformInvoice.includes(:company).recent
          invoices = invoices.where(company_id: params[:company_id]) if params[:company_id].present?
          invoices = invoices.where(status: params[:status]) if params[:status].present?
          render_success(invoices.map(&:platform_json))
        end

        def show
          render_success(@invoice.platform_json)
        end

        def create
          invoice = PlatformInvoice.new(invoice_params)
          if invoice.save
            audit_action!(action: "invoice.create", company: invoice.company, resource: invoice, metadata: { invoice_number: invoice.invoice_number, amount: invoice.amount })
            render_success(invoice.platform_json, :created)
          else
            render_error(invoice.errors.full_messages.join(", "))
          end
        end

        def update
          if @invoice.update(invoice_params)
            audit_record_update!(action: "invoice.update", record: @invoice, company: @invoice.company)
            render_success(@invoice.platform_json)
          else
            render_error(@invoice.errors.full_messages.join(", "))
          end
        end

        def destroy
          company = @invoice.company
          invoice_number = @invoice.invoice_number
          @invoice.destroy!
          audit_action!(action: "invoice.destroy", company: company, metadata: { invoice_number: invoice_number })
          render_success({ message: "Invoice deleted" })
        end

        private

        def set_invoice
          @invoice = PlatformInvoice.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render_error("Invoice not found", :not_found)
        end

        def invoice_params
          params.require(:invoice).permit(
            :company_id, :amount, :status, :billing_period_start, :billing_period_end,
            :due_date, :paid_at, :plan, :notes
          )
        end
      end
    end
  end
end
