class HomeworkCoachController < ApplicationController
  def new
    @homework_coach = HomeworkCoach.new
  end

  def create
    @homework_coach = HomeworkCoach.new(homework_coach_params)

    if @homework_coach.valid?
      result = @homework_coach.generate_help
      board_info = create_board_with_cards(result)

      session[:homework_coach_board] = board_info
      redirect_to homework_coach_path
    else
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("HomeworkCoach error: #{e.message}")
    redirect_to new_homework_coach_path, alert: "Error creating board: #{e.message}"
  end

  def show
    @board = session.delete(:homework_coach_board)

    if @board.nil?
      redirect_to new_homework_coach_path, alert: "No board found. Please try again."
    end
  end

  private
    def homework_coach_params
      params.require(:homework_coach).permit(:struggle, :grade_level)
    end

    def create_board_with_cards(result)
      board_name = result["board_name"]
      items = result["items"] || []

      client = FizzyApiClient::Client.new
      board = client.create_board(name: board_name)

      HomeworkCoach::COLUMNS.each do |column|
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
      html = item["description"]

      if item["links"].present?
        html += "<p><strong>Helpful Resources:</strong></p><ul>"
        item["links"].each do |link|
          html += %(<li><a href="#{link["url"]}" target="_blank">#{link["text"]}</a></li>)
        end
        html += "</ul>"
      end

      html
    end

    def fizzy_board_url(board_id)
      account_slug = ENV["FIZZY_ACCOUNT_SLUG"]
      "https://app.fizzy.do/#{account_slug}/boards/#{board_id}"
    end
end
