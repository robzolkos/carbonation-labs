class BoardBootstrap
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :description, :string

  validates :description, presence: true, length: { minimum: 10 }

  SYSTEM_PROMPT = <<~PROMPT
    You are an expert at analyzing workflows and suggesting kanban board structures.

    Fizzy is a kanban board with default columns:
    - Not Now (leftmost)
    - Maybe?
    - Done (rightmost)

    Users can add custom columns between "Maybe?" and "Done" to represent workflow stages.

    IMPORTANT: Columns represent STAGES that a card moves through, not categories of work.
    Each card (task/item) should be able to flow left-to-right through all columns.
    Think about the states of readiness or progress, not types of activities.

    Example for trip planning - cards might be "Flights", "Hotel", "Tours":
    - Good columns: Researching → Deciding → Booked (stages each card moves through)
    - Bad columns: Research, Booking, Packing (categories that don't apply to all cards)

    Suggest 2-5 additional columns that represent stages any card would move through.

    Column names should be succinct - one word preferred, two words maximum.

    Respond ONLY with valid JSON in this exact format:
    {
      "columns": [
        {"name": "Column Name", "color": "blue", "purpose": "Brief explanation of this stage"}
      ]
    }

    Available colors: blue, gray, tan, yellow, lime, aqua, violet, purple, pink

    Choose colors that make visual sense for the workflow progression.
  PROMPT

  def generate_columns
    chat = RubyLLM.chat(model: "anthropic/claude-sonnet-4.5", provider: :openrouter)

    response = chat.ask(
      "#{SYSTEM_PROMPT}\n\nUser wants to manage: #{description}"
    )

    Rails.logger.info("BoardBootstrap LLM response: #{response.content}")
    columns = parse_columns(response.content)
    Rails.logger.info("BoardBootstrap parsed columns: #{columns.inspect}")
    columns
  rescue => e
    Rails.logger.error("BoardBootstrap LLM error: #{e.message}")
    default_columns
  end

  private

  def parse_columns(content)
    json_match = content.match(/\{[\s\S]*\}/)
    return default_columns unless json_match

    data = JSON.parse(json_match[0])
    data["columns"] || default_columns
  rescue JSON::ParserError
    default_columns
  end

  def default_columns
    [
      { "name" => "In Progress", "color" => "blue", "purpose" => "Work currently being done" },
      { "name" => "Review", "color" => "yellow", "purpose" => "Ready for review" }
    ]
  end
end
