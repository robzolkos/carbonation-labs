require "test_helper"

class CsvToBoardControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_csv_to_board_path
    assert_response :success
    assert_select "h1", "CSV to Board"
  end

  test "should render form" do
    get new_csv_to_board_path
    assert_response :success
    assert_select "form[action=?]", csv_to_board_path
    assert_select "textarea[name=?]", "csv_to_board[csv_data]"
    assert_select "input[name=?]", "csv_to_board[board_name]"
    assert_select "input[name=?]", "csv_to_board[title_column]"
  end

  test "should reject empty csv_data" do
    post csv_to_board_path, params: { csv_to_board: { csv_data: "", board_name: "Test", title_column: "name" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "should reject missing board_name" do
    post csv_to_board_path, params: { csv_to_board: { csv_data: "name\nJohn", board_name: "", title_column: "name" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "show redirects without session data" do
    get csv_to_board_path
    assert_redirected_to new_csv_to_board_path
  end
end
