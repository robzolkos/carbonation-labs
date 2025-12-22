require "test_helper"

class ProcessExtractorControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_process_extractor_path
    assert_response :success
    assert_select "h1", "Process Extractor"
  end

  test "should render form" do
    get new_process_extractor_path
    assert_response :success
    assert_select "form[action=?]", process_extractor_path
    assert_select "textarea[name=?]", "process_extractor[process_description]"
  end

  test "should reject empty process_description" do
    post process_extractor_path, params: { process_extractor: { process_description: "" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "should reject short process_description" do
    post process_extractor_path, params: { process_extractor: { process_description: "short" } }
    assert_response :unprocessable_entity
    assert_select ".errors"
  end

  test "show redirects without session data" do
    get process_extractor_path
    assert_redirected_to new_process_extractor_path
  end
end
