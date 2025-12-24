class ProcessExtractorController < ApplicationController
  def new
    @process_extractor = ProcessExtractor.new
  end

  def create
    @process_extractor = ProcessExtractor.new(process_extractor_params)

    if @process_extractor.valid?
      result = @process_extractor.research_process
      board_info = create_board_with_cards(result)

      session[:process_extractor_board] = board_info
      redirect_to process_extractor_path
    else
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("ProcessExtractor error: #{e.message}")
    redirect_to new_process_extractor_path, alert: "Error creating board: #{e.message}"
  end

  def show
    @board = session.delete(:process_extractor_board)

    if @board.nil?
      redirect_to new_process_extractor_path, alert: "No board found. Please try again."
    end
  end

  private
    def process_extractor_params
      params.require(:process_extractor).permit(:process_description)
    end

    def create_board_with_cards(result)
      board_name = result["board_name"]
      columns = result["columns"] || []
      cards = result["cards"] || []

      client = FizzyApiClient::Client.new
      board = client.create_board(name: board_name)

      columns.each do |column|
        client.create_column(
          board_id: board["id"],
          name: column["name"],
          color: column["color"].to_sym
        )
      end

      cards.each do |card|
        client.create_card(
          board_id: board["id"],
          title: card["title"],
          description: card["description"]
        )
      end

      {
        "name" => board_name,
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
