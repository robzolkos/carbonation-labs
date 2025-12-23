class ProcessExtractorController < ApplicationController
  def new
    @process_extractor = ProcessExtractor.new
  end

  def create
    @process_extractor = ProcessExtractor.new(process_extractor_params)

    if @process_extractor.valid?
      result = @process_extractor.research_process
      cache_key = "process_extractor:#{SecureRandom.hex(16)}"
      Rails.cache.write(cache_key, result, expires_in: 1.hour)
      session[:process_extractor_cache_key] = cache_key
      session[:process_extractor_description] = @process_extractor.process_description
      redirect_to process_extractor_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    cache_key = session[:process_extractor_cache_key]
    @result = cache_key ? Rails.cache.read(cache_key) : nil
    @description = session[:process_extractor_description]

    if @result.nil?
      redirect_to new_process_extractor_path, alert: "No process researched. Please try again."
    else
      @board_name = @result["board_name"]
      @columns = @result["columns"] || []
      @cards = @result["cards"] || []
    end
  end

  def confirm
    board_name = params[:board_name]
    columns = JSON.parse(params[:columns])
    cards = JSON.parse(params[:cards])

    client = FizzyApiClient::Client.new
    board = client.create_board(name: board_name)

    columns.each do |column|
      client.create_column(
        board_id: board["id"],
        name: column["name"],
        color: column["color"].to_sym
      )
    end

    cards.each do |card|
      client.create_card(
        board_id: board["id"],
        title: card["title"],
        description: card["description"]
      )
    end

    cache_key = session.delete(:process_extractor_cache_key)
    Rails.cache.delete(cache_key) if cache_key
    session.delete(:process_extractor_description)
    redirect_to root_path, notice: "Board '#{board_name}' created with #{cards.size} cards!"
  rescue => e
    redirect_to root_path, alert: "Error creating board: #{e.message}"
  end

  private

    def process_extractor_params
      params.require(:process_extractor).permit(:process_description)
    end
end
