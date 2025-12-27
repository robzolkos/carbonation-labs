require "csv"

class CsvToBoard
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :csv_data, :string
  attribute :board_name, :string
  attribute :title_column, :string
  attribute :description_column, :string

  validates :csv_data, presence: true
  validates :board_name, presence: true
  validates :title_column, presence: true

  def parsed_rows
    @parsed_rows ||= parse_csv
  end

  def headers
    parsed_rows.first&.headers || []
  end

  def cards
    parsed_rows.map do |row|
      title = row[title_column].to_s.strip
      next if title.blank?

      description = if description_column.present?
        row[description_column].to_s.strip
      else
        build_description_from_row(row)
      end

      { title: title, description: description }
    end.compact
  end

  private
    def parse_csv
      CSV.parse(csv_data, headers: true)
    rescue CSV::MalformedCSVError => e
      errors.add(:csv_data, "is not valid CSV: #{e.message}")
      []
    end

    def build_description_from_row(row)
      other_columns = row.headers - [title_column]
      return "" if other_columns.empty?

      html = "<ul>"
      other_columns.each do |col|
        value = row[col].to_s.strip
        next if value.blank?
        html += "<li><strong>#{col}:</strong> #{value}</li>"
      end
      html += "</ul>"
      html
    end
end
