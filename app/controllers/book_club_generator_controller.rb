class BookClubGeneratorController < ApplicationController
  def new
    @book_club_generator = BookClubGenerator.new
  end

  def create
    @book_club_generator = BookClubGenerator.new(book_club_generator_params)

    if @book_club_generator.valid?
      result = @book_club_generator.generate_recommendations
      board_info = create_board_with_cards(result)

      session[:book_club_generator_board] = board_info
      redirect_to book_club_generator_path
    else
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("BookClubGenerator error: #{e.message}")
    redirect_to new_book_club_generator_path, alert: "Error creating board: #{e.message}"
  end

  def show
    @board = session.delete(:book_club_generator_board)

    if @board.nil?
      redirect_to new_book_club_generator_path, alert: "No board found. Please try again."
    end
  end

  private
    def book_club_generator_params
      params.require(:book_club_generator).permit(:favorite_books)
    end

    def create_board_with_cards(result)
      board_name = result["board_name"]
      items = result["items"] || []

      client = FizzyApiClient::Client.new
      board = client.create_board(name: board_name)

      BookClubGenerator::COLUMNS.each do |column|
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
          image_type: "book",
          author: item["author"]
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
