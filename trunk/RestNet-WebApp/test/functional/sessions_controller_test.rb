require 'test_helper'


#require 'test_helper'
#require 'webapp_exceptions'

class SessionsControllerTest < WebappFunctionalTestCase
  # Replace this with your real tests.
  fixtures :users, :persistent_sessions
  
  test "should show login form" do
    get :new
    #Assert the instance variables
    assert_not_nil assigns["handle_or_email"]
    assert_not_nil assigns["password"]
    assert_not_nil assigns["keep_me_logged"]
    assert_response :success
  end
  
  
  ##Login negative tests
  test "should not login with inexisting handle or email" do
    #aoonis = users(:aoonis)
    post :create, :handle_or_email=>"unexistent", :password=>"somepassword", :keep_me_logged=>nil
    #Should render the login form again and with the with flash[:error]="Invalid username/login"
    #assert the the rendered action is "new"
    assert_redirected_to new_session_url
    
    #assert that an error occured and it's in the flas
    assert_error_flashed(:invalid_login_name_or_email)
  end
  
  test "should not login with empty handle or email" do
    #aoonis = users(:aoonis)
    post :create, :handle_or_email=>"", :password=>"somepassword", :keep_me_logged=>nil
    #Should render the login form again and with the with flash[:error]="Invalid username/login"
    #assert the the rendered action is "new"
    assert_redirected_to new_session_url
    #assert that an error occured and it's in the flas
    assert_error_flashed(:invalid_login_name_or_email)
  end
  
  test "should not login with empty password" do
    aoonis = users(:aoonis)
    post :create, :handle_or_email=>users(:aoonis).handle, :password=>"", :keep_me_logged=>nil
    #Should render the login form again and with the with flash[:error]="Invalid username/login"
    #assert the the rendered action is "new"
    #assert_redirected_to new_session_url
    assert_response :unauthorized
    #assert that an error occured and it's in the flas
    assert_error_flashed(:wrong_password)
  end
  
  test "should not login with wrong password" do
    #aoonis = users(:aoonis)
    post :create, :handle_or_email=>users(:aoonis).email, :password=>"some password", :keep_me_logged=>nil
    #Should render the login form again and with the with flash[:error]="Invalid username/login"
    #assert the the rendered action is "new"
    assert_response :unauthorized
    #assert_redirected_to new_session_url
    #assert that an error occured and it's in the flas
    assert_error_flashed(:wrong_password)
  end
  
  test "should not login inactive users" do
    #inactiveUser = users(:aoonis_inactive)
    post :create, :handle_or_email=>users(:aoonis_inactive).handle, :password=>"132435", :keep_me_logged=>"1"
    assert_nil session[:logged_user_id]
    assert_redirected_to root_url
    assert_error_flashed(:user_not_activated_yet)
    assert_nil PersistentSession.find_by_user_id(users(:aoonis_inactive).id)    
  end
  test "should not authenticate facebook users" do
    
    post :create, :handle_or_email=>users(:aoonis_fb).handle, :password=>"132435", :keep_me_logged=>"0"
    assert_redirected_to new_session_url
    assert_error_flashed(:fb_user_not_authenticable_message,users(:aoonis_fb).handle)
  end
  
  #positive tests
  #Test for a valid email/password
  test "should login with valid email and password" do
    #aoonis = users(:aoonis)
    post :create, :handle_or_email=>users(:aoonis).email.upcase, :password=>"132435", :keep_me_logged=>"0"
    assert_redirected_to root_url
    assert_notice_flashed(:login_successfull)
    #check if the session has :user_id = users(:aoonis).id
    assert_not_nil session[:user_session]
    #assert_equal users(:aoonis).id, session[:logged_user_id]
    assert_equal users(:aoonis).id, session[:user_session].user_id
    assert_equal users(:aoonis).full_name, session[:user_session].name
    assert_nil PersistentSession.find_by_user_id(users(:aoonis).id)
    assert_nil cookies[WebappConstants::AUTO_LOGIN_COOKIE_NAME]
    
  end
  
  test "should create an auto-login cookie in the client when keep me logged is selected" do
    post :create, :handle_or_email=>users(:aoonis).email, :password=>"132435", :keep_me_logged=>"1"
    assert_redirected_to root_url
    assert_notice_flashed(:login_successfull)
    assert_not_nil session[:user_session]
    #assert_equal users(:aoonis).id, session[:logged_user_id]
    assert_equal users(:aoonis).id, session[:user_session].user_id
    assert_equal users(:aoonis).full_name, session[:user_session].name
    #Should be created a persistent session
    assert_not_nil PersistentSession.find_by_user_id(users(:aoonis).id)  
    #Get the key
    key = PersistentSession.find_by_user_id(users(:aoonis).id).key
    assert_equal "#{users(:aoonis).id}:#{key}", cookies[WebappConstants::AUTO_LOGIN_COOKIE_NAME]
  end
  
  test "should send user to home page and show an error when trying to destroy inexistent session" do 
    get :destroy
    #assert_nil session[:logged_user_id]
    assert_nil session[:user_session]
    assert_nil session[:facebook_session]
    assert_redirected_to root_url
    
  end
  
  test "should destroy session and return to home page with a success message" do
    get :destroy , {}, {:user_session=>UserSession.new(users(:aoonis)) }
    assert_notice_flashed(:session_destroyed)
    assert_nil session[:user_session]
    assert_redirected_to root_url
  end
  
  test "should destroy session, remove persistent session and remove cookie" do
    #Scenario: User have previouly create a persistent session. 
    #Setup scenario
    persistent_session = PersistentSession.create_session(users(:aoonis).id)
    @request.cookies[WebappConstants::AUTO_LOGIN_COOKIE_NAME] = "#{users(:aoonis).id}:#{persistent_session.key}"
    assert_not_nil PersistentSession.find_by_user_id(users(:aoonis).id)
    assert_not_nil @request.cookies[WebappConstants::AUTO_LOGIN_COOKIE_NAME]
    #test
    get :destroy , {}, {:user_session=>UserSession.new(users(:aoonis)) }
    assert_notice_flashed(:session_destroyed)
    assert_nil session[:user_session]    
    assert_redirected_to root_url
    assert_nil PersistentSession.find_by_user_id(users(:aoonis).id)
    
  end
  
  
  test "should do auto login with correct data" do
    #When a persistent session exists, with the correct cookie, it should be auto logged inf  
    #Create a cookie
    
    persistent_session = PersistentSession.create_session(users(:aoonis).id)
   
    @request.cookies[WebappConstants::AUTO_LOGIN_COOKIE_NAME] = "#{users(:aoonis).id}:#{persistent_session.key}"
    
    get :new, {}, {}
    
    assert_not_nil session[:user_session]
    #assert_equal users(:aoonis).id, session[:logged_user_id]
    assert_equal users(:aoonis).id, session[:user_session].user_id
    assert_equal users(:aoonis).full_name, session[:user_session].name
    #Should be created a persistent session
    assert_not_nil PersistentSession.find_by_user_id(users(:aoonis).id)  
    assert_not_equal PersistentSession.find_by_user_id(users(:aoonis).id).key, persistent_session.key   
    assert_not_nil @request.cookies[WebappConstants::AUTO_LOGIN_COOKIE_NAME]
    assert_redirected_to new_session_url
  end
  
  test "should not do auto login with wrong data" do
    persistent_session = PersistentSession.create_session(users(:aoonis).id)
    @request.cookies[WebappConstants::AUTO_LOGIN_COOKIE_NAME] = "#{users(:aoonis).id}:#{persistent_session.key}10"
    get :new, {}, {}
    
    assert_nil session[:user_session]
    #assert_equal users(:aoonis).id, session[:logged_user_id]
    #Should be created a persistent session
    assert_nil PersistentSession.find_by_user_id(users(:aoonis).id)  
    assert_nil cookies[WebappConstants::AUTO_LOGIN_COOKIE_NAME]
    assert_redirected_to root_url
  end
  
  test "should not do auto login with missing data" do
    #persistent_session = PersistentSession.create_session(users(:aoonis).id)
    @request.cookies[WebappConstants::AUTO_LOGIN_COOKIE_NAME] = "#{users(:aoonis).id}:121212121210"
    get :new, {}, {}  
    assert_nil session[:user_session]
    #assert_equal users(:aoonis).id, session[:logged_user_id]
    #Should be created a persistent session
    assert_nil PersistentSession.find_by_user_id(users(:aoonis).id)  
    assert_nil cookies[WebappConstants::AUTO_LOGIN_COOKIE_NAME]
    assert_redirected_to root_url
  end
  
  
  
  
end
