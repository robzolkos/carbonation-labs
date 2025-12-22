require "test_helper"

class BookClubGeneratorControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_book_club_generator_path
    assert_response :success
    assert_select "h1", "Book Club Generator"
  end

  test "should render form" do
    get new_book_club_generator_path
    assert_response :success
    assert_select "form[action=?]", book_club_generator_path
    assert_select "textarea[name=?]", "book_club_generator[favorite_books]"
  end

  test "should reject empty favorite_books" do
    post book_club_generator_path, params: { book_club_generator: { favorite_books: "" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "should reject short favorite_books" do
    post book_club_generator_path, params: { book_club_generator: { favorite_books: "ab" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "show redirects without session data" do
    get book_club_generator_path
    assert_redirected_to new_book_club_generator_path
  end
end
