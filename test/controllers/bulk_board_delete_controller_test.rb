require "test_helper"

class BulkBoardDeleteControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    # Will fail API call with test credentials, but controller rescues and shows empty state
    get bulk_board_delete_path
    assert_response :success
    assert_select "h1", "Bulk Board Delete"
  end

  test "destroy without board_ids redirects" do
    delete bulk_board_delete_path
    assert_redirected_to bulk_board_delete_path
    assert_equal "No boards selected.", flash[:alert]
  end
end
