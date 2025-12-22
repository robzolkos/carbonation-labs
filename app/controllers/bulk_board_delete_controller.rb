class BulkBoardDeleteController < ApplicationController
  def show
    client = FizzyApiClient::Client.new
    @boards = client.boards(auto_paginate: true)
  rescue => e
    Rails.logger.error("BulkBoardDelete error fetching boards: #{e.message}")
    @boards = []
    flash.now[:alert] = "Error fetching boards: #{e.message}"
  end

  def destroy
    board_ids = params[:board_ids] || []

    if board_ids.empty?
      redirect_to bulk_board_delete_path, alert: "No boards selected."
      return
    end

    client = FizzyApiClient::Client.new
    deleted_count = 0

    board_ids.each do |board_id|
      client.delete_board(board_id)
      deleted_count += 1
    rescue => e
      Rails.logger.error("Failed to delete board #{board_id}: #{e.message}")
    end

    redirect_to bulk_board_delete_path, notice: "Deleted #{deleted_count} board(s)."
  end
end
