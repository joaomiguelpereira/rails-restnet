class UserSession
  attr_writer :user_id, :name, :facebook_user, :email
  attr_reader :user_id, :name, :facebook_user, :email
  
  def initialize(user, facebook_user=nil)
    @user_id = user.id
    @name = user.full_name
    @facebook_user = facebook_user
    @email = user.email
  end
  
end