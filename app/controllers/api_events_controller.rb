class ApiEventsController < ApplicationController
  acts_as_token_authentication_handler_for User, fallback_to_devise: false

  before_action :set_event, only: [:show, :edit, :update, :destroy, :check_admin]
  before_action :verify_logged_in
  before_action :parse_dates, only: [:update, :create]

  # GET /events.json
  # maybe allow for site admins later on?
  def index
    @all_event_ids = Event.all.pluck(:id)
    @my_event_ids = current_user.subscriptions.pluck(:event_id)
    @my_events = Event.find(@my_event_ids)
    @not_my_events = Event.find(@all_event_ids - @my_event_ids)

    render json: { status: "success", data:
                   { subscribed: @my_events.as_json(
                       include: {channels: {}}
                     ), 
                     not_subscribed: @not_my_events.as_json(
                       include: {channels: {}}
                     )
                   }
                 }
  end

  # GET /events/1.json
  def show
    if @event.nil?
      render json: { status: "failure", error: "Event not found, or unauthorized." }
    else
      @subscription = Subscription.where(user_id: current_user.id, event_id: @event.id).first
      @data = @event.as_json(include: { channels: {include: :notifications } })
      @data["subscription"] = @subscription.as_json
      @subevents = @event.subevents.group_by { |s| s.start_time.to_formatted_s(:iso8601) }
      @data["subevents"] = @subevents.as_json
      render json: { status: "success", data: @data }
    end
  end

  def check_admin
    puts @event.id
    authorize! :manage, @event
    render json: { status: "success" }
  end

  # POST /events.json
  def create
    @event = Event.new(event_params)

    if not (@start_time and @end_time)
      render json: { status: "failure", error: "Start / end datetime not valid." }
      return
    end

    @event.start_time = @start_time
    @event.end_time = @end_time

    if @event.save
      @event.subscriptions.create!(user_id: current_user.id, admin: true)
      @event.channels.create!(name: "Notifications")
      render json: { status: "success", data: @event.as_json }
    else
      render json: { status: "failure", error: "Event not valid." }
    end
  end

  # PATCH/PUT /events/1.json
  def update
    authorize! :manage, @event

    @event.start_time = @start_time
    @event.end_time = @end_time

    if @event.update(event_params)
      render json: { status: "success", data: @event.as_json }
    else
      render json: { status: "failure", error: "Event not valid." }
    end
  end

  private
    def parse_dates
      @start_time = DateTime.parse(event_params[:start_time]) rescue nil
      @end_time = DateTime.parse(event_params[:end_time]) rescue nil
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find_by_id(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def event_params
      params.require(:event).permit(:name, :cover_photo_url, :start_time, :end_time, :description, :address, :event_map_url, :twitter_widget_id, :timezone, :published, :website_url, :facebook_url)
    end
end
