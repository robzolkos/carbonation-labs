require "test_helper"

class LabsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_path
    assert_response :success
    assert_select "h1", "Experiments"
  end

  test "should list all labs" do
    get root_path
    assert_response :success
    assert_select ".lab-card", count: LabsController::LABS.size
  end

  test "should have link to board bootstrap" do
    get root_path
    assert_response :success
    assert_select "a[href=?]", new_board_bootstrap_path
  end
end
