class FetchCardImageJob < ApplicationJob
  queue_as :default

  include ImageDownloader

  def perform(card_number:, title:, image_type:, **options)
    image_path = case image_type
    when "movie"
      fetch_movie_image(title, year: options[:year])
    when "book"
      fetch_book_image(title, author: options[:author])
    else
      nil
    end

    if image_path
      client = FizzyApiClient::Client.new
      client.update_card(card_number, image: image_path)
      Rails.logger.info("FetchCardImageJob: Updated card #{card_number} with image")
    else
      Rails.logger.info("FetchCardImageJob: No image found for card #{card_number} (#{title})")
    end
  rescue => e
    Rails.logger.error("FetchCardImageJob error for card #{card_number}: #{e.message}")
    # Don't re-raise - image is optional, card still exists
  end
end
