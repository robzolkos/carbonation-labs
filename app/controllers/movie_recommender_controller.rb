class MovieRecommenderController < ApplicationController
  def new
    @movie_recommender = MovieRecommender.new
  end

  def create
    @movie_recommender = MovieRecommender.new(movie_recommender_params)

    if @movie_recommender.valid?
      result = @movie_recommender.generate_recommendations
      board_info = create_board_with_cards(result)

      session[:movie_recommender_board] = board_info
      redirect_to movie_recommender_path
    else
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("MovieRecommender error: #{e.message}")
    redirect_to new_movie_recommender_path, alert: "Error creating board: #{e.message}"
  end

  def show
    @board = session.delete(:movie_recommender_board)

    if @board.nil?
      redirect_to new_movie_recommender_path, alert: "No board found. Please try again."
    end
  end

  private
    def movie_recommender_params
      params.require(:movie_recommender).permit(:favorite_movies)
    end

    def create_board_with_cards(result)
      board_name = result["board_name"]
      items = result["items"] || []

      client = FizzyApiClient::Client.new
      board = client.create_board(name: board_name)

      MovieRecommender::COLUMNS.each do |column|
        client.create_column(
          board_id: board["id"],
          name: column[:name],
          color: column[:color].to_sym
        )
      end

      items.each do |item|
        description = build_card_description(item)

        card = client.create_card(
          board_id: board["id"],
          title: item["title"],
          description: description
        )

        FetchCardImageJob.perform_later(
          card_number: card["number"],
          title: item["title"],
          image_type: "movie",
          year: item["year"]
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
      "https://fizzy.do/#{account_slug}/boards/#{board_id}"
    end
end
