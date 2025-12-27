require "test_helper"

class BoardMergerControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_board_merger_path
    assert_response :success
    assert_select "h1", "Board Merger"
  end

  test "should render form with board selects" do
    get new_board_merger_path
    assert_response :success
    assert_select "form[action=?]", board_merger_path
    assert_select "select[name=?]", "source_board_id"
    assert_select "select[name=?]", "target_board_id"
  end

  test "should reject empty source board" do
    post board_merger_path, params: { source_board_id: "", target_board_id: "123" }
    assert_redirected_to new_board_merger_path
    assert_equal "Please select a source board.", flash[:alert]
  end

  test "should reject empty target board" do
    post board_merger_path, params: { source_board_id: "123", target_board_id: "" }
    assert_redirected_to new_board_merger_path
    assert_equal "Please select a target board.", flash[:alert]
  end

  test "should reject same source and target" do
    post board_merger_path, params: { source_board_id: "123", target_board_id: "123" }
    assert_redirected_to new_board_merger_path
    assert_equal "Source and target boards must be different.", flash[:alert]
  end

  test "show redirects without session data" do
    get board_merger_path
    assert_redirected_to new_board_merger_path
  end
end
