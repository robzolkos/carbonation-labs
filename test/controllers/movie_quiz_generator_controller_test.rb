require "test_helper"

class MovieQuizGeneratorControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_movie_quiz_generator_path
    assert_response :success
    assert_select "h1", "Movie Quiz Generator"
  end

  test "should render form" do
    get new_movie_quiz_generator_path
    assert_response :success
    assert_select "form[action=?]", movie_quiz_generator_path
    assert_select "input[name=?]", "movie_quiz_generator[topic]"
    assert_select "input[name=?]", "movie_quiz_generator[teams]"
    assert_select "input[name=?]", "movie_quiz_generator[question_count]"
  end

  test "should reject empty topic" do
    post movie_quiz_generator_path, params: { movie_quiz_generator: { topic: "" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "should reject short topic" do
    post movie_quiz_generator_path, params: { movie_quiz_generator: { topic: "a" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "show redirects without session data" do
    get movie_quiz_generator_path
    assert_redirected_to new_movie_quiz_generator_path
  end
end
