class PasswordRecovery < ActiveRecord::Base
  
  def self.clear_password_recover(user_id)
    PasswordRecovery.delete(self.find_by_user_id(user_id).id) if self.find_by_user_id(user_id)
  end
  
  def self.create_password_recovery(user_id)
    #Check if exists any password recovery for the user
    password_recovery = self.find_by_user_id(user_id) || PasswordRecovery.new
    password_recovery.user_id = user_id
    password_recovery.key = ActiveSupport::SecureRandom.hex(32)
    password_recovery.save
    password_recovery
  end
end
