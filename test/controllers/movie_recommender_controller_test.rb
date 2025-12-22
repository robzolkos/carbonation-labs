require "test_helper"

class MovieRecommenderControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_movie_recommender_path
    assert_response :success
    assert_select "h1", "Movie Recommender"
  end

  test "should render form" do
    get new_movie_recommender_path
    assert_response :success
    assert_select "form[action=?]", movie_recommender_path
    assert_select "textarea[name=?]", "movie_recommender[favorite_movies]"
  end

  test "should reject empty favorite_movies" do
    post movie_recommender_path, params: { movie_recommender: { favorite_movies: "" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "should reject short favorite_movies" do
    post movie_recommender_path, params: { movie_recommender: { favorite_movies: "ab" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "show redirects without session data" do
    get movie_recommender_path
    assert_redirected_to new_movie_recommender_path
  end
end
