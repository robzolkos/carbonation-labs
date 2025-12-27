# frozen_string_literal: true

require "open-uri"
require "tempfile"
require "net/http"
require "json"
require "mini_magick"

module ImageDownloader
  extend ActiveSupport::Concern

  WIKIPEDIA_API = "https://en.wikipedia.org/w/api.php"
  OPEN_LIBRARY_SEARCH = "https://openlibrary.org/search.json"
  OPEN_LIBRARY_COVERS = "https://covers.openlibrary.org/b/id"
  TMDB_API = "https://api.themoviedb.org/3"
  TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p/w500"

  CARD_WIDTH = 400
  CARD_HEIGHT = 100

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

  # Fetch movie poster - tries TMDB (if API key set), then Wikipedia
  def fetch_movie_image(title, year: nil)
    # Try TMDB first if API key is configured
    if ENV["TMDB_API_KEY"].present?
      image_path = fetch_tmdb_poster(title, year)
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

  # Create a card image: dominant color background with poster on the right, title on bottom left
  # Returns path to the composite image
  def create_card_image(poster_path, title: nil)
    return nil if poster_path.blank? || !File.exist?(poster_path)

    # Get dominant color from the poster
    dominant_color = extract_dominant_color(poster_path)
    text_color = contrasting_color(dominant_color)

    # Create output file
    output = Tempfile.new([ "card_image", ".jpg" ])

    # Calculate text area width (leave space for poster ~67px wide at 100px height)
    text_area_width = CARD_WIDTH - 80

    # Build ImageMagick command
    cmd = [
      "magick",
      "-size", "#{CARD_WIDTH}x#{CARD_HEIGHT}",
      "xc:#{dominant_color}",
      "(", poster_path, "-resize", "x#{CARD_HEIGHT}", ")",
      "-gravity", "East",
      "-composite"
    ]

    # Add title text if provided
    if title.present?
      display_title = format_title_for_card(title.upcase)

      cmd += [
        "-gravity", "SouthWest",
        "-fill", text_color,
        "-font", "Adwaita-Sans-Bold",
        "-pointsize", "12",
        "-annotate", "+15+10", display_title
      ]
    end

    cmd << output.path

    result = system(*cmd)

    if result && File.exist?(output.path) && File.size(output.path) > 0
      Rails.logger.info("Created card image with dominant color #{dominant_color}, text color #{text_color}")
      output.path
    else
      Rails.logger.error("Failed to create card image: magick command failed")
      poster_path
    end
  rescue StandardError => e
    Rails.logger.error("Failed to create card image: #{e.message}")
    poster_path # Fall back to original poster
  end

  private
    # TMDB API for movie posters (requires free API key from themoviedb.org)
    def fetch_tmdb_poster(title, year = nil)
      uri = URI("#{TMDB_API}/search/movie")
      params = { query: title }
      params[:year] = year if year.present?
      uri.query = URI.encode_www_form(params)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{ENV['TMDB_API_KEY']}"
      request["Accept"] = "application/json"

      response = http.request(request)
      data = JSON.parse(response.body)
      results = data["results"]

      return nil if results.nil? || results.empty?

      poster_path = results.first["poster_path"]
      return nil if poster_path.nil?

      poster_url = "#{TMDB_IMAGE_BASE}#{poster_path}"
      Rails.logger.info("TMDB found poster for '#{title}': #{poster_url}")
      download_image(poster_url)
    rescue StandardError => e
      Rails.logger.error("TMDB fetch failed for '#{title}': #{e.message}")
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

    # Format title for card - split long titles into two balanced lines
    def format_title_for_card(title)
      max_line_length = 40

      # If it fits on one line, use as-is
      return title if title.length <= max_line_length

      # Find a space near the middle to split on
      words = title.split(" ")
      mid_point = title.length / 2

      # Build first line until we pass the midpoint
      line1 = ""
      line2_words = []

      words.each do |word|
        test_line = line1.empty? ? word : "#{line1} #{word}"
        if test_line.length <= mid_point + 5 && line2_words.empty?
          line1 = test_line
        else
          line2_words << word
        end
      end

      line2 = line2_words.join(" ")

      # Truncate line2 if still too long
      if line2.length > max_line_length
        line2 = line2[0, max_line_length - 3] + "..."
      end

      "#{line1}\n#{line2}"
    end

    # Calculate a contrasting color (white or black) based on luminance
    def contrasting_color(hex_color)
      # Parse hex color
      hex = hex_color.delete("#")
      r = hex[0..1].to_i(16)
      g = hex[2..3].to_i(16)
      b = hex[4..5].to_i(16)

      # Calculate relative luminance (per WCAG 2.0)
      luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255

      # Return white for dark backgrounds, black for light backgrounds
      luminance < 0.5 ? "#FFFFFF" : "#000000"
    end

    # Extract the dominant color from an image using ImageMagick histogram
    def extract_dominant_color(image_path)
      # Use MiniMagick to safely execute ImageMagick commands
      image = MiniMagick::Image.open(image_path)
      image.resize "50x50"
      image.colors 1

      # Get histogram output
      result = image.run_command("magick", image.path, "-format", "%c", "histogram:info:-")

      # Parse hex color from histogram output like: "1650: (60,76,92) #3C4D5D srgb(...)"
      if result =~ /#([0-9A-Fa-f]{6})/
        color = "##{$1}"
        Rails.logger.info("Extracted dominant color: #{color}")
        color
      else
        "#333333" # Default dark gray if extraction fails
      end
    rescue StandardError => e
      Rails.logger.error("Failed to extract dominant color: #{e.message}")
      "#333333"
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
