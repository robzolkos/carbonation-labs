class CsvToBoardController < ApplicationController
  def new
    @csv_to_board = CsvToBoard.new
  end

  def create
    @csv_to_board = CsvToBoard.new(csv_to_board_params)

    if @csv_to_board.valid? && @csv_to_board.headers.any?
      board_info = create_board_with_cards
      session[:csv_to_board_result] = board_info
      redirect_to csv_to_board_path
    else
      @csv_to_board.errors.add(:csv_data, "must have at least one column") if @csv_to_board.headers.empty?
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("CsvToBoard error: #{e.message}")
    redirect_to new_csv_to_board_path, alert: "Error creating board: #{e.message}"
  end

  def show
    @board = session.delete(:csv_to_board_result)

    if @board.nil?
      redirect_to new_csv_to_board_path, alert: "No board found. Please try again."
    end
  end

  private
    def csv_to_board_params
      params.require(:csv_to_board).permit(:csv_data, :board_name, :title_column, :description_column)
    end

    def create_board_with_cards
      cards = @csv_to_board.cards

      client = FizzyApiClient::Client.new
      board = client.create_board(name: @csv_to_board.board_name)

      cards.each do |card|
        client.create_card(
          board_id: board["id"],
          title: card[:title],
          description: card[:description]
        )
      end

      {
        "name" => @csv_to_board.board_name,
        "id" => board["id"],
        "card_count" => cards.size,
        "url" => fizzy_board_url(board["id"])
      }
    end

    def fizzy_board_url(board_id)
      account_slug = ENV["FIZZY_ACCOUNT_SLUG"]
      "https://app.fizzy.do/#{account_slug}/boards/#{board_id}"
    end
end
