class RestaurantBucketList
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ImageDownloader

  attribute :location_preferences, :string

  validates :location_preferences, presence: true, length: { minimum: 3 }

  COLUMNS = [
    { name: "Want to Try", color: "blue" },
    { name: "Been There", color: "yellow" },
    { name: "Favorites", color: "pink" }
  ].freeze

  SYSTEM_PROMPT = <<~PROMPT
    You are a restaurant and dining expert. Based on the city and cuisine preferences,
    recommend 8-12 must-try restaurants.

    For each restaurant recommendation, provide:
    - Restaurant name
    - Cuisine type
    - Price level ($, $$, $$$, or $$$$)
    - Neighborhood/area
    - A compelling 2-3 sentence description of the dining experience, signature
      dishes, and what makes it special

    Return JSON in this exact format:
    {
      "board_name": "Restaurants to Try in [City]",
      "items": [
        {
          "title": "Restaurant Name",
          "meta": "Italian | $$$ | Downtown",
          "description": "<p>Description of the restaurant and what makes it special...</p>"
        }
      ]
    }

    IMPORTANT:
    - Only recommend actual restaurants that exist
    - Include a mix of fine dining and casual spots
    - Mention signature dishes or must-try items
    - Consider ambiance and what makes each place unique
    - Order by overall recommendation strength
  PROMPT

  def generate_recommendations
    chat = RubyLLM.chat(
      model: "anthropic/claude-sonnet-4.5:online",
      provider: :openrouter,
      assume_model_exists: true
    )

    response = chat.ask(
      "#{SYSTEM_PROMPT}\n\nRecommend restaurants for: #{location_preferences}"
    )

    Rails.logger.info("RestaurantBucketList LLM response: #{response.content}")
    result = parse_result(response.content)
    Rails.logger.info("RestaurantBucketList parsed result: #{result.inspect}")
    result
  rescue => e
    Rails.logger.error("RestaurantBucketList LLM error: #{e.message}")
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
        "board_name" => "Restaurant Bucket List",
        "items" => [
          {
            "title" => "Local Favorite",
            "meta" => "Various | $$ | City Center",
            "description" => "<p>A beloved local spot worth checking out.</p>",
            "image_url" => ""
          }
        ]
      }
    end
end
