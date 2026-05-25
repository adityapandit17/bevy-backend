# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Public
      class JobOpeningsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @department = departments(:one)
          @company = Company.first || Company.create!(
            name: "Test Co",
            code: "TST",
            industry: "technology",
            employee_count: "1-50",
            timezone: "UTC",
            currency: "USD"
          )
          @company.update!(careers_slug: "test-co") if @company.careers_slug.blank?

          @open_job = JobOpening.create!(
            title: "Public Software Engineer",
            description: "A" * 25,
            requirements: "B" * 20,
            status: "open",
            location: "Remote",
            job_type: "full-time",
            vacancies: 1,
            experience: "2 years",
            skills: "Ruby, Rails",
            posted: Date.current,
            department: @department
          )
          @closed_job = JobOpening.create!(
            title: "Closed Role",
            description: "C" * 25,
            requirements: "D" * 20,
            status: "closed",
            location: "Remote",
            job_type: "full-time",
            vacancies: 1,
            experience: "1 year",
            skills: "SQL",
            posted: Date.current,
            department: @department
          )
        end

        def public_job_path(job)
          "/api/v1/public/#{@company.careers_slug}/jobs/#{job.public_slug}"
        end

        test "show returns open job without auth" do
          get public_job_path(@open_job), as: :json
          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal "Public Software Engineer", json["data"]["job"]["title"]
          assert_equal @company.name, json["data"]["company"]["name"]
          assert_equal @company.careers_slug, json["data"]["company"]["careers_slug"]
        end

        test "show returns not found for closed job" do
          get public_job_path(@closed_job), as: :json
          assert_response :not_found
        end

        test "resolve returns company and job slugs for legacy URLs" do
          get "/api/v1/public/resolve/#{@open_job.public_slug}", as: :json
          assert_response :success
          json = JSON.parse(response.body)
          assert json["success"]
          assert_equal @company.careers_slug, json["data"]["company_slug"]
          assert_equal @open_job.public_slug, json["data"]["job_slug"]
        end

        test "apply creates candidate for open job" do
          assert_difference "Candidate.count", 1 do
            post "#{public_job_path(@open_job)}/apply",
                 params: {
                   application: {
                     first_name: "Jane",
                     last_name: "Applicant",
                     email: "jane.applicant@example.com",
                     phone: "+919999999999"
                   }
                 },
                 as: :json
          end
          assert_response :created
          candidate = Candidate.order(:id).last
          assert_equal @open_job.id, candidate.job_opening_id
          assert_equal "applied", candidate.status
        end

        test "apply with resume file upload" do
          file = Rack::Test::UploadedFile.new(
            Rails.root.join("test/fixtures/files/sample_resume.pdf"),
            "application/pdf",
            original_filename: "resume.pdf"
          )

          assert_difference "Candidate.count", 1 do
            post "#{public_job_path(@open_job)}/apply",
                 params: {
                   application: {
                     first_name: "Resume",
                     last_name: "Uploader",
                     email: "resume.uploader@example.com",
                     phone: "+919999999998",
                     linkedin_url: "https://linkedin.com/in/resume-uploader"
                   },
                   resume_file: file
                 }
          end

          assert_response :created
          candidate = Candidate.order(:id).last
          assert candidate.resume.present?
          assert candidate.resume.start_with?("uploads/")
          assert_equal "https://linkedin.com/in/resume-uploader", candidate.linkedin_url
        end

        test "apply rejected for closed job" do
          post "#{public_job_path(@closed_job)}/apply",
               params: {
                 application: {
                   first_name: "John",
                   last_name: "Doe",
                   email: "john@example.com",
                   phone: "1234567890"
                 }
               },
               as: :json
          assert_response :not_found
        end
      end
    end
  end
end
