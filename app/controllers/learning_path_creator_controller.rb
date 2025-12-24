class LearningPathCreatorController < ApplicationController
  def new
    @learning_path_creator = LearningPathCreator.new
  end

  def create
    @learning_path_creator = LearningPathCreator.new(learning_path_creator_params)

    if @learning_path_creator.valid?
      result = @learning_path_creator.generate_recommendations
      board_info = create_board_with_cards(result)

      session[:learning_path_creator_board] = board_info
      redirect_to learning_path_creator_path
    else
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("LearningPathCreator error: #{e.message}")
    redirect_to new_learning_path_creator_path, alert: "Error creating board: #{e.message}"
  end

  def show
    @board = session.delete(:learning_path_creator_board)

    if @board.nil?
      redirect_to new_learning_path_creator_path, alert: "No board found. Please try again."
    end
  end

  private
    def learning_path_creator_params
      params.require(:learning_path_creator).permit(:skill_to_learn)
    end

    def create_board_with_cards(result)
      board_name = result["board_name"]
      items = result["items"] || []

      client = FizzyApiClient::Client.new
      board = client.create_board(name: board_name)

      LearningPathCreator::COLUMNS.each do |column|
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
      level = item["level"] ? "<p><em>Level: #{item["level"]}</em></p>" : ""
      <<~HTML
        <p><strong>#{item["meta"]}</strong></p>
        #{level}
        #{item["description"]}
      HTML
    end

    def fizzy_board_url(board_id)
      account_slug = ENV["FIZZY_ACCOUNT_SLUG"]
      "https://fizzy.do/#{account_slug}/boards/#{board_id}"
    end
end
