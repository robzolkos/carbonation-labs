class MovieRecommender
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ImageDownloader

  attribute :favorite_movies, :string

  validates :favorite_movies, presence: true, length: { minimum: 3 }

  COLUMNS = [
    { name: "To Watch", color: "blue" },
    { name: "Watched", color: "lime" },
    { name: "Favorites", color: "pink" }
  ].freeze

  SYSTEM_PROMPT = <<~PROMPT
    You are a movie recommendation expert. Based on the movies the user enjoys,
    recommend 8-12 similar films they would likely love.

    For each movie recommendation, provide:
    - Title (exact movie title)
    - Year released
    - Director name
    - Main actors (2-3 names)
    - A compelling 2-3 sentence description that captures the essence and appeal
      WITHOUT spoiling any plot points. Focus on tone, themes, and why fans of
      the input movies would enjoy it.

    Return JSON in this exact format:
    {
      "board_name": "Movies Like [main input movie]",
      "items": [
        {
          "title": "Movie Title",
          "year": "2023",
          "meta": "2023 | Director Name | Actor One, Actor Two",
          "description": "<p>A compelling description of why this movie is great...</p>"
        }
      ]
    }

    IMPORTANT:
    - Only recommend actual movies that exist
    - Do NOT spoil any plot twists or endings
    - Include a mix of well-known and hidden gems
    - Order by how likely the user would enjoy them (best matches first)
    - Keep descriptions engaging but spoiler-free
    - Include the year as a separate field for searching
  PROMPT

  def generate_recommendations
    chat = RubyLLM.chat(
      model: "anthropic/claude-sonnet-4.5:online",
      provider: :openrouter,
      assume_model_exists: true
    )

    response = chat.ask(
      "#{SYSTEM_PROMPT}\n\nRecommend movies based on these favorites: #{favorite_movies}"
    )

    Rails.logger.info("MovieRecommender LLM response: #{response.content}")
    result = parse_result(response.content)
    Rails.logger.info("MovieRecommender parsed result: #{result.inspect}")
    result
  rescue => e
    Rails.logger.error("MovieRecommender LLM error: #{e.message}")
    default_result
  end

  private
    def parse_result(content)
      json_match = content.match(/\{[\s\S]*\}/)
      return default_result unless json_match

      data = JSON.parse(json_match[0])
      return default_result unless data["board_name"] && data["items"]

      data
    rescue JSON::ParserError
      default_result
    end

    def default_result
      {
        "board_name" => "Movie Recommendations",
        "items" => [
          {
            "title" => "The Shawshank Redemption",
            "meta" => "1994 | Frank Darabont | Tim Robbins, Morgan Freeman",
            "description" => "<p>A timeless story of hope and friendship.</p>",
            "image_url" => ""
          }
        ]
      }
    end
end
