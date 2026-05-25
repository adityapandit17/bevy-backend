class CandidatesController < ApplicationController
  # Skip CSRF protection for JSON requests (handled by JWT authentication)
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? || json_request? }

  before_action :authenticate_user!
  before_action :set_candidate, only: [ :show, :update, :destroy, :send_email, :archive ]
  before_action :authorize_index!, only: [ :index ]
  before_action :authorize_show!, only: [ :show ]
  before_action :authorize_create!, only: [ :create ]
  before_action :authorize_update!, only: [ :update ]
  before_action :authorize_destroy!, only: [ :destroy ]

  # GET /candidates
  def index
    @candidates = Candidate.includes(:interviews, :next_interview)

    # Filter by archived status (default to not archived unless archive=true)
    if params[:archived] == "true"
      @candidates = @candidates.archived
    else
      @candidates = @candidates.not_archived
    end

    # Apply filters
    @candidates = @candidates.by_status(params[:status]) if params[:status].present?
    @candidates = @candidates.by_department(params[:department]) if params[:department].present?
    @candidates = @candidates.for_job_opening(params[:job_opening_id]) if params[:job_opening_id].present?
    @candidates = @candidates.search_text(params[:search]) if params[:search].present?
    @candidates = @candidates.with_skills(params[:skills]) if params[:skills].present?
    @candidates = @candidates.applied_on_or_after(params[:applied_from]) if params[:applied_from].present?
    @candidates = @candidates.applied_on_or_before(params[:applied_to]) if params[:applied_to].present?

    render json: Panko::ArraySerializer.new(@candidates, each_serializer: CandidateSerializer).to_json
  end

  # GET /candidates/:id
  def show
    render json: CandidateSerializer.new.serialize(@candidate)
  end

  # POST /candidates
  def create
    params_hash = candidate_params.to_h
    if params_hash[:skills].is_a?(Array)
      params_hash[:skills] = params_hash[:skills].join(", ")
    end

    @candidate = Candidate.new(params_hash)
    @candidate.applied_date ||= Date.current
    @candidate.last_contact ||= Date.current
    @candidate.status ||= "applied"
    link_candidate_to_job_opening(@candidate)

    if @candidate.save
      @candidate.job_opening&.increment_applications!
      render json: CandidateSerializer.new.serialize(@candidate), status: :created
    else
      render json: { errors: @candidate.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /candidates/:id
  def update
    params_hash = candidate_params.to_h
    if params_hash[:skills].is_a?(Array)
      params_hash[:skills] = params_hash[:skills].join(", ")
    end

    if @candidate.update(candidate_params)
      render json: CandidateSerializer.new.serialize(@candidate)
    else
      render json: { errors: @candidate.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /candidates/:id
  def destroy
    @candidate.destroy
    head :no_content
  end

  # PATCH /candidates/:id/update_status
  def update_status
    @candidate = Candidate.find(params[:id])
    new_status = params[:status]

    if @candidate.update(status: new_status, last_contact: Date.current)
      render json: CandidateSerializer.new.serialize(@candidate)
    else
      render json: { errors: @candidate.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /candidates/:id/archive
  def archive
    @candidate = Candidate.find(params[:id])
    if @candidate.update(archived: true)
      render json: CandidateSerializer.new.serialize(@candidate)
    else
      render json: { errors: @candidate.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /candidates/stats
  def stats
    stats = {
      total_applications: Candidate.count,
      active_candidates: Candidate.active.size,
      interviews_this_week: Interview.this_week.size,
      offers_extended: Candidate.where(status: "offered").size,
      hired_this_month: Candidate.where(status: "hired", applied_date: 1.month.ago..Date.current).size
    }

    # Pipeline breakdown
    pipeline = {}
    Candidate.group(:status).size.each do |status, count|
      pipeline[status] = count
    end
    stats[:pipeline] = pipeline

    render json: stats
  end

  # GET /candidates/pipeline
  def pipeline
    pipeline_data = {}

    %w[applied screening interview technical final offered hired rejected].each do |status|
      candidates = Candidate.by_status(status).includes(:interviews)
      pipeline_data[status] = {
        count: candidates.size,
        candidates: Panko::ArraySerializer.new(candidates, each_serializer: CandidateSerializer).to_a
      }
    end

    render json: pipeline_data
  end

  # POST /candidates/:id/send_email
  def send_email
    subject = params[:subject]
    message = params[:message]
    sender_name = params[:sender_name]

    if subject.blank? || message.blank?
      render json: { errors: [ "Subject and message are required" ] }, status: :unprocessable_entity
      return
    end

    begin
      CandidateMailer.candidate_email(@candidate, subject, message, sender_name).deliver_now

      # Update last_contact date
      @candidate.update(last_contact: Date.current)

      render json: {
        message: "Email sent successfully",
        candidate: CandidateSerializer.new.serialize(@candidate)
      }
    rescue => e
      Rails.logger.error "Failed to send email: #{e.message}"
      render json: { errors: [ "Failed to send email: #{e.message}" ] }, status: :internal_server_error
    end
  end

  private

  def set_candidate
    @candidate = Candidate.find(params[:id])
  end

  def candidate_params
    params.require(:candidate).permit(
      :job_opening_id, :first_name, :last_name, :date_of_birth, :email, :phone, :position, :department,
      :experience, :location, :status, :applied_date, :last_contact, :resume, :cover_letter, :notes,
      :skills, :education, :current_company, :expected_salary, :availability, :linkedin_url, :archived
    )
  end

  def authorize_index!
    authorize!("candidates", "index")
  end

  def authorize_show!
    authorize!("candidates", "show")
  end

  def authorize_create!
    authorize!("candidates", "create")
  end

  def authorize_update!
    authorize!("candidates", "update")
  end

  def authorize_destroy!
    authorize!("candidates", "destroy")
  end

  def link_candidate_to_job_opening(candidate)
    return if candidate.job_opening_id.present?

    job = JobOpening.find_by(
      title: candidate.position,
      department_id: Department.find_by(name: candidate.department)&.id
    )
    candidate.job_opening = job if job
  end

  # Legacy format methods kept for backward compatibility if needed
  # Can be removed after full migration to Panko
end
