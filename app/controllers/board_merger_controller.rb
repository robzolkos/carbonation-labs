class BoardMergerController < ApplicationController
  def new
    client = FizzyApiClient::Client.new
    @boards = client.boards(auto_paginate: true).map do |board|
      cards = client.cards(board_id: board["id"], auto_paginate: true)
      board.merge("card_count" => cards.size)
    end
  rescue => e
    Rails.logger.error("BoardMerger error fetching boards: #{e.message}")
    @boards = []
    flash.now[:alert] = "Error fetching boards: #{e.message}"
  end

  def create
    source_board_id = params[:source_board_id]
    target_board_id = params[:target_board_id]
    delete_source = params[:delete_source] == "1"

    if source_board_id.blank?
      redirect_to new_board_merger_path, alert: "Please select a source board."
      return
    end

    if target_board_id.blank?
      redirect_to new_board_merger_path, alert: "Please select a target board."
      return
    end

    if source_board_id == target_board_id
      redirect_to new_board_merger_path, alert: "Source and target boards must be different."
      return
    end

    result = merge_boards(source_board_id, target_board_id, delete_source)
    session[:board_merger_result] = result
    redirect_to board_merger_path
  rescue => e
    Rails.logger.error("BoardMerger error: #{e.message}")
    redirect_to new_board_merger_path, alert: "Error merging boards: #{e.message}"
  end

  def show
    @result = session.delete(:board_merger_result)

    if @result.nil?
      redirect_to new_board_merger_path, alert: "No result found. Please try again."
    end
  end

  private
    def merge_boards(source_board_id, target_board_id, delete_source)
      client = FizzyApiClient::Client.new

      boards = client.boards(auto_paginate: true)
      source_board = boards.find { |b| b["id"] == source_board_id }
      target_board = boards.find { |b| b["id"] == target_board_id }

      source_cards = client.cards(board_id: source_board_id, auto_paginate: true)
      Rails.logger.info("BoardMerger: Found #{source_cards.size} cards in source board #{source_board_id}")

      source_cards.each do |card|
        client.create_card(
          board_id: target_board_id,
          title: card["title"],
          description: card["description"]
        )
      end

      if delete_source
        client.delete_board(source_board_id)
      end

      {
        "source_name" => source_board&.dig("name") || "Unknown",
        "target_name" => target_board&.dig("name") || "Unknown",
        "target_id" => target_board_id,
        "cards_moved" => source_cards.size,
        "source_deleted" => delete_source,
        "url" => fizzy_board_url(target_board_id)
      }
    end

    def fizzy_board_url(board_id)
      account_slug = ENV["FIZZY_ACCOUNT_SLUG"]
      "https://app.fizzy.do/#{account_slug}/boards/#{board_id}"
    end
end
