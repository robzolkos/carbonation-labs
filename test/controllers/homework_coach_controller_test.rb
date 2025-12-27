require "test_helper"

class HomeworkCoachControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_homework_coach_path
    assert_response :success
    assert_select "h1", "Homework Coach"
  end

  test "should render form with grade dropdown" do
    get new_homework_coach_path
    assert_response :success
    assert_select "form[action=?]", homework_coach_path
    assert_select "select[name=?]", "homework_coach[grade_level]"
    assert_select "textarea[name=?]", "homework_coach[struggle]"
  end

  test "should reject empty struggle" do
    post homework_coach_path, params: { homework_coach: { struggle: "", grade_level: "middle_school" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "should reject missing grade level" do
    post homework_coach_path, params: { homework_coach: { struggle: "I don't understand fractions", grade_level: "" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "show redirects without session data" do
    get homework_coach_path
    assert_redirected_to new_homework_coach_path
  end
end
