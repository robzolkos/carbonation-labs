class BoardBootstrapController < ApplicationController
  def new
    @board_bootstrap = BoardBootstrap.new
  end

  def create
    @board_bootstrap = BoardBootstrap.new(board_bootstrap_params)

    if @board_bootstrap.valid?
      columns = @board_bootstrap.generate_columns
      board_info = create_board_with_columns(@board_bootstrap.board_name, columns)

      session[:board_bootstrap_board] = board_info
      redirect_to board_bootstrap_path
    else
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error("BoardBootstrap error: #{e.message}")
    redirect_to new_board_bootstrap_path, alert: "Error creating board: #{e.message}"
  end

  def show
    @board = session.delete(:board_bootstrap_board)

    if @board.nil?
      redirect_to new_board_bootstrap_path, alert: "No board found. Please try again."
    end
  end

  private
    def board_bootstrap_params
      params.require(:board_bootstrap).permit(:description, :board_name)
    end

    def create_board_with_columns(board_name, columns)
      client = FizzyApiClient::Client.new
      board = client.create_board(name: board_name)

      columns.each do |column|
        client.create_column(
          board_id: board["id"],
          name: column["name"],
          color: column["color"].to_sym
        )
      end

      {
        "name" => board_name,
        "id" => board["id"],
        "column_count" => columns.size,
        "url" => fizzy_board_url(board["id"])
      }
    end

    def fizzy_board_url(board_id)
      account_slug = ENV["FIZZY_ACCOUNT_SLUG"]
      "https://fizzy.do/#{account_slug}/boards/#{board_id}"
    end
end
