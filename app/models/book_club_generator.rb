class BookClubGenerator
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ImageDownloader

  attribute :favorite_books, :string

  validates :favorite_books, presence: true, length: { minimum: 3 }

  COLUMNS = [
    { name: "To Read", color: "blue" },
    { name: "Reading", color: "yellow" },
    { name: "Finished", color: "lime" }
  ].freeze

  SYSTEM_PROMPT = <<~PROMPT
    You are a book recommendation expert. Based on the books or genres the user enjoys,
    recommend 8-12 books they would likely love.

    For each book recommendation, provide:
    - Title (exact book title)
    - Author name
    - A compelling 2-3 sentence synopsis that captures the essence WITHOUT spoiling
      any plot twists or endings. Focus on themes, writing style, and why fans of
      the input books would enjoy it.
    - Page count (approximate)
    - Genre

    Return JSON in this exact format:
    {
      "board_name": "Books Like [main input book/genre]",
      "items": [
        {
          "title": "Book Title",
          "author": "Author Name",
          "meta": "Author Name | 320 pages | Fiction",
          "description": "<p>A compelling synopsis of the book...</p>"
        }
      ]
    }

    IMPORTANT:
    - Only recommend actual books that exist
    - Do NOT spoil any plot twists or endings
    - Include a mix of classics and contemporary works
    - Order by how likely the user would enjoy them (best matches first)
    - Include the author as a separate field for searching
  PROMPT

  def generate_recommendations
    chat = RubyLLM.chat(
      model: "anthropic/claude-sonnet-4.5:online",
      provider: :openrouter,
      assume_model_exists: true
    )

    response = chat.ask(
      "#{SYSTEM_PROMPT}\n\nRecommend books based on these favorites: #{favorite_books}"
    )

    Rails.logger.info("BookClubGenerator LLM response: #{response.content}")
    result = parse_result(response.content)
    Rails.logger.info("BookClubGenerator parsed result: #{result.inspect}")
    result
  rescue => e
    Rails.logger.error("BookClubGenerator LLM error: #{e.message}")
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
        "board_name" => "Book Recommendations",
        "items" => [
          {
            "title" => "The Great Gatsby",
            "meta" => "F. Scott Fitzgerald | 180 pages | Classic Fiction",
            "description" => "<p>A timeless tale of wealth, love, and the American Dream.</p>",
            "image_url" => ""
          }
        ]
      }
    end
end
