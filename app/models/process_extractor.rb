class ProcessExtractor
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :process_description, :string

  validates :process_description, presence: true, length: { minimum: 10 }

  SYSTEM_PROMPT = <<~PROMPT
    You are a research assistant that finds official documentation about processes.

    Research the following process and identify all required steps from official/authoritative sources.

    Fizzy is a kanban board that ALREADY HAS these default columns (do NOT include them in your response):
    - Not Now (leftmost)
    - Maybe?
    - Done (rightmost)

    You may suggest 0-3 ADDITIONAL columns to insert between "Maybe?" and "Done" to represent workflow stages.
    Most processes work fine with just the defaults, so only add columns if truly needed.

    IMPORTANT FOR COLUMNS: Columns represent STAGES that a card moves through, not categories of work.
    Each card (task/item) should be able to flow left-to-right through all columns.
    Think about states of readiness or progress, not types of activities.
    NEVER include "Not Now", "Maybe?", or "Done" - these already exist!

    Example for DMV process - cards might be "Get documents", "Take test", "Pay fees":
    - Good columns: Preparing → Scheduled (stages each card moves through)
    - Bad columns: Documents, Tests, Payments (categories that don't apply to all cards)
    - Wrong: Not Now, Maybe?, Done (these already exist - never include them!)

    For each step/card, provide:
    - A short title (1-5 words)
    - A detailed HTML-formatted description with requirements, sub-steps, and reference links

    Return JSON in this exact format:
    {
      "board_name": "Suggested board name",
      "columns": [
        {"name": "Column Name", "color": "blue", "purpose": "Why this column"}
      ],
      "cards": [
        {
          "title": "Step title",
          "description": "<p>What this step involves and requirements.</p><h4>Sub-steps</h4><ul><li>First thing to do</li><li>Second thing</li></ul><h4>References</h4><ul><li><a href='https://official-site.gov/page'>Official documentation</a></li></ul>"
        }
      ]
    }

    Available colors: blue, gray, tan, yellow, lime, aqua, violet, purple, pink

    IMPORTANT:
    - Use ONLY official/government sources when available
    - Format descriptions as HTML with proper tags (p, h4, ul, li, a, strong)
    - Include clickable links to source documentation
    - Order cards by the logical sequence of the process
    - Keep column suggestions minimal (0-3) - default columns handle most workflows
    - Each card represents one major step in the process
  PROMPT

  def research_process
    chat = RubyLLM.chat(
      model: "anthropic/claude-sonnet-4.5:online",
      provider: :openrouter,
      assume_model_exists: true
    )

    response = chat.ask(
      "#{SYSTEM_PROMPT}\n\nResearch this process: #{process_description}"
    )

    Rails.logger.info("ProcessExtractor LLM response: #{response.content}")
    result = parse_result(response.content)
    Rails.logger.info("ProcessExtractor parsed result: #{result.inspect}")
    result
  rescue => e
    Rails.logger.error("ProcessExtractor LLM error: #{e.message}")
    default_result
  end

  private

    def parse_result(content)
      json_match = content.match(/\{[\s\S]*\}/)
      return default_result unless json_match

      data = JSON.parse(json_match[0])
      return default_result unless data["board_name"] && data["cards"]

      data
    rescue JSON::ParserError
      default_result
    end

    def default_result
      {
        "board_name" => "My Process",
        "columns" => [],
        "cards" => [
          { "title" => "Step 1", "description" => "First step in the process" },
          { "title" => "Step 2", "description" => "Second step in the process" }
        ]
      }
    end
end
