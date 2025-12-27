require "test_helper"

class EmailToTasksControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_email_to_tasks_path
    assert_response :success
    assert_select "h1", "Email to Tasks"
  end

  test "should render form" do
    get new_email_to_tasks_path
    assert_response :success
    assert_select "form[action=?]", email_to_tasks_path
    assert_select "textarea[name=?]", "email_to_tasks[email_content]"
    assert_select "input[name=?]", "email_to_tasks[board_name]"
  end

  test "should reject empty email_content" do
    post email_to_tasks_path, params: { email_to_tasks: { email_content: "" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "should reject short email_content" do
    post email_to_tasks_path, params: { email_to_tasks: { email_content: "Too short" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "show redirects without session data" do
    get email_to_tasks_path
    assert_redirected_to new_email_to_tasks_path
  end
end
