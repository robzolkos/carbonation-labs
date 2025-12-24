class GiftIdeaGeneratorController < ApplicationController
  def new
    @gift_idea_generator = GiftIdeaGenerator.new
  end

  def create
    @gift_idea_generator = GiftIdeaGenerator.new(gift_idea_generator_params)

    if @gift_idea_generator.valid?
      result = @gift_idea_generator.generate_recommendations
      board_info = create_board_with_cards(result)

      session[:gift_idea_generator_board] = board_info
      redirect_to gift_idea_generator_path
    else
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("GiftIdeaGenerator error: #{e.message}")
    redirect_to new_gift_idea_generator_path, alert: "Error creating board: #{e.message}"
  end

  def show
    @board = session.delete(:gift_idea_generator_board)

    if @board.nil?
      redirect_to new_gift_idea_generator_path, alert: "No board found. Please try again."
    end
  end

  private
    def gift_idea_generator_params
      params.require(:gift_idea_generator).permit(:recipient_description)
    end

    def create_board_with_cards(result)
      board_name = result["board_name"]
      items = result["items"] || []

      client = FizzyApiClient::Client.new
      board = client.create_board(name: board_name)

      GiftIdeaGenerator::COLUMNS.each do |column|
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
      "https://fizzy.do/#{account_slug}/boards/#{board_id}"
    end
end
