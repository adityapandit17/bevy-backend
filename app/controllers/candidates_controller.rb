class CandidatesController < ApplicationController
  before_action :set_candidate, only: [ :show, :update, :destroy ]

  # GET /candidates
  def index
    @candidates = Candidate.includes(:interviews)

    # Apply filters
    @candidates = @candidates.by_status(params[:status]) if params[:status].present?
    @candidates = @candidates.by_department(params[:department]) if params[:department].present?
    @candidates = @candidates.where("name ILIKE ? OR email ILIKE ? OR position ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?

    render json: @candidates.map { |candidate| format_candidate(candidate) }
  end

  # GET /candidates/:id
  def show
    render json: format_candidate(@candidate)
  end

  # POST /candidates
  def create
    @candidate = Candidate.new(candidate_params)
    @candidate.applied_date ||= Date.current
    @candidate.last_contact ||= Date.current
    @candidate.status ||= "applied"

    if @candidate.save
      render json: format_candidate(@candidate), status: :created
    else
      render json: { errors: @candidate.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /candidates/:id
  def update
    if @candidate.update(candidate_params)
      render json: format_candidate(@candidate)
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
      render json: format_candidate(@candidate)
    else
      render json: { errors: @candidate.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /candidates/stats
  def stats
    stats = {
      total_applications: Candidate.count,
      active_candidates: Candidate.active.count,
      interviews_this_week: Interview.this_week.count,
      offers_extended: Candidate.where(status: "offered").count,
      hired_this_month: Candidate.where(status: "hired", applied_date: 1.month.ago..Date.current).count
    }

    # Pipeline breakdown
    pipeline = {}
    Candidate.group(:status).count.each do |status, count|
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
        count: candidates.count,
        candidates: candidates.map { |c| format_candidate(c) }
      }
    end

    render json: pipeline_data
  end

  private

  def set_candidate
    @candidate = Candidate.find(params[:id])
  end

  def candidate_params
    params.require(:candidate).permit(:name, :email, :phone, :position, :department, :experience, :location, :status, :applied_date, :last_contact, :resume, :cover_letter, :notes, :skills, :education, :current_company, :expected_salary, :availability)
  end

  def format_candidate(candidate)
    {
      id: candidate.id,
      name: candidate.name,
      email: candidate.email,
      phone: candidate.phone,
      position: candidate.position,
      department: candidate.department,
      experience: candidate.experience,
      location: candidate.location,
      status: candidate.status,
      applied_date: candidate.applied_date,
      last_contact: candidate.last_contact,
      resume: candidate.resume,
      cover_letter: candidate.cover_letter,
      notes: candidate.notes,
      skills: candidate.skills_list,
      education: candidate.education,
      current_company: candidate.current_company,
      expected_salary: candidate.expected_salary,
      availability: candidate.availability,
      interviews: candidate.interviews.map { |interview| format_interview(interview) },
      interview_count: candidate.interview_count,
      days_since_applied: candidate.days_since_applied,
      days_since_last_contact: candidate.days_since_last_contact,
      next_interview: candidate.next_interview ? format_interview(candidate.next_interview) : nil,
      created_at: candidate.created_at,
      updated_at: candidate.updated_at
    }
  end

  def format_interview(interview)
    {
      id: interview.id,
      candidate_id: interview.candidate_id,
      interview_type: interview.interview_type,
      scheduled_date: interview.scheduled_date,
      scheduled_time: interview.scheduled_time,
      interviewer: interview.interviewer,
      status: interview.status,
      notes: interview.notes,
      feedback: interview.feedback,
      rating: interview.rating,
      is_today: interview.is_today?,
      is_overdue: interview.is_overdue?,
      is_upcoming: interview.is_upcoming?,
      formatted_time: interview.formatted_time,
      formatted_date: interview.formatted_date,
      status_color: interview.status_color,
      created_at: interview.created_at,
      updated_at: interview.updated_at
    }
  end
end
