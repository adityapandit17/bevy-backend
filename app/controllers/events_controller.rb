class EventsController < ApplicationController
  before_action :set_event, only: [ :show, :update, :destroy ]

  def index
    @events = Event.includes(:organizer).all

    # Filtering
    @events = @events.upcoming if params[:upcoming] == "true"
    @events = @events.past if params[:past] == "true"
    @events = @events.scheduled if params[:status] == "scheduled"
    @events = @events.by_type(params[:event_type]) if params[:event_type].present?

    # Date range filter
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      @events = @events.by_date_range(start_date.beginning_of_day, end_date.end_of_day)
    end

    # Search
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      @events = @events.where("LOWER(title) LIKE :search OR LOWER(description) LIKE :search", search: search_term)
    end

    # Default to upcoming if no filters
    @events = @events.upcoming if params[:upcoming].nil? && params[:past].nil? && params[:start_date].blank?

    render json: @events.as_json(
      include: {
        organizer: { only: [ :id, :email, :first_name, :last_name ] }
      },
      methods: [ :attendee_ids_list, :formatted_start_time, :formatted_end_time, :duration_hours, :is_upcoming?, :is_past?, :is_ongoing? ]
    )
  end

  def show
    render json: @event.as_json(
      include: {
        organizer: { only: [ :id, :email, :first_name, :last_name ] }
      },
      methods: [ :attendee_ids_list, :formatted_start_time, :formatted_end_time, :duration_hours, :is_upcoming?, :is_past?, :is_ongoing? ]
    )
  end

  def create
    @event = Event.new(event_params)
    @event.organizer_id = current_user.id if current_user.present?
    @event.attendee_ids_list = params[:event][:attendee_ids] if params[:event][:attendee_ids].present?

    if @event.save
      render json: @event.as_json(
        include: {
          organizer: { only: [ :id, :email, :first_name, :last_name ] }
        },
        methods: [ :attendee_ids_list, :formatted_start_time, :formatted_end_time, :duration_hours, :is_upcoming?, :is_past?, :is_ongoing? ]
      ), status: :created
    else
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @event.attendee_ids_list = params[:event][:attendee_ids] if params[:event][:attendee_ids].present?
    
    if @event.update(event_params)
      render json: @event.as_json(
        include: {
          organizer: { only: [ :id, :email, :first_name, :last_name ] }
        },
        methods: [ :attendee_ids_list, :formatted_start_time, :formatted_end_time, :duration_hours, :is_upcoming?, :is_past?, :is_ongoing? ]
      )
    else
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    head :no_content
  end

  private

  def set_event
    @event = Event.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Event not found" }, status: :not_found
  end

  def event_params
    params.require(:event).permit(:title, :description, :event_type, :start_time, :end_time, :location, :status, attendee_ids: [])
  end
end
