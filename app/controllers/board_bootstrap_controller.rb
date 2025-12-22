class BoardBootstrapController < ApplicationController
  def new
    @board_bootstrap = BoardBootstrap.new
  end

  def create
    @board_bootstrap = BoardBootstrap.new(board_bootstrap_params)

    if @board_bootstrap.valid?
      session[:board_bootstrap_columns] = @board_bootstrap.generate_columns
      session[:board_bootstrap_description] = @board_bootstrap.description
      redirect_to board_bootstrap_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @columns = session[:board_bootstrap_columns]
    @description = session[:board_bootstrap_description]

    redirect_to new_board_bootstrap_path, alert: "No columns generated. Please try again." unless @columns
  end

  def confirm
    board_name = params[:board_name]
    columns = JSON.parse(params[:columns])

    client = FizzyApiClient::Client.new
    board = client.create_board(name: board_name)

    columns.each do |column|
      client.create_column(
        board_id: board["id"],
        name: column["name"],
        color: column["color"].to_sym
      )
    end

    session.delete(:board_bootstrap_columns)
    session.delete(:board_bootstrap_description)
    redirect_to root_path, notice: "Board '#{board_name}' created with #{columns.size} custom columns!"
  rescue => e
    redirect_to root_path, alert: "Error creating board: #{e.message}"
  end

  private

  def board_bootstrap_params
    params.require(:board_bootstrap).permit(:description)
  end
end
