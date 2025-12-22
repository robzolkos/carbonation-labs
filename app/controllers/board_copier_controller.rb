class BoardCopierController < ApplicationController
  def new
    client = FizzyApiClient::Client.new
    @boards = client.boards(auto_paginate: true)
  rescue => e
    Rails.logger.error("BoardCopier error fetching boards: #{e.message}")
    @boards = []
    flash.now[:alert] = "Error fetching boards: #{e.message}"
  end

  def create
    source_board_id = params[:source_board_id]
    source_board_name = params[:source_board_name]
    new_board_name = params[:new_board_name]

    if source_board_id.blank?
      redirect_to new_board_copier_path, alert: "Please select a board to copy."
      return
    end

    if new_board_name.blank?
      redirect_to new_board_copier_path, alert: "Please enter a name for the new board."
      return
    end

    board_info = copy_board(source_board_id, source_board_name, new_board_name)
    session[:board_copier_result] = board_info
    redirect_to board_copier_path
  rescue => e
    Rails.logger.error("BoardCopier error: #{e.message}")
    redirect_to new_board_copier_path, alert: "Error copying board: #{e.message}"
  end

  def show
    @board = session.delete(:board_copier_result)

    if @board.nil?
      redirect_to new_board_copier_path, alert: "No board found. Please try again."
    end
  end

  private
    def copy_board(source_board_id, source_board_name, new_board_name)
      client = FizzyApiClient::Client.new

      source_columns = client.columns(source_board_id)
      source_cards = client.cards(board_id: source_board_id, auto_paginate: true)

      new_board = client.create_board(name: new_board_name)

      source_columns.each do |column|
        color = column["color"]
        color_sym = color.is_a?(String) ? color.to_sym : nil
        client.create_column(
          board_id: new_board["id"],
          name: column["name"],
          color: color_sym
        )
      end

      source_cards.each do |card|
        client.create_card(
          board_id: new_board["id"],
          title: card["title"],
          description: card["description"]
        )
      end

      {
        "name" => new_board_name,
        "id" => new_board["id"],
        "source_name" => source_board_name,
        "column_count" => source_columns.size,
        "card_count" => source_cards.size,
        "url" => fizzy_board_url(new_board["id"])
      }
    end

    def fizzy_board_url(board_id)
      account_slug = ENV["FIZZY_ACCOUNT_SLUG"]
      "https://app.fizzy.do/#{account_slug}/boards/#{board_id}"
    end
end
