class RecognitionsController < ApplicationController
  before_action :set_recognition, only: [ :show, :update, :destroy ]

  def index
    @recognitions = Recognition.for_current_company.includes(:given_by, :received_by)

    # Filtering
    @recognitions = @recognitions.by_type(params[:recognition_type]) if params[:recognition_type].present?
    @recognitions = @recognitions.by_category(params[:category]) if params[:category].present?
    @recognitions = @recognitions.where(status: params[:status]) if params[:status].present?
    @recognitions = @recognitions.by_employee(params[:employee_id]) if params[:employee_id].present?
    @recognitions = @recognitions.by_giver(params[:given_by_id]) if params[:given_by_id].present?

    # Search
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      @recognitions = @recognitions.where("LOWER(title) LIKE :search OR LOWER(description) LIKE :search", search: search_term)
    end

    # Default ordering
    @recognitions = @recognitions.recent

    # Limit for pagination
    limit = params[:limit] ? params[:limit].to_i : nil
    @recognitions = @recognitions.limit(limit) if limit

    render json: @recognitions.as_json(
      include: {
        given_by: { only: [ :id, :email, :first_name, :last_name ] },
        received_by: { only: [ :id, :email, :first_name, :last_name, :designation, :department_id ] }
      },
      methods: [ :formatted_date, :given_by_name, :received_by_name ]
    )
  end

  def show
    render json: @recognition.as_json(
      include: {
        given_by: { only: [ :id, :email, :first_name, :last_name ] },
        received_by: { only: [ :id, :email, :first_name, :last_name, :designation, :department_id ] }
      },
      methods: [ :formatted_date, :given_by_name, :received_by_name ]
    )
  end

  def create
    @recognition = Recognition.new(recognition_params)
    @recognition.given_by_id = current_user.id if current_user.present?
    @recognition.status = "active"

    if @recognition.save
      render json: @recognition.as_json(
        include: {
          given_by: { only: [ :id, :email, :first_name, :last_name ] },
          received_by: { only: [ :id, :email, :first_name, :last_name, :designation, :department_id ] }
        },
        methods: [ :formatted_date, :given_by_name, :received_by_name ]
      ), status: :created
    else
      render json: { errors: @recognition.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @recognition.update(recognition_params)
      render json: @recognition.as_json(
        include: {
          given_by: { only: [ :id, :email, :first_name, :last_name ] },
          received_by: { only: [ :id, :email, :first_name, :last_name, :designation, :department_id ] }
        },
        methods: [ :formatted_date, :given_by_name, :received_by_name ]
      )
    else
      render json: { errors: @recognition.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @recognition.destroy
    head :no_content
  end

  private

  def set_recognition
    @recognition = find_in_tenant(Recognition, params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Recognition not found" }, status: :not_found
  end

  def recognition_params
    params.require(:recognition).permit(:received_by_id, :recognition_type, :title, :description, :category, :status)
  end
end
