class CardMoverController < ApplicationController
  def new
    client = FizzyApiClient::Client.new
    @boards = client.boards(auto_paginate: true).map do |board|
      cards = client.cards(board_id: board["id"], auto_paginate: true)
      board.merge("card_count" => cards.size)
    end
  rescue => e
    Rails.logger.error("CardMover error fetching boards: #{e.message}")
    @boards = []
    flash.now[:alert] = "Error fetching boards: #{e.message}"
  end

  def create
    source_board_ids = Array(params[:source_board_ids]).reject(&:blank?)
    target_board_id = params[:target_board_id]

    if source_board_ids.empty?
      redirect_to new_card_mover_path, alert: "Please select at least one source board."
      return
    end

    if target_board_id.blank?
      redirect_to new_card_mover_path, alert: "Please select a target board."
      return
    end

    if source_board_ids.include?(target_board_id)
      redirect_to new_card_mover_path, alert: "Target board cannot also be a source board."
      return
    end

    result = move_cards(source_board_ids, target_board_id)
    session[:card_mover_result] = result
    redirect_to card_mover_path
  rescue => e
    Rails.logger.error("CardMover error: #{e.message}")
    redirect_to new_card_mover_path, alert: "Error moving cards: #{e.message}"
  end

  def show
    @result = session.delete(:card_mover_result)

    if @result.nil?
      redirect_to new_card_mover_path, alert: "No result found. Please try again."
    end
  end

  private
    def move_cards(source_board_ids, target_board_id)
      client = FizzyApiClient::Client.new

      boards = client.boards(auto_paginate: true)
      target_board = boards.find { |b| b["id"] == target_board_id }

      total_cards = 0
      source_names = []

      source_board_ids.each do |source_id|
        source_board = boards.find { |b| b["id"] == source_id }
        source_names << source_board&.dig("name") if source_board

        cards = client.cards(board_id: source_id, auto_paginate: true)
        cards.each do |card|
          client.create_card(
            board_id: target_board_id,
            title: card["title"],
            description: card["description"]
          )
          total_cards += 1
        end
      end

      {
        "source_names" => source_names,
        "source_count" => source_board_ids.size,
        "target_name" => target_board&.dig("name") || "Unknown",
        "target_id" => target_board_id,
        "cards_moved" => total_cards,
        "url" => fizzy_board_url(target_board_id)
      }
    end

    def fizzy_board_url(board_id)
      account_slug = ENV["FIZZY_ACCOUNT_SLUG"]
      "https://app.fizzy.do/#{account_slug}/boards/#{board_id}"
    end
end
