class EmailToTasks
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email_content, :string
  attribute :board_name, :string

  validates :email_content, presence: true, length: { minimum: 20 }

  COLUMNS = [
    { name: "To Do", color: "gray" },
    { name: "In Progress", color: "yellow" },
    { name: "Done", color: "lime" }
  ].freeze

  SYSTEM_PROMPT = <<~PROMPT
    You are an expert at extracting action items from emails and conversations.

    Analyze the following email/message and extract ALL actionable tasks.

    For each task:
    - Create a clear, actionable title (starts with a verb)
    - Include relevant context and details from the email
    - Note any deadlines or timeframes mentioned
    - Include who requested it or who's involved
    - Add any dependencies or prerequisites

    Be thorough - look for:
    - Explicit requests ("Can you...", "Please...", "We need...")
    - Implicit tasks (questions that need answers, decisions needed)
    - Follow-ups mentioned ("Let's circle back", "We should discuss")
    - Deadlines and dates
    - Commitments made ("I'll send you...", "We'll prepare...")

    Return JSON in this exact format:
    {
      "board_name": "Tasks from: [Brief subject/topic]",
      "items": [
        {
          "title": "Send proposal to client by Friday",
          "description": "<p><strong>Context:</strong> From email discussion about Q1 project...</p><p><strong>Deadline:</strong> Friday</p><p><strong>Requested by:</strong> Sarah</p><p><strong>Details:</strong> Include pricing for both options mentioned...</p>"
        }
      ]
    }

    IMPORTANT:
    - Extract EVERY action item, even small ones
    - Make titles specific and actionable (not vague)
    - Preserve important details like names, dates, and specifics
    - If no clear tasks exist, create a single card noting "No action items found"
    - Group related tasks if they're clearly part of the same deliverable
  PROMPT

  def extract_tasks
    chat = RubyLLM.chat(
      model: "anthropic/claude-sonnet-4.5",
      provider: :openrouter,
      assume_model_exists: true
    )

    response = chat.ask("#{SYSTEM_PROMPT}\n\nEmail content:\n#{email_content}")

    Rails.logger.info("EmailToTasks LLM response: #{response.content}")
    result = parse_result(response.content)
    Rails.logger.info("EmailToTasks parsed result: #{result.inspect}")
    result
  rescue => e
    Rails.logger.error("EmailToTasks LLM error: #{e.message}")
    default_result
  end

  def effective_board_name
    board_name.present? ? board_name : "Tasks from Email"
  end

  private
    def parse_result(content)
      json_match = content.match(/\{[\s\S]*\}/)
      return default_result unless json_match

      data = JSON.parse(json_match[0])
      return default_result unless data["board_name"] && data["items"]

      # Use custom board name if provided
      data["board_name"] = effective_board_name if board_name.present?

      data
    rescue JSON::ParserError
      default_result
    end

    def default_result
      {
        "board_name" => effective_board_name,
        "items" => [
          {
            "title" => "Review email for action items",
            "description" => "<p>The email content couldn't be parsed automatically. Review manually.</p>"
          }
        ]
      }
    end
end
