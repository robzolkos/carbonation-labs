class RestaurantBucketListController < ApplicationController
  def new
    @restaurant_bucket_list = RestaurantBucketList.new
  end

  def create
    @restaurant_bucket_list = RestaurantBucketList.new(restaurant_bucket_list_params)

    if @restaurant_bucket_list.valid?
      result = @restaurant_bucket_list.generate_recommendations
      board_info = create_board_with_cards(result)

      session[:restaurant_bucket_list_board] = board_info
      redirect_to restaurant_bucket_list_path
    else
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("RestaurantBucketList error: #{e.message}")
    redirect_to new_restaurant_bucket_list_path, alert: "Error creating board: #{e.message}"
  end

  def show
    @board = session.delete(:restaurant_bucket_list_board)

    if @board.nil?
      redirect_to new_restaurant_bucket_list_path, alert: "No board found. Please try again."
    end
  end

  private
    def restaurant_bucket_list_params
      params.require(:restaurant_bucket_list).permit(:location_preferences)
    end

    def create_board_with_cards(result)
      board_name = result["board_name"]
      items = result["items"] || []

      client = FizzyApiClient::Client.new
      board = client.create_board(name: board_name)

      RestaurantBucketList::COLUMNS.each do |column|
        client.create_column(
          board_id: board["id"],
          name: column[:name],
          color: column[:color].to_sym
        )
      end

      items.each do |item|
        description = build_card_description(item)

        client.create_card(
          board_id: board["id"],
          title: item["title"],
          description: description
        )
      end

      {
        "name" => board_name,
        "id" => board["id"],
        "card_count" => items.size,
        "url" => fizzy_board_url(board["id"])
      }
    end

    def build_card_description(item)
      <<~HTML
        <p><strong>#{item["meta"]}</strong></p>
        #{item["description"]}
      HTML
    end

    def fizzy_board_url(board_id)
      account_slug = ENV["FIZZY_ACCOUNT_SLUG"]
      "https://app.fizzy.do/#{account_slug}/boards/#{board_id}"
    end
end
