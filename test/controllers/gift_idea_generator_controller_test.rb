require "test_helper"

class GiftIdeaGeneratorControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_gift_idea_generator_path
    assert_response :success
    assert_select "h1", "Gift Idea Generator"
  end

  test "should render form" do
    get new_gift_idea_generator_path
    assert_response :success
    assert_select "form[action=?]", gift_idea_generator_path
    assert_select "textarea[name=?]", "gift_idea_generator[recipient_description]"
  end

  test "should reject empty recipient_description" do
    post gift_idea_generator_path, params: { gift_idea_generator: { recipient_description: "" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "should reject short recipient_description" do
    post gift_idea_generator_path, params: { gift_idea_generator: { recipient_description: "short" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "show redirects without session data" do
    get gift_idea_generator_path
    assert_redirected_to new_gift_idea_generator_path
  end
end
