class MovieQuizGeneratorController < ApplicationController
  def new
    @movie_quiz_generator = MovieQuizGenerator.new
  end

  def create
    @movie_quiz_generator = MovieQuizGenerator.new(movie_quiz_generator_params)

    if @movie_quiz_generator.valid?
      result = @movie_quiz_generator.generate_quiz
      board_info = create_board_with_cards(result)

      session[:movie_quiz_generator_board] = board_info
      redirect_to movie_quiz_generator_path
    else
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("MovieQuizGenerator error: #{e.message}")
    redirect_to new_movie_quiz_generator_path, alert: "Error creating board: #{e.message}"
  end

  def show
    @board = session.delete(:movie_quiz_generator_board)

    if @board.nil?
      redirect_to new_movie_quiz_generator_path, alert: "No board found. Please try again."
    end
  end

  private
    def movie_quiz_generator_params
      params.require(:movie_quiz_generator).permit(:topic, :teams, :question_count)
    end

    def create_board_with_cards(result)
      board_name = result["board_name"]
      items = result["items"] || []

      client = FizzyApiClient::Client.new
      board = client.create_board(name: board_name)

      @movie_quiz_generator.columns.each do |column|
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
