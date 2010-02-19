require 'test_helper'

class UsersControllerTest < WebappFunctionalTestCase
  fixtures :users
  
  test "should not destroy user when no session is present" do
    delete :destroy, {:id=>users(:aoonis).id}
    assert_not_nil User.find_by_handle("AoonIS")
    assert_redirected_to root_url
    assert_error_flashed(:not_allowed)
  end
  
  test "should not destroy user when logged user is not admin or not same user" do
    some_user = users(:aoonis)
    user_session = UserSession.new(some_user)
    delete :destroy, {:id=>users(:david).id, }, {:user_session=>user_session}
    assert_not_nil User.find_by_handle("david")
    assert_redirected_to root_url
    assert_error_flashed(:not_allowed)
  end
  
  test "should destroy user when logged user is admin but not same user" do
    some_user = users(:admin)
    
    user_session = UserSession.new(some_user)
    delete :destroy, {:id=>users(:david).id, }, {:user_session=>user_session}
    assert_nil User.find_by_handle("david")
    assert_redirected_to users_url
    assert_notice_flashed(:user_removed)
  end
  
  def test_destroy_user_if_is_self  
    some_user = users(:aoonis)
    user_session = UserSession.new(some_user)
    delete :destroy, {:id=>users(:aoonis).id, }, {:user_session=>user_session}
    assert_nil User.find_by_handle("AoonIS")
    #session should now not exists
    assert_no_user_session
    assert_redirected_to users_url
    assert_notice_flashed(:user_removed)
  end
  
  test "should not destroy user when some session exists for inexistent user" do
  some_user = users(:aoonis)
  some_user.id = 129182989
  user_session = UserSession.new(some_user)
  delete :destroy, {:id=>users(:aoonis).id, }, {:user_session=>user_session}
  assert_not_nil User.find_by_handle("AoonIS")
  assert_redirected_to root_url
  assert_user_session
  assert_error_flashed(:not_allowed)
end

test "should create user" do
  post :create, {:user=>{
    :first_name=>"first name",:last_name=>"last name", :password=>"12345", :password_confirmation=>"12345", 
    :email=>"gdesquina@gmail.com"}}
  user = User.find_by_email("gdesquina@gmail.com")
  
  
  assert_nil session[:user_session]
  assert_redirected_to root_url
  assert_not_nil user
  assert_not_nil user.handle
  assert_equal(user.active, false)
  assert_notice_flashed(:user_created_confirmation_sent, user.full_name,user.email)
end

test "should create fb user" do
  
  @facebook_session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])   
  some_fb_uid = 1626128749
  @facebook_session.secure_with!("other session key", some_fb_uid, Time.now.to_i + 60)
  @request.session[:facebook_session] = @facebook_session
  
  post :create, {:user=>{
    :first_name=>"first name", :last_name=>"last_name", :email=>"gdesquina@gmail.com"}}
  user = User.find_by_email("gdesquina@gmail.com")
  
  assert_not_nil user
  assert_equal(user.active, true)
  assert_equal(user.fb_uid,some_fb_uid)
  assert_user_session
  
  #assert_not_nil session[:user_session]
  assert_redirected_to root_url
end

test "should not show new user form if user has a session" do
  get :new, {}, {:user_session=>UserSession.new(users(:aoonis))}
  assert_error_flashed(:user_session_exists)
  assert_redirected_to root_url
end

test "should log error and send to root url if activating an inexistent user" do
  get :activate, {:activation_key=>users(:aoonis).activation_key, :id=>9999}, {}
  assert_error_flashed(:user_not_found)
  assert_redirected_to root_url    
end

test "should send user to login url if activating an active users" do
  get :activate, {:activation_key=>users(:aoonis).activation_key, :id=>users(:aoonis).id}, {}
  assert_error_flashed(:user_already_active_error)
  assert_redirected_to new_session_url
  user = User.find(users(:aoonis).id)
  assert_equal(user.active, true)     
  
end
test "should send user to root url if activating with activation key is invalid" do
  get :activate, {:activation_key=>"something else", :id=>users(:david).id}, {}
  assert_error_flashed(:invalid_activation_key_error)
  assert_redirected_to root_url
  user = User.find(users(:david).id)
  assert_equal(user.active, false)     
end

test "activate account" do
  get :activate, {:activation_key=>users(:david).activation_key, :id=>users(:david).id}, {}
  assert_notice_flashed(:user_activated_success_message)
  assert_redirected_to new_session_url
  user = User.find(users(:david).id)
  assert_equal(user.active, true) 
end

test "should not try pass recovery when user session exists" do
  get :recover_password, {}, {:user_session=>UserSession.new(users(:aoonis))}
  assert_error_flashed(:user_session_exists)
  assert_redirected_to root_url
end

test "recover pass  should render recover pass form" do
  get :recover_password
  assert_not_nil assigns["handle_or_user_name"]
  assert_response :success
end

test "recover pass should show error when no email or name is provided" do
  post :recover_password
  assert_error_flashed(:invalid_login_name_or_email)
  assert_redirected_to recover_password_url
end

test "recover pass should show error when email or name provided does not exists" do
  post :recover_password, {:name_or_email=>"something"}
  assert_error_flashed(:invalid_login_name_or_email)
  assert_redirected_to recover_password_url
end

test "recover pass  should send email with instructions and redirect to root url when valid email" do
  post :recover_password, {:handle_or_email=>users(:david).email}
  assert_not_nil PasswordRecovery.find_by_user_id(users(:david).id)
  assert_notice_flashed(:recover_password_instructions_sent,users(:david).email)
  assert_redirected_to root_url
end

test "reset password should send to root url when no user_id or key is provided" do
  get :reset_password, {}
  assert_error_flashed(:reset_password_invalid_key)
  assert_redirected_to root_url
end
test "reset password should send to root url when invalid user_id is provided" do
  get :reset_password, {:id=>919191919, :key=>"kdkdj"}
  assert_error_flashed(:user_not_found)
  assert_redirected_to root_url
end

test "reset password should send to root url user has not requested chenge to pass" do
  get :reset_password, {:id=>users(:david).id, :key=>"kdkdj"}
  assert_error_flashed(:reset_password_invalid_key)
  assert_redirected_to root_url
end

test "reset password should send to root when key is invalid" do
  password_recovery = PasswordRecovery.create_password_recovery(users(:david).id)
  get :reset_password, {:id=>users(:david).id, :key=>"kdkdj"}
  assert_error_flashed(:reset_password_invalid_key)
  assert_redirected_to root_url
end

test "reset password should show new password fields" do
  password_recovery = PasswordRecovery.create_password_recovery(users(:david).id)
  get :reset_password, {:id=>users(:david).id, :key=>password_recovery.key}
  assert_not_nil assigns["password"]
  assert_not_nil assigns["password_confirmation"]
  assert_equal assigns["user_id"].to_i, users(:david).id
  assert_equal assigns["key"],password_recovery.key
end

#now the real stuff

test "should fail when no data is provided" do
  put :reset_password, {}, {}
  assert_error_flashed(:reset_password_invalid_key)
  assert_redirected_to root_url
end

test "should fail when password dont match" do
  put :reset_password, {:password=>"aaaaa", :password_confirmation=>"baaaa", :id=>"100", :key=>"teste"}
  assert_error_flashed(:password_dont_match)
  
end

test "should fail when user is not found dont match" do
  put :reset_password, {:password=>"aaaaa", :password_confirmation=>"aaaaa", :id=>"9999999", :key=>"teste"}
  assert_error_flashed(:user_not_found)
  assert_redirected_to root_url
end

test "should fail when user has not requested password change" do
  put :reset_password, {:password=>"aaaaa", :password_confirmation=>"aaaaa", :id=>users(:david).id, :key=>"teste"}
  assert_error_flashed(:reset_password_invalid_key)
  assert_redirected_to root_url
end

test "should fail when passwords dont meet minimum requirements" do
  put :reset_password, {:password=>"aooo", :password_confirmation=>"aooo", :id=>users(:david).id, :key=>"teste"}
  assert_error_flashed(:invalid_password)    
end

test "should fail when passwords dont meet max requirements" do
  put :reset_password, {:password=>"oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo", :password_confirmation=>"oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo", :id=>users(:david).id, :key=>"teste"}
  assert_error_flashed(:invalid_password)
end

test "should change password" do
  new_pass = "12345"
  password_recovery = PasswordRecovery.create_password_recovery(users(:aoonis).id)
  put :reset_password, {:password=>new_pass, :password_confirmation=>new_pass, :id=>users(:aoonis).id, :key=>password_recovery.key}
  #ensure I can authenticate
  assert_nothing_raised(Webapp::WrongPasswordError, Webapp::UserNotActiveError) {
    User.authenticate_with_handle_or_email(users(:aoonis).email, new_pass)
  }
  assert_notice_flashed(:password_changed_successfully)
  assert_redirected_to new_session_url
  assert_nil PasswordRecovery.find_by_user_id(users(:aoonis).id)
  
end

test "should not render edit if not authenticated" do
  #no session
  get :edit, {:id=>users(:aoonis).id}
  assert_redirected_to root_url
  assert_error_flashed(:not_allowed)
end

test "should not render edit if not correctly authenticated" do
  authenticated_user = users(:david)
  user_session = UserSession.new(authenticated_user)
  get :edit, {:id=>users(:aoonis).id}, {:user_session=>user_session}
  assert_redirected_to root_url
  assert_error_flashed(:not_allowed)
end


test "should render edit if admin is authenticated" do
  test_render_edit_form(users(:admin), users(:aoonis))
end

test "should render edit if user is authenticated" do
  test_render_edit_form(users(:aoonis), users(:aoonis))
end

def test_render_edit_form(authenticated_user, user) 
  user_session = UserSession.new(authenticated_user)
  get :edit, {:id=>user.id}, {:user_session=>user_session}
  assert_not_nil assigns["user"]
  assert_equal assigns["user"].id, users(:aoonis).id
  assert_response :success
end

test "should not update if not authenticated" do
  post :update
  assert_redirected_to root_url
  assert_error_flashed(:not_allowed)
end

def test_update_email_and_names
  user_session = UserSession.new(users(:aoonis))
  post_user = {:first_name=>"new first name", :last_name=>"new last name", :email=>"jonhy@gmail.com"}
  post :update, {:id=>users(:aoonis).id, :user=>post_user},{:user_session=>user_session}
  user = User.find_by_email("jonhy@gmail.com")
  assert_not_nil user
  assert_equal(user.first_name,"new first name")
  assert_equal(user.last_name,"new last name")
  assert_equal(user.email,"jonhy@gmail.com")
  assert_equal(user_session.name,user.full_name)
  assert_redirected_to :controller=>:users, :action=>:show, :id=>user.id
  assert_notice_flashed(:user_data_updated)
end
def test_update_handle
  user_session = UserSession.new(users(:aoonis))
  post_user = {:handle=>"newhandle"}
  post :update, {:id=>users(:aoonis).id, :user=>post_user},{:user_session=>user_session}
  assert_not_nil User.find_by_handle("newhandle")
  assert_redirected_to :controller=>:users, :action=>:show, :id=>User.find_by_handle("newhandle").id
  assert_notice_flashed(:user_data_updated)
end

test "should not update handle for a duplicated handle" do
user_session = UserSession.new(users(:aoonis))
post_user = {:handle=>users(:david).handle}
post :update, {:id=>users(:aoonis).id, :user=>post_user},{:user_session=>user_session}
assert_error_flashed(:user_data_not_updated)

end




test "should not update admin" do

user_session = UserSession.new(users(:aoonis))
post_user = {:admin=>"1"}
post :update, {:id=>users(:aoonis).id, :user=>post_user},{:user_session=>user_session}
#assert not changed admin
modified_user = User.find(users(:aoonis).id)
assert_not_equal(modified_user.admin, true)

end

test "should not update active" do
user_session = UserSession.new(users(:david))
post_user = {:active=>"1"}
post :update, {:id=>users(:david).id, :user=>post_user},{:user_session=>user_session}
#assert not changed admin
modified_user = User.find(users(:david).id)
assert_not_equal(modified_user.active, true)
end


test "should not update hashed password" do
user_session = UserSession.new(users(:david))
post_user = {:hashed_password=>"123456"}
post :update, {:id=>users(:david).id, :user=>post_user},{:user_session=>user_session}
#assert not changed admin
modified_user = User.find(users(:david).id)
assert_not_equal(modified_user.hashed_password, "123456")
end

test "should not update fb_uid" do
user_session = UserSession.new(users(:david))
post_user = {:fb_uid=>"123456"}
post :update, {:id=>users(:david).id, :user=>post_user},{:user_session=>user_session}
#assert not changed admin
modified_user = User.find(users(:david).id)
assert_not_equal(modified_user.fb_uid, "123456")
end


def test_should_not_update_password
user_session = UserSession.new(users(:david))
post_user = {:passsword=>"123456", :password_confirmation=>"123456"}
post :update, {:id=>users(:david).id, :user=>post_user},{:user_session=>user_session}
#assert not changed admin
assert_raise(Webapp::WrongPasswordError) {
  user = User.authenticate_with_handle_or_email(users(:david).handle,"123456")
  
}
end




test "should not update password without a valid session" do
put :change_password, {:id=>users(:david).id}
assert_error_flashed(:not_allowed)
assert_redirected_to root_url
end


test "should not update password if user session is not itself" do
user_session = UserSession.new(users(:aoonis))
put :change_password, {:id=>users(:david).id}, {:user_session=>user_session}
assert_error_flashed(:not_allowed)
assert_redirected_to root_url
end

test "should not update password if current password is invalid" do
user_session = UserSession.new(users(:aoonis))
put :change_password, {:id=>users(:aoonis).id, :current_password=>"1232", :password=>"132435", :password_confirmation=>"132435"}, {:user_session=>user_session}
assert_error_flashed(:wrong_password)
assert_response :success
end

test "should not update password if new passwords dont match" do
user_session = UserSession.new(users(:aoonis))
put :change_password, {:id=>users(:aoonis).id, :current_password=>"132435", :password=>"novapsss", :password_confirmation=>"novapsss2"}, {:user_session=>user_session}
assert_error_flashed(:password_dont_match)
assert_response :success
end


test "should not update password if new passwords match the requirements" do
user_session = UserSession.new(users(:aoonis))
put :change_password, {:id=>users(:aoonis).id, :current_password=>"132435", :password=>"123", :password_confirmation=>"123"}, {:user_session=>user_session}
assert_error_flashed(:invalid_password)
assert_response :success
assert_raise (Webapp::WrongPasswordError) {
  User.authenticate_with_handle_or_email(users(:aoonis).handle, "123")
}
end

def test_should_not_change_password_for_facebook_user
user_session = UserSession.new(users(:aoonis_fb))
put :change_password, {:id=>users(:aoonis_fb).id, :current_password=>"", :password=>"12345", :password_confirmation=>"12345"}, {:user_session=>user_session}
assert_error_flashed(:password_not_changeable_for_facebook_user)
assert_redirected_to :controller=>:users, :action=>:show, :id=>users(:aoonis_fb).id


end


test "should update password" do
user_session = UserSession.new(users(:aoonis))
put :change_password, {:id=>users(:aoonis).id, :current_password=>"132435", :password=>"12345", :password_confirmation=>"12345"}, {:user_session=>user_session}
assert_notice_flashed(:password_changed_successfully)
assert_redirected_to :controller=>:users, :action=>:show, :id=>users(:aoonis).id

assert_nothing_raised (Webapp::WrongPasswordError) {
  User.authenticate_with_handle_or_email(users(:aoonis).handle, "12345")
}

end


test "should not update activation key" do
user_session = UserSession.new(users(:david))
post_user = {:activation_key=>"123456"}
post :update, {:id=>users(:david).id, :user=>post_user},{:user_session=>user_session}
#assert not changed admin
modified_user = User.find(users(:david).id)
assert_not_equal(modified_user.activation_key, "123456")
end


test "should not updated password" do

user_session = UserSession.new(users(:aoonis))
post_user = {:handle=>"newhandle", :hashed_password=>"newhp", :salt=>"newsalt"}
post :update ,{:user=>post_user}, {:user_session=>user_session}
modified_user = User.find_by_handle("newhandle")
assert_nil modified_user

end


end
