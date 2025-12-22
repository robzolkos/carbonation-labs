require "test_helper"

class BoardBootstrapControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_board_bootstrap_path
    assert_response :success
    assert_select "h1", "Board Bootstrap"
  end

  test "should render form" do
    get new_board_bootstrap_path
    assert_response :success
    assert_select "form[action=?]", board_bootstrap_path
    assert_select "textarea[name=?]", "board_bootstrap[description]"
  end

  test "should reject empty description" do
    post board_bootstrap_path, params: { board_bootstrap: { description: "" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "should reject short description" do
    post board_bootstrap_path, params: { board_bootstrap: { description: "short" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end
end
