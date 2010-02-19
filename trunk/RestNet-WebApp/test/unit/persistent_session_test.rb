require 'test_helper'

class PersistentSessionTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "should delete entry by user id" do
    assert_not_nil PersistentSession.find_by_user_id(persistent_sessions(:david).user_id)
    PersistentSession.clear_session(persistent_sessions(:david).user_id)
    assert_nil PersistentSession.find_by_user_id(persistent_sessions(:david).user_id)
  end
  test "should do nothing if no session is found for the user id" do
    assert_nil PersistentSession.find_by_user_id(11212)
    PersistentSession.clear_session(11212)
    assert_nil PersistentSession.find_by_user_id(11212)
  end
  
  test "should create new entry if no session exists for user id" do
    test_id = 9999
    assert_nil PersistentSession.find_by_user_id(test_id)
    PersistentSession.create_session(test_id)
    assert_not_nil PersistentSession.find_by_user_id(test_id)
  end
  
  test "should update entry if a session exists for user id" do
    old_value = persistent_sessions(:david).key
    assert_not_nil PersistentSession.find_by_user_id(persistent_sessions(:david).user_id)
    PersistentSession.create_session(persistent_sessions(:david).user_id)
    assert_not_nil PersistentSession.find_by_user_id(persistent_sessions(:david).user_id)
    assert_not_equal old_value, PersistentSession.find_by_user_id(persistent_sessions(:david).user_id).key
  end
  

end
