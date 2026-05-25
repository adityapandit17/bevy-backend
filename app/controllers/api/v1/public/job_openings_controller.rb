# frozen_string_literal: true

module Api
  module V1
    module Public
      class JobOpeningsController < ApplicationController
        skip_before_action :verify_authenticity_token

        # GET /api/v1/public/resolve/:job_slug — legacy URL redirect
        def resolve
          job = JobOpening.find_by!(public_slug: params[:job_slug])
          company = Company.current
          raise ActiveRecord::RecordNotFound unless company && job.publicly_available?

          render json: {
            success: true,
            data: {
              company_slug: company.careers_slug,
              job_slug: job.public_slug
            }
          }
        rescue ActiveRecord::RecordNotFound
          render json: { success: false, error: "Job not found" }, status: :not_found
        end

        # GET /api/v1/public/:company_slug/jobs/:job_slug
        def show
          company = find_company!
          job = find_open_job!(company)

          render json: {
            success: true,
            data: {
              company: PublicCompanySerializer.new.serialize(company),
              job: PublicJobOpeningSerializer.new.serialize(job)
            }
          }
        rescue ActiveRecord::RecordNotFound
          render json: { success: false, error: "Job not found" }, status: :not_found
        end

        # POST /api/v1/public/:company_slug/jobs/:job_slug/apply
        def apply
          company = find_company!
          job = find_open_job!(company)

          candidate = job.candidates.build(application_attributes)
          candidate.position = job.title
          candidate.department = job.department&.name
          candidate.status = "applied"
          candidate.applied_date ||= Date.current
          candidate.last_contact ||= Date.current

          if params[:resume_file].present?
            candidate.resume = PublicResumeUploadService.store!(params[:resume_file])
          end

          if candidate.save
            job.increment_applications!
            render json: {
              success: true,
              data: { message: "Application submitted successfully" }
            }, status: :created
          else
            render json: { success: false, errors: candidate.errors.full_messages }, status: :unprocessable_entity
          end
        rescue PublicResumeUploadService::Error => e
          render json: { success: false, error: e.message }, status: :unprocessable_entity
        rescue ActiveRecord::RecordNotFound
          render json: { success: false, error: "Job not found" }, status: :not_found
        end

        private

        def find_company!
          Company.find_by!(careers_slug: params[:company_slug])
        end

        def find_open_job!(company)
          job = JobOpening.includes(:department).find_by!(public_slug: params[:job_slug])
          raise ActiveRecord::RecordNotFound unless job.publicly_available?

          job
        end

        def application_attributes
          attrs = public_application_params.to_h

          if params.dig(:application, :skills).is_a?(Array)
            attrs[:skills] = params[:application][:skills].join(", ")
          end

          attrs
        end

        def public_application_params
          params.require(:application).permit(
            :first_name, :last_name, :email, :phone, :experience, :location,
            :cover_letter, :education, :current_company, :expected_salary,
            :availability, :linkedin_url, :skills, :notes
          )
        end
      end
    end
  end
end
