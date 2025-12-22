class MovieQuizGenerator
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :topic, :string
  attribute :teams, :string
  attribute :question_count, :integer, default: 20

  validates :topic, presence: true, length: { minimum: 2 }
  validates :question_count, numericality: { greater_than: 0, less_than_or_equal_to: 50 }

  TEAM_COLORS = %w[blue lime pink violet aqua tan yellow purple].freeze

  def columns
    team_names.each_with_index.map do |team, index|
      { name: team, color: TEAM_COLORS[index % TEAM_COLORS.length] }
    end
  end

  def team_names
    return [] if teams.blank?

    teams.split(",").map(&:strip).reject(&:blank?)
  end

  SYSTEM_PROMPT = <<~PROMPT
    You are a movie trivia expert with deep knowledge of film history, behind-the-scenes facts,
    and obscure details. Based on the genre or decade the user provides, generate movie quiz questions.

    Each quiz card should have:
    - The movie title as the card title
    - A multiple choice question with fascinating trivia about that movie
    - Four options labeled A, B, C, D with one correct answer
    - The correct answer hidden in a details/summary element that must be clicked to reveal

    IMPORTANT: Create a WIDE VARIETY of question types. Include questions about:
    - Box office records and financial facts
    - Actors who almost got the role or turned it down
    - Behind-the-scenes mishaps and happy accidents
    - Real-life inspirations for characters or stories
    - Iconic lines that were improvised
    - How many times an actor did a stunt or scene
    - Awards won or notable snubs
    - Cameos and uncredited appearances
    - Original titles the movie almost had
    - Songs that were written for or featured in the film
    - Props, costumes, or sets that were reused or sold
    - Connections to other films (same director, shared universe, etc.)
    - Runtime, budget, or production timeline facts
    - Location filming trivia
    - Age of actors during filming
    - Sequels, prequels, or spin-offs
    - Critical reception vs audience reception
    - Cultural impact or controversy
    - Easter eggs or hidden details
    - Casting choices and audition stories

    Return JSON in this exact format:
    {
      "board_name": "Movie Quiz: [topic]",
      "items": [
        {
          "title": "The Shawshank Redemption",
          "description": "<p><strong>Which actor turned down the role of Andy Dufresne before Tim Robbins was cast?</strong></p><p>A) Kevin Costner<br>B) Tom Hanks<br>C) Nicolas Cage<br>D) Johnny Depp</p><details><summary>Reveal Answer</summary><p><strong>B) Tom Hanks</strong></p></details>"
        }
      ]
    }

    IMPORTANT:
    - Generate exactly the number of questions requested
    - Only use real movies that match the topic
    - Make sure all facts are accurate and verifiable
    - Every question should teach something interesting
    - Mix difficulty levels - some easy, some hard
    - The wrong answers should be plausible but clearly wrong
    - NO duplicate question types in a row - keep variety high
  PROMPT

  def generate_quiz
    chat = RubyLLM.chat(
      model: "anthropic/claude-sonnet-4.5:online",
      provider: :openrouter,
      assume_model_exists: true
    )

    response = chat.ask(
      "#{SYSTEM_PROMPT}\n\nGenerate #{question_count} movie quiz questions for: #{topic}"
    )

    Rails.logger.info("MovieQuizGenerator LLM response: #{response.content}")
    result = parse_result(response.content)
    Rails.logger.info("MovieQuizGenerator parsed result: #{result.inspect}")
    result
  rescue => e
    Rails.logger.error("MovieQuizGenerator LLM error: #{e.message}")
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
        "board_name" => "Movie Quiz",
        "items" => [
          {
            "title" => "The Godfather",
            "description" => "<p><strong>What year was this film released?</strong></p><p>A) 1970<br>B) 1972<br>C) 1974<br>D) 1976</p><details><summary>Reveal Answer</summary><p><strong>B) 1972</strong></p></details>"
          }
        ]
      }
    end
end
