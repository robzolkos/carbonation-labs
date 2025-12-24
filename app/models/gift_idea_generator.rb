class GiftIdeaGenerator
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ImageDownloader

  attribute :recipient_description, :string

  validates :recipient_description, presence: true, length: { minimum: 10 }

  COLUMNS = [
    { name: "Ideas", color: "blue" },
    { name: "Considering", color: "yellow" },
    { name: "Purchased", color: "lime" }
  ].freeze

  SYSTEM_PROMPT = <<~PROMPT
    You are a thoughtful gift recommendation expert. Based on the description of the
    gift recipient (age, interests, occasion, budget), suggest 8-12 gift ideas.

    For each gift recommendation, provide:
    - Gift name/title
    - A compelling 2-3 sentence description of why this would be a great gift
    - Price range (e.g., "$25-50", "Under $100")
    - Where to buy it (general stores or categories, not specific links)

    Return JSON in this exact format:
    {
      "board_name": "Gift Ideas for [brief recipient description]",
      "items": [
        {
          "title": "Gift Name",
          "meta": "$25-50 | Amazon, Target",
          "description": "<p>Why this gift would be perfect for them...</p>"
        }
      ]
    }

    IMPORTANT:
    - Suggest practical, thoughtful gifts that match the recipient's interests
    - Include a variety of price points when budget isn't specified
    - Mix experience gifts with physical items
    - Order by how likely the recipient would appreciate them
    - Consider the occasion (birthday, holiday, thank you, etc.)
  PROMPT

  def generate_recommendations
    chat = RubyLLM.chat(
      model: "anthropic/claude-sonnet-4.5:online",
      provider: :openrouter,
      assume_model_exists: true
    )

    response = chat.ask(
      "#{SYSTEM_PROMPT}\n\nSuggest gifts for: #{recipient_description}"
    )

    Rails.logger.info("GiftIdeaGenerator LLM response: #{response.content}")
    result = parse_result(response.content)
    Rails.logger.info("GiftIdeaGenerator parsed result: #{result.inspect}")
    result
  rescue => e
    Rails.logger.error("GiftIdeaGenerator LLM error: #{e.message}")
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
        "board_name" => "Gift Ideas",
        "items" => [
          {
            "title" => "Gift Card",
            "meta" => "$25-100 | Various retailers",
            "description" => "<p>A versatile gift that lets them choose what they want.</p>",
            "image_url" => ""
          }
        ]
      }
    end
end
