require "test_helper"

class BoardCopierControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    # Will fail API call with test credentials, but controller rescues and shows empty state
    get new_board_copier_path
    assert_response :success
    assert_select "h1", "Board Copier"
  end

  test "should render form" do
    get new_board_copier_path
    assert_response :success
    assert_select "form[action=?]", board_copier_path
    assert_select "select[name=?]", "source_board_id"
    assert_select "input[name=?]", "new_board_name"
  end

  test "create without source_board_id redirects" do
    post board_copier_path, params: { new_board_name: "Test" }
    assert_redirected_to new_board_copier_path
    assert_equal "Please select a board to copy.", flash[:alert]
  end

  test "create without new_board_name redirects" do
    post board_copier_path, params: { source_board_id: "123" }
    assert_redirected_to new_board_copier_path
    assert_equal "Please enter a name for the new board.", flash[:alert]
  end

  test "show redirects without session data" do
    get board_copier_path
    assert_redirected_to new_board_copier_path
  end
end
