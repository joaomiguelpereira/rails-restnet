class UserSession
  attr_writer :user_id, :name, :facebook_user 
  attr_reader :user_id, :name, :facebook_user
  
   def initialize(user, facebook_user=nil)
     @user_id = user.id
     @name = user.full_name
     @facebook_user = facebook_user
   end
  
  def profile_picture_url
    if @facebook_user
      return @facebook_user.pic_small 
    end
  end
end