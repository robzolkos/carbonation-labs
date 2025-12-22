class TripPlanner
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :destination, :string
  attribute :trip_length, :string
  attribute :interests, :string

  validates :destination, presence: true
  validates :trip_length, presence: true

  TRIP_LENGTHS = [
    [ "Weekend (2-3 days)", "weekend" ],
    [ "Short trip (4-5 days)", "short" ],
    [ "One week", "week" ],
    [ "Two weeks", "two_weeks" ],
    [ "Extended (3+ weeks)", "extended" ]
  ].freeze

  COLUMNS = [
    { name: "To Plan", color: "gray" },
    { name: "Booked", color: "blue" },
    { name: "Done", color: "lime" }
  ].freeze

  SYSTEM_PROMPT = <<~PROMPT
    You are an experienced travel planner who creates detailed, practical trip itineraries.

    Create a day-by-day travel plan for:
    - Destination: {destination}
    - Trip length: {trip_length}
    - Interests/preferences: {interests}

    For each day, create a card with:
    - A descriptive title (e.g., "Day 1: Arrival & Old Town Exploration")
    - Morning, afternoon, and evening activities
    - Specific places to visit with brief descriptions
    - Restaurant/food recommendations
    - Practical tips (best times to visit, tickets to book ahead, etc.)
    - Estimated costs where relevant

    Also include cards for:
    - Pre-trip preparation (visas, packing, bookings)
    - Transportation tips (getting around, airport transfers)
    - Local tips (customs, tipping, phrases to know)

    Return JSON in this exact format:
    {
      "board_name": "Trip to [Destination]: [Length] Itinerary",
      "items": [
        {
          "title": "Pre-Trip: Things to Book Ahead",
          "description": "<p><strong>Before you go:</strong></p><ul><li>Book X</li><li>Reserve Y</li></ul><p><strong>Pro tip:</strong> Helpful advice...</p>"
        },
        {
          "title": "Day 1: Arrival & First Impressions",
          "description": "<p><strong>Morning:</strong> Activity details...</p><p><strong>Afternoon:</strong> Activity details...</p><p><strong>Evening:</strong> Dinner recommendation...</p><p><strong>Tips:</strong> Practical advice...</p>"
        }
      ]
    }

    IMPORTANT:
    - Be specific with place names and locations
    - Include a mix of popular attractions and local gems
    - Consider realistic timing and travel between locations
    - Tailor recommendations to the stated interests
    - Include backup options for weather-dependent activities
  PROMPT

  def generate_itinerary
    chat = RubyLLM.chat(
      model: "anthropic/claude-sonnet-4.5:online",
      provider: :openrouter,
      assume_model_exists: true
    )

    interests_text = interests.present? ? interests : "general sightseeing and local culture"

    prompt = SYSTEM_PROMPT
      .gsub("{destination}", destination)
      .gsub("{trip_length}", trip_length_name)
      .gsub("{interests}", interests_text)

    response = chat.ask(prompt)

    Rails.logger.info("TripPlanner LLM response: #{response.content}")
    result = parse_result(response.content)
    Rails.logger.info("TripPlanner parsed result: #{result.inspect}")
    result
  rescue => e
    Rails.logger.error("TripPlanner LLM error: #{e.message}")
    default_result
  end

  def trip_length_name
    TRIP_LENGTHS.find { |name, value| value == trip_length }&.first || trip_length
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
        "board_name" => "Trip to #{destination}",
        "items" => [
          {
            "title" => "Day 1: Explore",
            "description" => "<p>Start exploring your destination!</p>"
          }
        ]
      }
    end
end
