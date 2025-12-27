require "test_helper"

class TripPlannerControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_trip_planner_path
    assert_response :success
    assert_select "h1", "Trip Planner"
  end

  test "should render form" do
    get new_trip_planner_path
    assert_response :success
    assert_select "form[action=?]", trip_planner_path
    assert_select "input[name=?]", "trip_planner[destination]"
    assert_select "select[name=?]", "trip_planner[trip_length]"
    assert_select "textarea[name=?]", "trip_planner[interests]"
  end

  test "should reject empty destination" do
    post trip_planner_path, params: { trip_planner: { destination: "", trip_length: "week" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "should reject missing trip_length" do
    post trip_planner_path, params: { trip_planner: { destination: "Tokyo", trip_length: "" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "show redirects without session data" do
    get trip_planner_path
    assert_redirected_to new_trip_planner_path
  end
end
