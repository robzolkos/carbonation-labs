require "test_helper"

class LearningPathCreatorControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_learning_path_creator_path
    assert_response :success
    assert_select "h1", "Learning Path Creator"
  end

  test "should render form" do
    get new_learning_path_creator_path
    assert_response :success
    assert_select "form[action=?]", learning_path_creator_path
    assert_select "textarea[name=?]", "learning_path_creator[skill_to_learn]"
  end

  test "should reject empty skill_to_learn" do
    post learning_path_creator_path, params: { learning_path_creator: { skill_to_learn: "" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "should reject short skill_to_learn" do
    post learning_path_creator_path, params: { learning_path_creator: { skill_to_learn: "a" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "show redirects without session data" do
    get learning_path_creator_path
    assert_redirected_to new_learning_path_creator_path
  end
end
