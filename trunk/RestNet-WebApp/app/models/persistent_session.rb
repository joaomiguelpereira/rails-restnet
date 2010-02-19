class PersistentSession < ActiveRecord::Base
  
  def self.clear_session(user_id)
    PersistentSession.delete(PersistentSession.find_by_user_id(user_id).id) if !PersistentSession.find_by_user_id(user_id).nil?
  end
  
  def self.create_session(user_id)
    #check if exists
    persistent_session = PersistentSession.find_by_user_id(user_id) || PersistentSession.new
    rand_key = ActiveSupport::SecureRandom.hex(32)
    persistent_session.user_id = user_id
    persistent_session.key = rand_key
    persistent_session.save
    persistent_session
  end
end
