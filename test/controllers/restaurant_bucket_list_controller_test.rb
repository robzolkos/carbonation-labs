require "test_helper"

class RestaurantBucketListControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_restaurant_bucket_list_path
    assert_response :success
    assert_select "h1", "Restaurant Bucket List"
  end

  test "should render form" do
    get new_restaurant_bucket_list_path
    assert_response :success
    assert_select "form[action=?]", restaurant_bucket_list_path
    assert_select "textarea[name=?]", "restaurant_bucket_list[location_preferences]"
  end

  test "should reject empty location_preferences" do
    post restaurant_bucket_list_path, params: { restaurant_bucket_list: { location_preferences: "" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "should reject short location_preferences" do
    post restaurant_bucket_list_path, params: { restaurant_bucket_list: { location_preferences: "ab" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "show redirects without session data" do
    get restaurant_bucket_list_path
    assert_redirected_to new_restaurant_bucket_list_path
  end
end
