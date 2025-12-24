require "test_helper"

class BoardBootstrapTest < ActiveSupport::TestCase
  test "valid with description and board_name" do
    bootstrap = BoardBootstrap.new(
      description: "I want to manage blog posts from idea to published",
      board_name: "My Blog Board"
    )
    assert bootstrap.valid?
  end

  test "invalid without description" do
    bootstrap = BoardBootstrap.new(description: "", board_name: "My Board")
    assert_not bootstrap.valid?
    assert_includes bootstrap.errors[:description], "can't be blank"
  end

  test "invalid with short description" do
    bootstrap = BoardBootstrap.new(description: "short", board_name: "My Board")
    assert_not bootstrap.valid?
    assert_includes bootstrap.errors[:description], "is too short (minimum is 10 characters)"
  end

  test "invalid without board_name" do
    bootstrap = BoardBootstrap.new(
      description: "I want to manage blog posts from idea to published",
      board_name: ""
    )
    assert_not bootstrap.valid?
    assert_includes bootstrap.errors[:board_name], "can't be blank"
  end

  test "parse_columns extracts json from response" do
    bootstrap = BoardBootstrap.new(description: "test")

    # Test parsing via reflection
    columns = bootstrap.send(:parse_columns, '{"columns": [{"name": "Test", "color": "blue", "purpose": "Testing"}]}')
    assert_equal 1, columns.size
    assert_equal "Test", columns.first["name"]
  end

  test "parse_columns returns default on invalid json" do
    bootstrap = BoardBootstrap.new(description: "test")

    columns = bootstrap.send(:parse_columns, "invalid json")
    assert_equal 2, columns.size
    assert_equal "In Progress", columns.first["name"]
  end

  test "default_columns returns sensible defaults" do
    bootstrap = BoardBootstrap.new(description: "test")

    columns = bootstrap.send(:default_columns)
    assert_equal 2, columns.size
    assert columns.all? { |c| c.key?("name") && c.key?("color") && c.key?("purpose") }
  end
end
