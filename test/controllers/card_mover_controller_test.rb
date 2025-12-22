require "test_helper"

class CardMoverControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_card_mover_path
    assert_response :success
    assert_select "h1", "Card Mover"
  end

  test "should render form with board list and target select" do
    get new_card_mover_path
    assert_response :success
    assert_select "form[action=?]", card_mover_path
    assert_select "select[name=?]", "target_board_id"
  end

  test "should reject empty source boards" do
    post card_mover_path, params: { source_board_ids: [], target_board_id: "123" }
    assert_redirected_to new_card_mover_path
    assert_equal "Please select at least one source board.", flash[:alert]
  end

  test "should reject empty target board" do
    post card_mover_path, params: { source_board_ids: [ "123" ], target_board_id: "" }
    assert_redirected_to new_card_mover_path
    assert_equal "Please select a target board.", flash[:alert]
  end

  test "should reject target in source list" do
    post card_mover_path, params: { source_board_ids: [ "123", "456" ], target_board_id: "123" }
    assert_redirected_to new_card_mover_path
    assert_equal "Target board cannot also be a source board.", flash[:alert]
  end

  test "show redirects without session data" do
    get card_mover_path
    assert_redirected_to new_card_mover_path
  end
end
