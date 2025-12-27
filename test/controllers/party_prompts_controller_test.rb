require "test_helper"

class PartyPromptsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_party_prompts_path
    assert_response :success
    assert_select "h1", "Party Prompts"
  end

  test "should render form" do
    get new_party_prompts_path
    assert_response :success
    assert_select "form[action=?]", party_prompts_path
    assert_select "select[name=?]", "party_prompts[game_type]"
    assert_select "select[name=?]", "party_prompts[category]"
    assert_select "select[name=?]", "party_prompts[difficulty]"
    assert_select "input[name=?]", "party_prompts[prompt_count]"
    assert_select "input[name=?]", "party_prompts[teams]"
  end

  test "should reject empty game_type" do
    post party_prompts_path, params: { party_prompts: { game_type: "", category: "animals", difficulty: "easy" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "should reject empty category" do
    post party_prompts_path, params: { party_prompts: { game_type: "charades", category: "", difficulty: "easy" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "should reject empty difficulty" do
    post party_prompts_path, params: { party_prompts: { game_type: "charades", category: "animals", difficulty: "" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "should reject invalid prompt_count" do
    post party_prompts_path, params: { party_prompts: { game_type: "charades", category: "animals", difficulty: "easy", prompt_count: 0 } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "should reject prompt_count over 50" do
    post party_prompts_path, params: { party_prompts: { game_type: "charades", category: "animals", difficulty: "easy", prompt_count: 100 } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "show redirects without session data" do
    get party_prompts_path
    assert_redirected_to new_party_prompts_path
  end
end
