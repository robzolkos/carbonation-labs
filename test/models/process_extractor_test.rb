require "test_helper"

class ProcessExtractorTest < ActiveSupport::TestCase
  test "valid with process_description" do
    extractor = ProcessExtractor.new(process_description: "Getting a California Driver's License")
    assert extractor.valid?
  end

  test "invalid without process_description" do
    extractor = ProcessExtractor.new(process_description: "")
    assert_not extractor.valid?
    assert_includes extractor.errors[:process_description], "can't be blank"
  end

  test "invalid with short process_description" do
    extractor = ProcessExtractor.new(process_description: "short")
    assert_not extractor.valid?
    assert_includes extractor.errors[:process_description], "is too short (minimum is 10 characters)"
  end

  test "parse_result extracts json from response" do
    extractor = ProcessExtractor.new(process_description: "test")

    result = extractor.send(:parse_result, '{"board_name": "Test Board", "columns": [], "cards": [{"title": "Step 1", "description": "First step"}]}')
    assert_equal "Test Board", result["board_name"]
    assert_equal 1, result["cards"].size
    assert_equal "Step 1", result["cards"].first["title"]
  end

  test "parse_result handles json with surrounding text" do
    extractor = ProcessExtractor.new(process_description: "test")

    response = 'Here is the JSON: {"board_name": "Test", "columns": [], "cards": [{"title": "A", "description": "B"}]} Hope that helps!'
    result = extractor.send(:parse_result, response)
    assert_equal "Test", result["board_name"]
  end

  test "parse_result returns default on invalid json" do
    extractor = ProcessExtractor.new(process_description: "test")

    result = extractor.send(:parse_result, "invalid json")
    assert_equal "My Process", result["board_name"]
    assert_equal 2, result["cards"].size
  end

  test "parse_result returns default when missing required keys" do
    extractor = ProcessExtractor.new(process_description: "test")

    result = extractor.send(:parse_result, '{"columns": []}')
    assert_equal "My Process", result["board_name"]
  end

  test "default_result returns sensible defaults" do
    extractor = ProcessExtractor.new(process_description: "test")

    result = extractor.send(:default_result)
    assert_equal "My Process", result["board_name"]
    assert_equal [], result["columns"]
    assert_equal 2, result["cards"].size
    assert result["cards"].all? { |c| c.key?("title") && c.key?("description") }
  end
end
