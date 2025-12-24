# frozen_string_literal: true

require "open-uri"
require "tempfile"
require "net/http"
require "json"

module ImageDownloader
  extend ActiveSupport::Concern

  WIKIPEDIA_API = "https://en.wikipedia.org/w/api.php"
  OPEN_LIBRARY_SEARCH = "https://openlibrary.org/search.json"
  OPEN_LIBRARY_COVERS = "https://covers.openlibrary.org/b/id"
  OMDB_API = "https://www.omdbapi.com"

  # Download an image from a URL to a temp file
  def download_image(url)
    return nil if url.blank?

    uri = URI.parse(url)
    response = uri.open(
      "User-Agent" => "CarbonationLabs/1.0 (https://github.com/carbonation-labs)",
      read_timeout: 10,
      open_timeout: 5
    )
    ext = File.extname(uri.path).presence || ".jpg"
    temp_file = Tempfile.new([ "card_image", ext ])
    temp_file.binmode
    temp_file.write(response.read)
    temp_file.rewind
    temp_file.path
  rescue StandardError => e
    Rails.logger.error("Failed to download image from #{url}: #{e.message}")
    nil
  end

  # Fetch movie poster - tries OMDB (if API key set), then Wikipedia
  def fetch_movie_image(title, year: nil)
    # Try OMDB first if API key is configured
    if ENV["OMDB_API_KEY"].present?
      image_path = fetch_omdb_poster(title, year)
      return image_path if image_path
    end

    # Fall back to Wikipedia
    search_type = year ? "#{year} film" : "film"
    fetch_wikipedia_image(title, type: search_type)
  end

  # Fetch book cover - tries Open Library first, then Wikipedia
  def fetch_book_image(title, author: nil)
    # Try Open Library first (free, no API key, best for books)
    image_path = fetch_open_library_cover(title, author)
    return image_path if image_path

    # Fall back to Wikipedia
    search_type = author ? "#{author} novel" : "novel"
    fetch_wikipedia_image(title, type: search_type)
  end

  # Search Wikipedia for an image
  def fetch_wikipedia_image(search_term, type: "")
    search_query = "#{search_term} #{type}".strip
    image_url = find_wikipedia_page_image(search_query)
    return nil unless image_url

    download_image(image_url)
  rescue StandardError => e
    Rails.logger.error("Wikipedia image fetch failed for '#{search_term}': #{e.message}")
    nil
  end

  private
    # OMDB API for movie posters (requires free API key from omdbapi.com)
    def fetch_omdb_poster(title, year = nil)
      uri = URI(OMDB_API)
      params = {
        apikey: ENV["OMDB_API_KEY"],
        t: title,
        type: "movie"
      }
      params[:y] = year if year.present?
      uri.query = URI.encode_www_form(params)

      response = Net::HTTP.get(uri)
      data = JSON.parse(response)

      return nil unless data["Response"] == "True" && data["Poster"].present? && data["Poster"] != "N/A"

      Rails.logger.info("OMDB found poster for '#{title}': #{data["Poster"]}")
      download_image(data["Poster"])
    rescue StandardError => e
      Rails.logger.error("OMDB fetch failed for '#{title}': #{e.message}")
      nil
    end

    # Open Library API for book covers (free, no API key needed)
    def fetch_open_library_cover(title, author = nil)
      search_query = author.present? ? "#{title} #{author}" : title
      uri = URI(OPEN_LIBRARY_SEARCH)
      uri.query = URI.encode_www_form(
        q: search_query,
        limit: 1,
        fields: "cover_i,title,author_name"
      )

      response = Net::HTTP.get(uri)
      data = JSON.parse(response)
      docs = data["docs"]

      return nil if docs.nil? || docs.empty?

      cover_id = docs.first["cover_i"]
      return nil unless cover_id

      cover_url = "#{OPEN_LIBRARY_COVERS}/#{cover_id}-L.jpg"
      Rails.logger.info("Open Library found cover for '#{title}': #{cover_url}")
      download_image(cover_url)
    rescue StandardError => e
      Rails.logger.error("Open Library fetch failed for '#{title}': #{e.message}")
      nil
    end

    # Wikipedia API for page images
    def find_wikipedia_page_image(query)
      # First, search for the page
      search_uri = URI(WIKIPEDIA_API)
      search_uri.query = URI.encode_www_form(
        action: "query",
        list: "search",
        srsearch: query,
        srlimit: 1,
        format: "json"
      )

      search_response = Net::HTTP.get(search_uri)
      search_data = JSON.parse(search_response)
      pages = search_data.dig("query", "search")
      return nil if pages.nil? || pages.empty?

      page_title = pages.first["title"]

      # Now get the page image
      image_uri = URI(WIKIPEDIA_API)
      image_uri.query = URI.encode_www_form(
        action: "query",
        titles: page_title,
        prop: "pageimages",
        pithumbsize: 500,
        format: "json"
      )

      image_response = Net::HTTP.get(image_uri)
      image_data = JSON.parse(image_response)
      pages = image_data.dig("query", "pages")
      return nil if pages.nil?

      page = pages.values.first
      thumbnail_url = page.dig("thumbnail", "source")
      Rails.logger.info("Wikipedia found image for '#{query}': #{thumbnail_url}") if thumbnail_url
      thumbnail_url
    end
end
