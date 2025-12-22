class EmailToTasksController < ApplicationController
  def new
    @email_to_tasks = EmailToTasks.new
  end

  def create
    @email_to_tasks = EmailToTasks.new(email_to_tasks_params)

    if @email_to_tasks.valid?
      result = @email_to_tasks.extract_tasks
      board_info = create_board_with_cards(result)

      session[:email_to_tasks_board] = board_info
      redirect_to email_to_tasks_path
    else
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("EmailToTasks error: #{e.message}")
    redirect_to new_email_to_tasks_path, alert: "Error creating board: #{e.message}"
  end

  def show
    @board = session.delete(:email_to_tasks_board)

    if @board.nil?
      redirect_to new_email_to_tasks_path, alert: "No board found. Please try again."
    end
  end

  private
    def email_to_tasks_params
      params.require(:email_to_tasks).permit(:email_content, :board_name)
    end

    def create_board_with_cards(result)
      board_name = result["board_name"]
      items = result["items"] || []

      client = FizzyApiClient::Client.new
      board = client.create_board(name: board_name)

      EmailToTasks::COLUMNS.each do |column|
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
