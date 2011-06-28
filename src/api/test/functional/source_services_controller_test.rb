require File.dirname(__FILE__) + '/../test_helper'

class SourceServicesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:source_services)
  end

  test "should show source_service" do
    if SourceService.first
      get :show, :id => SourceService.first.name
      assert_response :success
    end
  end
end
