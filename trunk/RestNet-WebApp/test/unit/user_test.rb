require 'test_helper'

class UserTest < WebappUnitTestCase
  
  ########################
  #Accept terms validators
  ########################

  #Test no terms acceptance
  test "must accept terms and conditions" do
    
    user = build_user("golias","o grande", "11111111", "11111111","david@domain.com","0")
    assert !user.save, "Saved user without accept the terms"
    assert user.errors.invalid?(:terms)
  end


  
  ########################
  #Email Validations
  ########################
  
  #Test invalid email
  def test_should_not_create_with_invalid_email
    user = build_user("golias","o grande", "11111111", "11111111","daviddomain.com","1")
    assert !user.save, "Saved user with invalid email"
    assert user.errors.invalid?(:email)
  end
  
  
  #Test existing emails
  def test_should_not_create_used_email
    user = build_user("golias","o grande", "11111111", "11111111",users(:david).email,"1")
    assert !user.save, "Saved user with duplicated email"    
    assert user.errors.invalid?(:email)
  
end

  #Test no email
  def test_should_not_create_with_no_email
    user = build_user("golias","o garnde", "11111111", "11111111","",1)
    assert !user.save, "Saved user with no email"    
    assert user.errors.invalid?(:email)
  end
  
  
  
  ########################
  #handle Validations
  ########################
  test "should not change handle name for some invalid format" do
    user = users(:aoonis)
    user.handle="askdlaka,ds.a"
    assert !user.valid?
  end
  test "should not change handle name for some existing handle" do
    user = users(:aoonis)
    user.handle=users(:david).handle
    assert !user.valid?
  end
  

  ########################
  # Password Validators
  ########################
  #Test different passwords
  def test_should_not_create_user_with_different_passwords
    user = build_user("golias","o grande","11111111", "11111112","validemail@domain.com",1)
    assert !user.save, "Saved user with different passwords"
  end
  
  #Test empty passwords
  def test_should_not_create_user_with_empty_passwords
    user = build_user("golias", "o grande", "", "","validemail@domain.com",1)
    assert !user.save, "Saved user with different passwords"
  end 
  
  
  #Test password too short (min=5)
  def test_should_not_create_user_with_short_password
    user = build_user("golias", "o grande", "1111", "1111","validemail@domain.com",1)
    assert !user.save, "Saved user with password too short"
  end 
  
  
  #Test password too long (min=150)
  def test_should_not_create_user_with_long_passwords
    user = build_user("golias", "o maluco", "1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111", "1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111","validemail@domain.com",1)
    assert !user.save, "Saved user with password too long"
  end 
  
  ##Test Create ok
  def test_should_create_user
    user = build_user("golias","o grande", "mypassword","mypassword","validmail@adomain.com","1")
    assert user.save, "The user should have been saved"
  end
  
  #Test Activation key
  def test_should_create_activation_key
    user = build_user("first name", "last name", "password", "password", "validmail@adomain.com","1")
    
    #user.save
    assert user.save ,"The user should have been saved"
    
    #user.errors.each{|attr,msg| puts "#{attr} - #{msg}" }
    
    activation_key = user.salt+user.email+user.hashed_password
    expected_activation_key = Digest::SHA1.hexdigest(activation_key )
    assert_equal(expected_activation_key, user.activation_key,"Activation key is wrong")
  end
  #Test inactive status
  def test_should_create_inactive_user
    user = build_user("first name", "last name", "password", "password", "validmail@adomain.com","1")  
    assert user.save ,"The user should have been saved"
    assert_equal(false, user.active,"User should be inactive")
  end
  
  ########################
  # Test Authentication  #
  ########################
  
  #Positive tests
  test "should authenticate user with handle and correct password" do
    user = nil
    assert_nothing_raised(ActiveRecord::RecordNotFound, Webapp::WrongPasswordError) {
      user = User.authenticate_with_handle_or_email(users(:aoonis).handle, "132435")
    }
    assert_not_nil user, "the user should be authenticated"
  end
  
  test "should authenticate user with valid email and correct password" do
    user = nil
    assert_nothing_raised(ActiveRecord::RecordNotFound, Webapp::WrongPasswordError) {
      user = User.authenticate_with_handle_or_email(users(:aoonis).email, "132435")
    }
    assert_not_nil user, "the user should be authenticated"
  end
  
  
  
  #negative tests
  
  
  test "should not authenticate with correct handle but with wrong password" do
    user = nil
    assert_raise(Webapp::WrongPasswordError) {
      user = User.authenticate_with_handle_or_email(users(:aoonis).handle, "thepassword1")
    }
    assert_nil user, "the user should be nil"
  end
  
  test "should not authenticate with correct email but with wrong password" do
    user = nil
    assert_raise(Webapp::WrongPasswordError) {
      user = User.authenticate_with_handle_or_email(users(:aoonis).email, "thepassword1")
    }
    assert_nil user, "the user should be nil"
  end
  
  test "should not authenticate with wrong name and wrong password" do
    
    assert_raise(ActiveRecord::RecordNotFound) {
      user = User.authenticate_with_handle_or_email("david1", "thepassword")
    }
  end
  
  
  
  
  
  test "should find a user by handle" do  
    user = nil
    assert_nothing_raised(ActiveRecord::RecordNotFound, "The user should have been found") {
      user = User.find_by_handle_or_email(users(:david).handle)
    }
    assert_not_nil(user)
  end
  
  test "should find a user by email" do  
    user = nil
    assert_nothing_raised(ActiveRecord::RecordNotFound, "The user should have been found") {
      user = User.find_by_handle_or_email(users(:david).email)
    }
    assert_not_nil(user)
  end
  
  test "should not find a user by inexistent email or name" do  
    user = nil
    assert_raise(ActiveRecord::RecordNotFound, "The user should have been found") {
      user = User.find_by_handle_or_email("users___inexiten___email")
    }
    assert_nil(user)
  end
  
  
  
  
  #Private mwthods
  private
  def build_user(first_name, last_name, password, password_confirmation,email,terms)
    user = User.new
    user.first_name=first_name
    user.last_name=last_name
    user.password=password
    user.password_confirmation = password_confirmation
    user.email = email
    user.terms = terms
    user
  end
end
