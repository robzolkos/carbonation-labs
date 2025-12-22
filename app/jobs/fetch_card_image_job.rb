class FetchCardImageJob < ApplicationJob
  queue_as :default

  include ImageDownloader

  def perform(card_number:, title:, image_type:, **options)
    poster_path = case image_type
    when "movie"
      fetch_movie_image(title, year: options[:year])
    when "book"
      fetch_book_image(title, author: options[:author])
    else
      nil
    end

    return log_no_image(card_number, title) unless poster_path

    # For movies, create card image with dominant color background and title
    final_image_path = if image_type == "movie"
      create_card_image(poster_path, title: title) || poster_path
    else
      poster_path
    end

    client = FizzyApiClient::Client.new
    client.update_card(card_number, image: final_image_path)
    Rails.logger.info("FetchCardImageJob: Updated card #{card_number} with image")
  rescue => e
    Rails.logger.error("FetchCardImageJob error for card #{card_number}: #{e.message}")
    # Don't re-raise - image is optional, card still exists
  end

  private
    def log_no_image(card_number, title)
      Rails.logger.info("FetchCardImageJob: No image found for card #{card_number} (#{title})")
    end
end
