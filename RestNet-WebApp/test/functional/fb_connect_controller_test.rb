require 'test_helper'

class FbConnectControllerTest < WebappFunctionalTestCase
  
  
  def setup
    @facebook_session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])   
  end
  
  def test_authenticate
    post :authenticate
    assert_not_nil @facebook_session
    assert_redirected_to @facebook_session.login_url
  end
  
  test "connect and redirect to register url" do
    @controller = FbConnectController.new
    assert_not_nil @facebook_session
    some_fb_uid = 1626128749
    @facebook_session.secure_with!("a session key", some_fb_uid, Time.now.to_i + 60)
    @request = ActionController::TestRequest.new    
   #test_name = @facebook_session.user.first_name
    assert_not_nil @request
    
    @request.session[:facebook_session] = @facebook_session
    assert_not_nil @request.session[:facebook_session]
    assert_equal some_fb_uid, @request.session[:facebook_session].user.uid
    @controller.send(:instance_variable_set, '@facebook_session', @facebook_session)
    post :connect
    assert_redirected_to new_user_url
  end
  
  test "connect and redirect to root url" do
    @controller = FbConnectController.new
    assert_not_nil @facebook_session
    user = users(:aoonis_fb)
    @facebook_session.secure_with!("a session key, other key", user.fb_uid, Time.now.to_i + 60)
    @request = ActionController::TestRequest.new    
    
    assert_not_nil @request
    
    #   @request.session[:user_id] = user.id
    @request.session[:facebook_session] = @facebook_session
    #    
    assert_not_nil @request.session[:facebook_session]
    assert_equal user.fb_uid, @request.session[:facebook_session].user.uid
    #    
    #    setup_controller_request_and_response
    @controller.send(:instance_variable_set, '@facebook_session', @facebook_session)
    post :connect
    #has to be authenticated now
    
    assert_redirected_to root_url
    assert_not_nil session[:user_session]
    assert_equal users(:aoonis_fb).id, session[:user_session].user_id
    assert_equal users(:aoonis_fb).full_name, session[:user_session].name
    
    #    
    #    assert_response :redirect
    #    assert_redirected_to '/'
  end
  
  #test "should authenticate then ask user to register" do
  #  @controller.facebook_session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
  #  get :connect, {}, {}
  #  assert_not_nil session[:facebook_session]
  #  assert_redirected_to new_user_url  
  # end
  
  # Replace this with your real tests.
  test "should not connect and redirect to home when user is not connected with fb" do
    get :connect
    assert_error_flashed(:could_not_connect_to_fb)
    assert_redirected_to root_url
  end
  # Replace this with your real tests.
  test "should not connect and redirect to where user was when is not connected with fb" do
    get :connect, {},{:return_to=>new_session_url}
    assert_error_flashed(:could_not_connect_to_fb)
    assert_redirected_to new_session_url
  end
end
