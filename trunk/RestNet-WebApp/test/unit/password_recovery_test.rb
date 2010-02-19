require 'test_helper'

class PasswordRecoveryTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  fixtures :users
  
  
  test "should raise exception when recovery is not found" do
    assert_nothing_raised(ActiveRecord::RecordNotFound) {
      PasswordRecovery.clear_password_recover(4400)
    }  
  end
  
  test "should clear password recovery" do
    assert_not_nil PasswordRecovery.find_by_user_id(100)
    PasswordRecovery.clear_password_recover(100)
    assert_nil PasswordRecovery.find_by_user_id(100)
  end
  
  test "should update a recovery password" do
    assert_not_nil PasswordRecovery.find_by_user_id(100)
    key = PasswordRecovery.find_by_user_id(100).key
    
    password_recovery = PasswordRecovery.create_password_recovery(100)
    assert_not_nil PasswordRecovery.find_by_user_id(100)
    assert_not_equal key, PasswordRecovery.find_by_user_id(100).key
  end
  
  test "should create a new recovery" do
    password_recovery = PasswordRecovery.create_password_recovery( users(:david).id )
    assert_not_nil password_recovery  
  end
end
