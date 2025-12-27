class PartyPrompts
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :game_type, :string
  attribute :category, :string
  attribute :difficulty, :string
  attribute :prompt_count, :integer, default: 30
  attribute :teams, :string

  validates :game_type, presence: true
  validates :category, presence: true
  validates :difficulty, presence: true
  validates :prompt_count, numericality: { greater_than: 0, less_than_or_equal_to: 50 }

  GAME_TYPES = [
    [ "Charades", "charades" ],
    [ "Pictionary", "pictionary" ],
    [ "Both", "both" ]
  ].freeze

  CATEGORIES = [
    [ "Movies & TV", "movies_tv" ],
    [ "Animals", "animals" ],
    [ "Actions & Activities", "actions" ],
    [ "Famous People", "famous_people" ],
    [ "Food & Drink", "food" ],
    [ "Sports", "sports" ],
    [ "Random Mix", "random" ]
  ].freeze

  DIFFICULTIES = [
    [ "Easy", "easy" ],
    [ "Medium", "medium" ],
    [ "Hard", "hard" ],
    [ "Mixed", "mixed" ]
  ].freeze

  TEAM_COLORS = %w[blue pink lime violet aqua tan].freeze

  def columns
    cols = [ { name: "Draw Pile", color: "gray" } ]

    team_names.each_with_index do |team, index|
      cols << { name: team, color: TEAM_COLORS[index % TEAM_COLORS.length] }
    end

    cols
  end

  def team_names
    return [ "Scored" ] if teams.blank?

    teams.split(",").map(&:strip).reject(&:blank?)
  end

  SYSTEM_PROMPT = <<~PROMPT
    You are a party game expert creating prompts for Charades and Pictionary.

    Generate prompts for:
    - Game type: {game_type}
    - Category: {category}
    - Difficulty: {difficulty}
    - Number of prompts: {prompt_count}

    For each prompt, provide:
    - A clear thing to act out or draw
    - Difficulty indicator (Easy 🟢, Medium 🟡, Hard 🔴)
    - A subtle hint (hidden until revealed)

    Guidelines by difficulty:
    - Easy: Common things, single words, obvious actions (e.g., "Eating pizza", "Dog")
    - Medium: Compound concepts, movie titles, specific people (e.g., "The Lion King", "Playing tennis")
    - Hard: Abstract concepts, obscure references, complex scenes (e.g., "Déjà vu", "The ending of Inception")

    For Charades: Focus on things that can be acted without props
    For Pictionary: Focus on things that can be drawn simply
    For Both: Mix it up, but indicate which game each prompt works best for

    Return JSON in this exact format:
    {
      "board_name": "{game_type}: {category} Prompts",
      "items": [
        {
          "title": "Making a sandwich",
          "description": "<p>🟢 Easy · Action</p><details><summary>Hint</summary><p>Think lunch, layers, bread</p></details>"
        },
        {
          "title": "Jurassic Park",
          "description": "<p>🟡 Medium · Movie</p><details><summary>Hint</summary><p>1993, dinosaurs, theme park gone wrong</p></details>"
        }
      ]
    }

    IMPORTANT:
    - Generate exactly the requested number of prompts
    - Mix difficulties if "Mixed" is selected
    - Make prompts fun and actable/drawable
    - Avoid anything inappropriate for all ages
    - Keep titles concise (what they'll act/draw)
    - Hints should help without giving it away
  PROMPT

  def generate_prompts
    chat = RubyLLM.chat(
      model: "anthropic/claude-sonnet-4.5",
      provider: :openrouter,
      assume_model_exists: true
    )

    prompt = SYSTEM_PROMPT
      .gsub("{game_type}", game_type_name)
      .gsub("{category}", category_name)
      .gsub("{difficulty}", difficulty_name)
      .gsub("{prompt_count}", prompt_count.to_s)

    response = chat.ask(prompt)

    Rails.logger.info("PartyPrompts LLM response: #{response.content}")
    result = parse_result(response.content)
    Rails.logger.info("PartyPrompts parsed result: #{result.inspect}")
    result
  rescue => e
    Rails.logger.error("PartyPrompts LLM error: #{e.message}")
    default_result
  end

  def game_type_name
    GAME_TYPES.find { |name, value| value == game_type }&.first || game_type
  end

  def category_name
    CATEGORIES.find { |name, value| value == category }&.first || category
  end

  def difficulty_name
    DIFFICULTIES.find { |name, value| value == difficulty }&.first || difficulty
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
        "board_name" => "#{game_type_name} Prompts",
        "items" => [
          {
            "title" => "Eating spaghetti",
            "description" => "<p>🟢 Easy · Action</p><details><summary>Hint</summary><p>Italian food, messy, twirl with fork</p></details>"
          }
        ]
      }
    end
end
