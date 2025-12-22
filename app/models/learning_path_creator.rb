class LearningPathCreator
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ImageDownloader

  attribute :skill_to_learn, :string

  validates :skill_to_learn, presence: true, length: { minimum: 2 }

  COLUMNS = [
    { name: "Beginner", color: "blue" },
    { name: "Intermediate", color: "yellow" },
    { name: "Advanced", color: "purple" }
  ].freeze

  SYSTEM_PROMPT = <<~PROMPT
    You are an expert learning path designer. Based on the skill the user wants to learn,
    create a structured learning path with 10-15 resources progressing from beginner to advanced.

    For each learning resource, provide:
    - Resource name/title
    - Type (Course, Book, Tutorial, Video Series, Practice Project, etc.)
    - Estimated time to complete
    - Whether it's free or paid
    - A 2-3 sentence description of what you'll learn and why it's valuable at this stage
    - Skill level (Beginner, Intermediate, or Advanced)

    Return JSON in this exact format:
    {
      "board_name": "Learning [Skill Name]",
      "items": [
        {
          "title": "Resource Name",
          "meta": "Course | 10 hours | Free",
          "description": "<p>What you'll learn and why it's a great starting point...</p>",
          "level": "Beginner"
        }
      ]
    }

    IMPORTANT:
    - Progress logically from fundamentals to advanced topics
    - Include a mix of theory and hands-on practice
    - Recommend actual resources that exist (courses, books, tutorials)
    - Balance free and paid resources
    - Include practice projects to apply knowledge
    - Order by recommended learning sequence
  PROMPT

  def generate_recommendations
    chat = RubyLLM.chat(
      model: "anthropic/claude-sonnet-4.5:online",
      provider: :openrouter,
      assume_model_exists: true
    )

    response = chat.ask(
      "#{SYSTEM_PROMPT}\n\nCreate a learning path for: #{skill_to_learn}"
    )

    Rails.logger.info("LearningPathCreator LLM response: #{response.content}")
    result = parse_result(response.content)
    Rails.logger.info("LearningPathCreator parsed result: #{result.inspect}")
    result
  rescue => e
    Rails.logger.error("LearningPathCreator LLM error: #{e.message}")
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
        "board_name" => "Learning Path",
        "items" => [
          {
            "title" => "Getting Started",
            "meta" => "Tutorial | 2 hours | Free",
            "description" => "<p>A great first step to get you started on your learning journey.</p>",
            "image_url" => "",
            "level" => "Beginner"
          }
        ]
      }
    end
end
