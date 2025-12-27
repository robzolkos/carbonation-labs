class PartyPromptsController < ApplicationController
  def new
    @party_prompts = PartyPrompts.new
  end

  def create
    @party_prompts = PartyPrompts.new(party_prompts_params)

    if @party_prompts.valid?
      result = @party_prompts.generate_prompts
      board_info = create_board_with_cards(result)

      session[:party_prompts_board] = board_info
      redirect_to party_prompts_path
    else
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("PartyPrompts error: #{e.message}")
    redirect_to new_party_prompts_path, alert: "Error creating board: #{e.message}"
  end

  def show
    @board = session.delete(:party_prompts_board)

    if @board.nil?
      redirect_to new_party_prompts_path, alert: "No board found. Please try again."
    end
  end

  private
    def party_prompts_params
      params.require(:party_prompts).permit(:game_type, :category, :difficulty, :prompt_count, :teams)
    end

    def create_board_with_cards(result)
      board_name = result["board_name"]
      items = result["items"] || []

      client = FizzyApiClient::Client.new
      board = client.create_board(name: board_name)

      @party_prompts.columns.each do |column|
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
