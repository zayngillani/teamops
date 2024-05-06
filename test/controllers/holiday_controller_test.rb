require "test_helper"

class HolidayControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get holiday_create_url
    assert_response :success
  end

  test "should get new" do
    get holiday_new_url
    assert_response :success
  end
end
