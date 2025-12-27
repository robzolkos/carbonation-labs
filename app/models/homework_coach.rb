class HomeworkCoach
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :struggle, :string
  attribute :grade_level, :string

  validates :struggle, presence: true, length: { minimum: 5 }
  validates :grade_level, presence: true

  GRADE_LEVELS = [
    [ "Elementary (K-2)", "elementary_k2" ],
    [ "Elementary (3-5)", "elementary_35" ],
    [ "Middle School (6-8)", "middle_school" ],
    [ "High School (9-10)", "high_school_910" ],
    [ "High School (11-12)", "high_school_1112" ],
    [ "College Freshman/Sophomore", "college_underclass" ],
    [ "College Junior/Senior", "college_upperclass" ],
    [ "Graduate School", "graduate" ]
  ].freeze

  COLUMNS = [
    { name: "Start Here", color: "blue" },
    { name: "Working On", color: "yellow" },
    { name: "Got It!", color: "lime" }
  ].freeze

  SYSTEM_PROMPT = <<~PROMPT
    You are a patient, encouraging homework coach who specializes in helping students
    who are struggling. Your goal is to break down complex topics into manageable pieces
    and rebuild understanding from the ground up.

    The student is at grade level: {grade_level}
    They are struggling with: {struggle}

    Create 8-12 learning cards that will help them understand this topic. Each card should
    build on the previous one, starting from the absolute basics.

    For each card, provide:
    - A clear, encouraging title
    - An explanation that:
      * Starts with what they probably already know
      * Uses simple analogies and real-world examples
      * Includes a mental model or visualization when helpful
      * Breaks complex ideas into smaller steps
      * Ends with a quick check or practice thought
    - 2-3 helpful external links (Khan Academy, YouTube educational channels,
      interactive tools, practice sites, etc.)

    IMPORTANT GUIDELINES:
    - Adjust language complexity to match the grade level
    - Never make the student feel bad for not understanding
    - Use phrases like "Think of it like..." and "Imagine..."
    - Include encouraging notes like "This is where it clicks for most people!"
    - For math/science: include worked examples with clear steps
    - For reading/writing: include templates and frameworks
    - For languages: include memory tricks and patterns
    - Make each card feel achievable - small wins build confidence

    Return JSON in this exact format:
    {
      "board_name": "Understanding [Topic]: A Step-by-Step Guide",
      "items": [
        {
          "title": "Let's Start With What You Know",
          "description": "<p>Encouraging explanation with analogies and examples...</p><p><strong>Think of it like:</strong> A relatable analogy...</p><p><strong>Quick check:</strong> A simple question to verify understanding...</p>",
          "links": [
            {"text": "Khan Academy: Topic Basics", "url": "https://khanacademy.org/..."},
            {"text": "Visual Explanation (YouTube)", "url": "https://youtube.com/..."}
          ]
        }
      ]
    }

    IMPORTANT:
    - Only include real, working URLs to legitimate educational resources
    - Prefer well-known sites: Khan Academy, YouTube Edu, Coursera, edX, Quizlet, etc.
    - Order cards from most basic to more advanced
    - The first card should be "You're in the right place" - validating and orienting
    - The last card should be "Putting it all together" - synthesis and next steps
  PROMPT

  def generate_help
    chat = RubyLLM.chat(
      model: "anthropic/claude-sonnet-4.5:online",
      provider: :openrouter,
      assume_model_exists: true
    )

    prompt = SYSTEM_PROMPT
      .gsub("{grade_level}", grade_level_name)
      .gsub("{struggle}", struggle)

    response = chat.ask(prompt)

    Rails.logger.info("HomeworkCoach LLM response: #{response.content}")
    result = parse_result(response.content)
    Rails.logger.info("HomeworkCoach parsed result: #{result.inspect}")
    result
  rescue => e
    Rails.logger.error("HomeworkCoach LLM error: #{e.message}")
    default_result
  end

  def grade_level_name
    GRADE_LEVELS.find { |name, value| value == grade_level }&.first || grade_level
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
        "board_name" => "Understanding Your Topic",
        "items" => [
          {
            "title" => "Let's Start Here",
            "description" => "<p>We're going to break this down step by step. You've got this!</p>",
            "links" => [
              { "text" => "Khan Academy", "url" => "https://khanacademy.org" }
            ]
          }
        ]
      }
    end
end
