class TripPlannerController < ApplicationController
  def new
    @trip_planner = TripPlanner.new
  end

  def create
    @trip_planner = TripPlanner.new(trip_planner_params)

    if @trip_planner.valid?
      result = @trip_planner.generate_itinerary
      board_info = create_board_with_cards(result)

      session[:trip_planner_board] = board_info
      redirect_to trip_planner_path
    else
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("TripPlanner error: #{e.message}")
    redirect_to new_trip_planner_path, alert: "Error creating board: #{e.message}"
  end

  def show
    @board = session.delete(:trip_planner_board)

    if @board.nil?
      redirect_to new_trip_planner_path, alert: "No board found. Please try again."
    end
  end

  private
    def trip_planner_params
      params.require(:trip_planner).permit(:destination, :trip_length, :interests)
    end

    def create_board_with_cards(result)
      board_name = result["board_name"]
      items = result["items"] || []

      client = FizzyApiClient::Client.new
      board = client.create_board(name: board_name)

      TripPlanner::COLUMNS.each do |column|
        client.create_column(
          board_id: board["id"],
          name: column[:name],
          color: column[:color].to_sym
        )
      end

      items.each do |item|
        client.create_card(
          board_id: board["id"],
          title: item["title"],
          description: item["description"]
        )
      end

      {
        "name" => board_name,
        "id" => board["id"],
        "card_count" => items.size,
        "url" => fizzy_board_url(board["id"])
      }
    end

    def fizzy_board_url(board_id)
      account_slug = ENV["FIZZY_ACCOUNT_SLUG"]
      "https://app.fizzy.do/#{account_slug}/boards/#{board_id}"
    end
end
